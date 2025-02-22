#!/bin/bash

CONTAINER=$1
DOCKERFILE=$2

# shift twice over so that can include all other arguments after
shift
shift

echo "Building $CONTAINER container..."

bash docker build --network=host -t $CONTAINER -f $DOCKERFILE "$@" .