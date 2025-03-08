#!/bin/bash

# exit if error occurs
set -e

NAME=ml_lab
IMAGE="nvcr.io/nvidia/l4t-ml:r32.7.1-py3"

# check to see if already existing version
if [ "$(sudo docker ps -aq -f name=$NAME)" ]; then
    echo "Removing existing container..."
    sudo docker stop $NAME
    sudo docker rm $NAME
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ROOT=$(git rev-parse --show-toplevel)
else
    ROOT=$(pwd)
fi

echo "Starting new container..."
sudo docker run -it -d --name $NAME --network=host --runtime=nvidia \
    -v $ROOT/workspaces:/root/workspaces \
    $IMAGE

echo "Container started"
echo $(sudo docker logs --tail=2 $NAME)