#!/bin/bash

set -euo pipefail

source .env

echo "[INFO] Using segment length=$SEGMENT_LEN"
echo "[INFO] Using jetson ip=$JETSON_IP"
echo "[INFO] Using data directory=$DATA_DIR"

while true; do
    # get the current time
    now=$(date +%s)
    WAIT_TIME=$(( (SEGMENT_LEN - now % SEGMENT_LEN) % SEGMENT_LEN ))

    echo "[INFO] Waiting for $WAIT_TIME seconds until next recording start"
    sleep $WAIT_TIME
    echo "[INFO] Starting recording for streamA at $(date) and storing in $DATA_DIR/"

    ffmpeg -f flv -i "rtmp://$JETSON_IP/live/streamA live=1" \
           -rw_timeout 15000000 \
           -c copy \
           -f segment \
           -segment_time "$SEGMENT_LEN" \
           -reset_timestamps 1 \
           -strftime 1 \
           -movflags +faststart \
           "$DATA_DIR/%Y_%m_%d_T%H%M_A.mp4"

           #     -loglevel warning \

    echo "[WARN] ffmpeg exited at $(date), restarting in 2 seconds..."
    sleep 2
done







