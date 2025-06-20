#!/bin/bash

set -euo pipefail

trap 'echo "[ERROR] Command failed at line $LINENO: $BASH_COMMAND" >&2' ERR

echo "Shutting down all app processes in 5 seconds"
sleep 5

CONTAINER_NAME=live

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

echo "Removing logs"
LOG_DIR=_logs
rm -rf _logs