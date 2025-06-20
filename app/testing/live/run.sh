#!/bin/bash

set -euo pipefail

IMAGE_NAME=live-poc
CONTAINER_NAME=live

JETSON_IP=$(hostname -I | awk '{print $1}')
echo "Current ip address is $JETSON_IP"
echo "JETSON_IP=$JETSON_IP" > .env

# check to see if already existing version
if [ "$(sudo docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Removing existing container..."
    sudo docker stop $CONTAINER_NAME
    echo "Successfully stopped the container"
    # sudo docker rm $CONTAINER_NAME
fi

echo "Removing all recording and live feed background processes"
pids=$(ps -eo pid,cmd | grep "[b]ash scripts/" | awk '{print $1}')

for pid in $pids; do
    echo "Found script PID: $pid"
    
    # Print full command used to launch the script
    cmd=$(ps -p "$pid" -o cmd=)
    echo "The command was: $cmd"
    
    # Kill the script itself
    kill "$pid"

    echo "" 
done

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
export DATA_DIR=_data
mkdir -p $LOG_DIR
mkdir -p $DATA_DIR

# how long each .mp4 archive file is (in seconds)
export SEGMENT_LEN=60

echo "Starting camera feed"

setsid bash scripts/live_cameraA.sh > "$LOG_DIR/live_cameraA.log" 2>&1 &
live_pid=$!
echo "Started background live process A with pid $live_pid"

sleep 1

setsid bash scripts/record_cameraA.sh > $LOG_DIR/record_cameraA.log 2>&1 &
rec_pid=$!
echo "Started background recording process A with pid $rec_pid"



