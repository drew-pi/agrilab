#!/bin/bash

source .env

CAMERA_A=/dev/video0

# other data
FRAME_RATE=5


ffmpeg -re -f v4l2 -fflags +discardcorrupt \
    -input_format mjpeg -video_size 1280x960 -framerate $FRAME_RATE \
    -i $CAMERA_A \
    -vf "format=yuv420p,drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:
       text='%{localtime}':x=10:y=10:fontsize=32:fontcolor=white:box=1:boxcolor=black@0.5" \
    -c:v libx264 -preset ultrafast -tune zerolatency \
    -g 1 -keyint_min 1 -sc_threshold 0 \
    -f flv rtmp://$JETSON_IP/live/stream \
    -loglevel warning # for production so that doesn't cloud the screen