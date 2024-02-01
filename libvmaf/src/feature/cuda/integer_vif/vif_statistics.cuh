/**
 *
 *  Copyright 2016-2023 Netflix, Inc.
 *  Copyright 2021 NVIDIA Corporation.
 *
 *     Licensed under the BSD+Patent License (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *         https://opensource.org/licenses/BSDplusPatent
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 */

#include "cuda_helper.cuh"
#include "cuda/integer_vif_cuda.h"

#include "common.h"

__device__ __forceinline__ uint16_t get_best16_from32(uint32_t temp, int *x) {
  int k = __clz(temp);
  k = 16 - k;
  temp = temp >> k;
  *x = -k;
  return temp;
}

__device__ __forceinline__ uint16_t get_best16_from64(uint64_t temp, int *x) {
  int k = __clzll(temp);
  if (k > 48) {
    k -= 48;
    temp = temp << k;
    *x = k;
  } else if (k < 47) {
    k = 48 - k;
    temp = temp >> k;
    *x = -k;
  } else {
    *x = 0;
    if (temp >> 16) {
      temp = temp >> 1;
      *x = -1;
    }
  }
  return (uint16_t)temp;
}

__device__ __forceinline__ uint16_t log_generate(int i) {
  // if (i < 32767 || i >= 65536)
  //     return 0;
  return (uint16_t)roundf(log2f(float(i)) * 2048.f);
}

template <typename aligned_dtype = uint4>
__device__ __forceinline__ void vif_statistic_calculation(
    const aligned_dtype &mu1, const aligned_dtype &mu2,
    const aligned_dtype &xx_filt, const aligned_dtype &yy_filt,
    const aligned_dtype &xy_filt, int cur_col, int w, int h,
    double vif_enhn_gain_limit, vif_accums &thread_accum) {
  // float equivalent of 2. (2 * 65536)
  constexpr int32_t sigma_nsq = 65536 << 1;

  const uint32_t *mu1_val = reinterpret_cast<const uint32_t *>(&mu1);
  const uint32_t *mu2_val = reinterpret_cast<const uint32_t *>(&mu2);
  const uint32_t *xx_filt_val = reinterpret_cast<const uint32_t *>(&xx_filt);
  const uint32_t *yy_filt_val = reinterpret_cast<const uint32_t *>(&yy_filt);
  const uint32_t *xy_filt_val = reinterpret_cast<const uint32_t *>(&xy_filt);

  constexpr int aligned_dtype_values = sizeof(aligned_dtype) / sizeof(int32_t);
  // calculate thread relative sums for all preloaded values
  for (int v = 0; v < aligned_dtype_values; ++v) {
    if (cur_col + v < w) {

      int64_t num_val, den_val;

      uint32_t mu1_sq_val =
          (uint32_t)((((uint64_t)mu1_val[v] * mu1_val[v]) + 2147483648) >> 32);
      uint32_t mu2_sq_val =
          (uint32_t)((((uint64_t)mu2_val[v] * mu2_val[v]) + 2147483648) >> 32);
      uint32_t mu1_mu2_val =
          (uint32_t)((((uint64_t)mu1_val[v] * mu2_val[v]) + 2147483648) >> 32);

      int32_t sigma1_sq = (int32_t)(xx_filt_val[v] - mu1_sq_val);
      int32_t sigma2_sq = (int32_t)(yy_filt_val[v] - mu2_sq_val);
      int32_t sigma12 = (int32_t)(xy_filt_val[v] - mu1_mu2_val);

      sigma1_sq = max(sigma1_sq, 0);
      sigma2_sq = max(sigma2_sq, 0);

      // eps is zero, an int will not be less then 1.0e-10, it can be
      // changed to one
      const double eps = 65536 * 1.0e-10;
      double g = 0.0;
      int32_t sv_sq = sigma2_sq;

      // if sigma1_sq > 0 then sigma1_sq >= 1 and thus greater eps => only
      // the case sigma1_sq == 0 matters

      // as g can only be < 0 if sigma12 is < 0 we can also check for that
      double tmp = sigma12 / (sigma1_sq + eps);
      if (sigma12 > 0 && sigma1_sq != 0 && sigma2_sq != 0) {
        g = tmp;
      }
      sv_sq = sigma2_sq - g * sigma12;
      sv_sq = (uint32_t)(max(sv_sq, (int32_t)eps));

      g = min(g, vif_enhn_gain_limit);

      if (sigma1_sq >= sigma_nsq) {
        uint32_t log_den_stage1 = (uint32_t)(sigma_nsq + sigma1_sq);
        int x;
        uint16_t log_den1 = get_best16_from32(log_den_stage1, &x);

        /**
         * log values are taken from the look-up table generated by
         * log_generate() function which is called in
         * integer_combo_threadfunc den_val in float is log2(1 +
         * sigma1_sq/2) here it is converted to equivalent of
         * log2(2+sigma1_sq) - log2(2) i.e log2(2*65536+sigma1_sq) - 17
         * multiplied by 2048 as log_value = log2(i)*2048 i=16384 to 65535
         * generated using log_value x because best 16 bits are taken
         */
        thread_accum.num_x++;
        thread_accum.x += x;
        den_val = log_generate(log_den1);

        if (sigma12 >= 0) {
          // num_val = log2f(1.0f + (g * g * sigma1_sq) / (sv_sq +
          // sigma_nsq));
          /**
           * In floating-point numerator = log2((1.0f + (g * g *
           * sigma1_sq)/(sv_sq + sigma_nsq))
           *
           * In Fixed-point the above is converted to
           * numerator = log2((sv_sq + sigma_nsq)+(g * g * sigma1_sq))-
           * log2(sv_sq + sigma_nsq)
           */
          int x1, x2;
          uint32_t numer1 = (sv_sq + sigma_nsq);
          int64_t numer1_tmp =
              (int64_t)((g * g * sigma1_sq)) + numer1; // numerator
          uint16_t numlog = get_best16_from64((uint64_t)numer1_tmp, &x1);

          // we do not check against numer1 > 0 as sv_sq >= and sigma_nsq >
          // 0 and therefore the sum is > 0
          uint16_t denlog = get_best16_from64((uint64_t)numer1, &x2);
          thread_accum.x2 += (x2 - x1);
          num_val = log_generate(numlog) - log_generate(denlog);
          thread_accum.num_log += num_val;
          thread_accum.den_log += den_val;
        } else {
          num_val = 0;
          thread_accum.num_log += num_val;
          thread_accum.den_log += den_val;
        }
      } else {
        den_val = 1;
        thread_accum.num_non_log += sigma2_sq;
        thread_accum.den_non_log += den_val;
      }
    }
  }
}
