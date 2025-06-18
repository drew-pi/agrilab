#!/bin/bash

set -e

CONTAINER_NAME=live

sudo docker build -t $CONTAINER_NAME .

sudo docker run --rm --name live-stack --network host \
    -v $(pwd)/hls:/var/www/hls \
    $CONTAINER_NAME
