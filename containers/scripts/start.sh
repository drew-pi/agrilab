#!/bin/bash

# exit if error occurs
set -e

DOCKERFILE="../Dockerfile"
CONTAINER="jetson_jupyter"

# build the container
./build.sh $CONTAINER $DOCKERFILE

# check to see if already existing version
if [ "$(sudo docker ps -aq -f name=$CONTAINER)" ]; then
    echo "Removing existing container..."
    sudo docker stop $CONTAINER
    sudo docker rm $CONTAINER
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ROOT=$(git rev-parse --show-toplevel)
else
    ROOT=$(pwd)
fi

echo "Starting new container..."
sudo docker run -d --name $CONTAINER --network=host \
    -v $ROOT/notebooks:/home/persephone/notebooks \
    -v $ROOT/.jupyter_logs/logs:/home/persephone/logs \
    $CONTAINER

echo "Container started"
echo $(sudo docker logs --tail=2 jetson_jupyter)