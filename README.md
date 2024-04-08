# nr-vqa-vmaf

Some of the code in this respitory may be deprecated or test cases not used for attaining the results. Write to https://github.com/Kajlid/nr-vqa-vmaf/issues for questions.

Main dependencies:
- pip3 install torch torchvision torchview
- pip3 install matplotlib
- pip3 install ffmpeg_quality_metrics
- pip install scikit-image

ffmpeg_quality_metrics was used to calculate vmaf.

Structure:

- main.ipynb      [File]
    Main working file. Here all code for the project can be found.

- data    [Folder]
    - trailers_train        [Folder]
        the 70 trailers reserved for the dataset that the neural network was trained on. 
    
    - trailers_test         [Folder]
        the 17 trailers reserved for the dataset that the neural network was tested on. 


- compressed_data: 
    NOT USED

- compressed_data2:         [Folder]
    70 videos from the training data that has gotten a random compression level. 

- compressed_TEST_videos:   [Folder]
    17 videos from the test data that has gotten a random compression level.

- images_train:             [Folder]
    Reference images (train set), each 250th frame from trailers_train.

- images_TEST:              [Folder]
    Reference images (test set), each 250th frame from trailers_test.

- images_train_compressed2: [Folder]
    Distorted images (train set), each 250th frame from compressed_data2

- images_TEST_compressed:   [Folder]
    Distorted images (test set), each 250th frame from compressed_TEST_videos

- images_train_crop_png:    [Folder]
    Cropped "patches" of images from images_train, contains information in the file name of which part of the image each patch belongs to, for analysis. Used for VMAF calculation (reference images).

- images_train_comp_crop_png: [Folder]
    Cropped "patches" of images from images_train_compressed2, contains information in the file name of which part of the image each patch belongs to, for analysis. Used for VMAF calculation (distorted images) and for creating the dataset used for training the neural network.

- images_TEST_crop_png:     [Folder]
    Cropped "patches" from images_TEST. Only used for VMAF calculation (reference) which will be used as ground truth quality labels.

- images_TEST_comp_crop_png:[Folder]
    Cropped "patches" from images_TEST_compressed. Used for VMAF calculation (distorted images) and for creating the dataset used for testing the neural network. 

- vmaf_values_train.csv     [File]
    Calculated VMAF values, train set and corresponding compressed image patches.

- vmaf_values_TEST.csv     [File]
    Calculated VMAF values, test set and corresponding compressed image patches.

- vmaf_on_full_frames_train.csv [File]
    Only used for analysis.

Other files and folders found in the repository were either created by running code or used for tests/not used at all. 
For example, inference.csv was created as a result of testing the DenseNet model and contains information on inferreing the model performance. 