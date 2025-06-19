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

echo "Removing all recording and live feed background processes"
# ps aux | grep [f]fmpeg
pkill -x ffmpeg || true

echo "Rebuilding $IMAGE_NAME"
sudo docker build -t $IMAGE_NAME .

# start in detached mode
sudo docker run --rm -d --name $CONTAINER_NAME --network host \
    -v $(pwd)/hls:/var/www/hls \
    $IMAGE_NAME

echo "Waiting for $CONTAINER_NAME to start"
sleep 5

sudo docker logs -n 30 -t $CONTAINER_NAME

sleep 1

LOG_DIR=_logs
DATA_DIR=_data
mkdir -p $LOG_DIR
mkdir -p $DATA_DIR

# how long each .mp4 archive file is (in seconds)
SEGMENT_LEN=60

echo "Starting camera feed"

bash scripts/live_cameraA.sh > $LOG_DIR/live_cameraA.log 2>&1 &
pid=$!
echo "Started live camera feed A with pid $pid"

bash scripts/record_cameraA.sh > $LOG_DIR/_cameraA.log 2>&1 &
pid=$!
echo "Started recording stream A with pid $pid"



