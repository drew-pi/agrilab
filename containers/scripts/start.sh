#!/bin/bash

DOCKERFILE="Dockerfile"
CONTAINER="jetson_jupyter"

# build the container
bash build.sh $CONTAINER $DOCKERFILE

# check to see if already existing version
if [ "$(docker ps -aq -f name=$CONTAINER)" ]; then
    echo "Removing existing container..."
    docker stop $CONTAINER
    docker rm $CONTAINER
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ROOT=$(git rev-parse --show-toplevel)
else
    ROOT=$(pwd)
fi

echo "Starting new container..."
bash docker run -d --name $CONTAINER --network=host \
    -v $(ROOT)/notebooks:/home/jupyteruser/notebooks \
    -v $(ROOT)/.jupyter_logs/logs:/home/jupyteruser/logs \
    $IMAGE_NAME

echo "Container started"