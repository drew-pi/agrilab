#!/bin/bash

set -e

CONTAINER_NAME=live-poc

sudo docker build -t $CONTAINER_NAME .

# start in detached mode
sudo docker run --rm -d --name live --network host \
    -v $(pwd)/hls:/var/www/hls \
    $CONTAINER_NAME

# run camera capture
ffmpeg -re -f v4l2 -fflags +discardcorrupt \
       -input_format mjpeg -video_size 640x480 -framerate 30 \
       -i /dev/video0 \
       -vf format=yuv420p \
       -c:v libx264 -preset ultrafast -tune zerolatency \
       -f flv rtmp://10.49.26.98/live/stream

ffmpeg -re -f v4l2 -fflags +discardcorrupt \
    -input_format mjpeg -video_size 1280x960 -framerate 5 \
    -i /dev/video0 \
    -vf format=yuv420p \
    -c:v libx264 -preset ultrafast -tune zerolatency \
    -g 1 -keyint_min 1 -sc_threshold 0 \
    -f flv rtmp://10.49.26.98/live/stream \
    -loglevel warning # for production so that doesn't cloud the screen
