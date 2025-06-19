#!/bin/bash

set -e

IMAGE_NAME=live-poc
CONTAINER_NAME=live

# check to see if already existing version
if [ "$(sudo docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Removing existing container..."
    sudo docker stop $CONTAINER_NAME
    echo "Successfully stopped the container"
    # sudo docker rm $CONTAINER_NAME
fi

sudo docker build -t $IMAGE_NAME .

# start in detached mode
sudo docker run --rm -d --name $CONTAINER_NAME --network host \
    -v $(pwd)/hls:/var/www/hls \
    $IMAGE_NAME

echo "Waiting for $CONTAINER_NAME to start"
sleep 5

sudo docker logs -n 20 -t $CONTAINER_NAME

sleep 1
echo "Starting camera feed"

mkdir -p _logs

bash scripts/record_cameraA.sh > _logs/record_cameraA.log 2>&1 &
pid=$!
echo "Started live camera feed with process $pid"

# ffmpeg -re -f v4l2 -fflags +discardcorrupt \
#     -input_format mjpeg -video_size 1280x960 -framerate 5 \
#     -i /dev/video0 \
#     -vf "format=yuv420p,drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:
#        text='%{localtime}':x=10:y=10:fontsize=32:fontcolor=white:box=1:boxcolor=black@0.5" \
#     -c:v libx264 -preset ultrafast -tune zerolatency \
#     -g 1 -keyint_min 1 -sc_threshold 0 \
#     -f flv rtmp://10.49.26.98/live/stream \
#     -loglevel warning # for production so that doesn't cloud the screen

