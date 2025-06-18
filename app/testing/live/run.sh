#!/bin/bash

set -e

IMAGE_NAME=live-poc
CONTAINER_NAME=live

# check to see if already existing version
if [ "$(sudo docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Removing existing container..."
    sudo docker stop $CONTAINER_NAME
    echo "Successfully stopped the container"
    sudo docker rm $CONTAINER_NAME
fi

sudo docker build -t $IMAGE_NAME .

# start in detached mode
sudo docker run --rm -it --name $CONTAINER_NAME --network host \
    -v $(pwd)/hls:/var/www/hls \
    $IMAGE_NAME

echo "Waiting for $CONTAINER_NAME to start"
sleep 5

sudo docker logs -n 20 -t $CONTAINER_NAME

sleep 1
echo "Starting camera feed"

# run camera capture
# ffmpeg -re -f v4l2 -fflags +discardcorrupt \
#        -input_format mjpeg -video_size 640x480 -framerate 30 \
#        -i /dev/video0 \
#        -vf format=yuv420p \
#        -c:v libx264 -preset ultrafast -tune zerolatency \
#        -f flv rtmp://10.49.26.98/live/stream

ffmpeg -re -f v4l2 -fflags +discardcorrupt \
    -input_format mjpeg -video_size 1280x960 -framerate 5 \
    -use_wallclock_as_timestamps 1 \
    -i /dev/video0 \
    -vf format=yuv420p \
    -c:v libx264 -preset ultrafast -tune zerolatency \
    -g 1 -keyint_min 1 -sc_threshold 0 \
    -fps_mode cfr
    -f flv rtmp://10.49.26.98/live/stream \
    -loglevel warning # for production so that doesn't cloud the screen
