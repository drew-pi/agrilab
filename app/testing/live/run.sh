#!/bin/bash

set -euo pipefail
trap 'echo "[ERROR] Command failed at line $LINENO: $BASH_COMMAND" >&2' ERR

source .env.local

echo "Current ip address is $(hostname -I | awk '{print $1}')"
echo "Using address $JETSON_IP"

# check to see if already existing version
if [ "$(sudo docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Removing existing container..."
    sudo docker stop $CONTAINER_NAME
    echo "Successfully stopped the container"
    sudo docker rm $CONTAINER_NAME || true
fi

echo "Removing all recording and live feed background processes"
pids=$(ps -eo pid,cmd | grep "[b]ash scripts/" | awk '{print $1}' || true)

if [[ -n "$pids" ]]; then
    for pid in $pids; do
        echo "Found script PID: $pid"
        
        # Print full command used to launch the script
        cmd=$(ps -p "$pid" -o cmd=) || true
        echo "The command was: $cmd"
        
        # Kill the script itself
        kill "$pid"

        echo "" 
    done
fi

# ps aux | grep [f]fmpeg
pkill -x ffmpeg || true


echo "Rebuilding $IMAGE_NAME"
sudo docker build -t $IMAGE_NAME .

# start in detached mode
sudo docker run --rm -d --name $CONTAINER_NAME --network host \
    -v $(pwd)/hls:/var/www/hls \
    -v $(pwd)/_data:/recordings \
    $IMAGE_NAME

echo "Waiting for $CONTAINER_NAME to start"
sleep 3

sudo docker logs -n 30 -t $CONTAINER_NAME

sleep 1

mkdir -p $LOG_DIR
mkdir -p $DATA_DIR

echo "Starting camera feed and recording"

setsid bash scripts/live.sh /dev/video0 A > "$LOG_DIR/live_cameraA.log" 2>&1 &
live_pid_A=$!
echo "Started background live process A with pid $live_pid_A"

setsid bash scripts/live.sh /dev/video1 B > "$LOG_DIR/live_cameraB.log" 2>&1 &
live_pid_B=$!
echo "Started background live process B with pid $live_pid_B"

sleep 1

setsid bash scripts/record.sh A > $LOG_DIR/record_cameraA.log 2>&1 &
rec_pid_A=$!
echo "Started background recording process A with pid $rec_pid_A"

setsid bash scripts/record.sh B > $LOG_DIR/record_cameraB.log 2>&1 &
rec_pid_B=$!
echo "Started background recording process B with pid $rec_pid_B"




