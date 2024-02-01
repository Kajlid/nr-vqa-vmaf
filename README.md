# nr-vqa-vmaf

ffmpeg_quality_metrics will be used to calculate vmaf.

Dependencies:
- pip3 install torch torchvision torchview
- pip3 install matplotlib
- pip3 install ffmpeg_quality_metrics
- pip install ffpyplayer

Structure:

- main.ipynb
    Main working file.

- data
    - trailers_train
        the 70 trailers that is reserved for the dataset that the neural network will be trained on. 
    
    - trailers_test
        the 17 trailers that is reserved for the dataset that the neural network will be tested on. Will be used for VMAF calculation (ground truth).


- compressed_data: NOT USED

- compressed_data2:
    70 videos from the training data that has gotten a random compression level. 

- compressed_TEST_videos:
    17 videos from the test data that has gotten a random compression level.

- images_train:
    Reference images, each 250th frame from trailers_train

- images_TEST:
    Reference images, each 250th frame from trailers_test

- images_train_compressed2:
    Distoreted images, each 250th frame from compressed_data2

- images_TEST_compressed:
    Distoreted images, each 250th frame from compressed_TEST_videos

- images_train_crop:
    Cropped "patches" of images from images_train, will contain information in the file name of which part of the image each patch belongs to, for analysis. Will be used for VMAF calculation (ground truth).

- images_train_comp_crop:
    Cropped "patches" of images from images_train_compressed2, will contain information in the file name of which part of the image each patch belongs to, for analysis. Will be used for VMAF calculation (ground truth) and for training network.


- vmaf.txt
    Stores VMAF output from command line.
