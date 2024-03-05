# About

Compilation of overengineered scripts (due to batch limitations), to attach video previews at the start of any video, without reencoding the original video.

Useful for Google Photos, where the first frame or seconds or your video are displayed as thumbnails.

None of the script modifies original files. Some created files keep the original modified dates.

## Requisites

- [FFmpeg](https://ffmpeg.org/download.html)
- Make sure to include the extensions of your files in the `for` line of each script, if they are not already included.
- Some scripts break if filenames have special characters, adjust them.

## Scripts

### Audio to video

- Creates a black-screen-with-filename video, for every audio file in the directory.


### Audio to video mjpeg

- Creates a still image video, for every audio file in the directory.
- Requires jpg images with equal filenames in `/temp` folder.


### Auto forall intro

- For every video in the directory, creates an amount of grid previews, and attaches them to the start of the video.

If you get the error `Impossible to open '..\tempGrillf\`, update to a newer ffmpeg version, or delete `..\` in the `echo file` lines.


### Auto join intro

- For every video in the directory, creates an amount of grid previews (+print of filenames and durations), and joins all videos in a single file.
The script to create text timestamps is pending for upload (lost in my other computer).


### Forall encode 1920

- Re encodes every video in the directory, at a new resolution: 1920 pixels in size for the biggest axis, and preserving aspect ratio with the other.


### Forall crear intro

Skip to the next script, this is an old iteration.
- For every video in the directory, takes image samples in the directory, and attaches them to the start of each respective video.
- Requires to manually create `video.mp4.png`, `video.mp4_1.png` and `video.mp4_2.png`.


### Forall crear intro variable / pasosExtra

- For every video in the directory, takes image samples in the directory, and attaches them to the start of each respective video.
- To create image samples, run the extraer script first, and move them from `/tempFrames` folder to the main directory.


### Forall crear vid prev variable

- For every video in the directory, takes video previews in the `/prevs` folder, and attaches them to the start of each respective video.
- To create video previews, run the extraer script first.


### Forall extraer frames

- Extracts an amount of image samples, for every video file in the directory.


### Forall extraer vid prev / Forall extraer prev given

- Extracts an amount of video samples, for every video file in the directory.




