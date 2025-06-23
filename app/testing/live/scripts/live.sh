#!/bin/bash

## Usage
# bash scripts/live.sh [/dev/videoX] [A|B]
## 

set -euo pipefail
trap 'echo "[ERROR] Command failed at line $LINENO: $BASH_COMMAND" >&2' ERR

source .env

# check to see if only one argument passed in
if [[ $# -ne 2 ]]; then
    echo "[ERROR] Invalid input, found $# parameters."
    exit 1
fi

if [[ "$1" =~ ^/dev/video[0-9]+$ && "$2" =~ ^[AB]$ ]]; then
    CAMERA="$1"
    CAMERA_ID="$2"
else
    echo "[ERROR] Invalid camera device format or invalid camera ID. Used $1 and $2 instead"
    exit 1
fi

# other data
FRAME_RATE=5

echo "[INFO] Using framerate=$FRAME_RATE"
echo "[INFO] Using camera $CAMERA_ID with source=$CAMERA"
echo "[INFO] Using segment length=$SEGMENT_LEN"
echo "[INFO] Using jetson ip=$JETSON_IP"


echo "[INFO] beginning live camera$CAMERA_ID feed"

ffmpeg -re -f v4l2 -fflags +discardcorrupt \
    -input_format mjpeg -video_size 1280x960 -framerate $FRAME_RATE \
    -use_wallclock_as_timestamps 1 \
    -i "$CAMERA" \
    -vf "format=yuv420p,drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:
       text='%{localtime}':x=10:y=10:fontsize=32:fontcolor=white:box=1:boxcolor=black@0.5" \
    -c:v libx264 -preset ultrafast -tune zerolatency \
    -g 1 -keyint_min 1 -sc_threshold 0 \
    -force_key_frames "expr:gte(t,n_forced*${SEGMENT_LEN})" \
    -movflags +faststart \
    -loglevel warning \
    -f flv rtmp://$JETSON_IP/live/stream$CAMERA_ID





