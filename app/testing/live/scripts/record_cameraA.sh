#!/bin/bash

set -u

trap 'echo "[ERROR] Command failed at line $LINENO: $BASH_COMMAND" >&2' ERR

source .env

echo "[INFO] Using segment length=$SEGMENT_LEN"
echo "[INFO] Using jetson ip=$JETSON_IP"
echo "[INFO] Using data directory=$DATA_DIR"

MIN_CUTOFF=$(( SEGMENT_LEN / 30 ))

record_aligned_segments() {
    now=$(date +%s)
    WAIT_TIME=$(( (SEGMENT_LEN - now % SEGMENT_LEN) % SEGMENT_LEN ))
    echo -e "\n[INFO] Starting aligned segmentation loop in $WAIT_TIME seconds\n"
    sleep $WAIT_TIME

    echo -e "\n[INFO] Starting aligned segmentation loop at $(date)\n"
    ffmpeg -rw_timeout 15000000 \
        -f flv -i "rtmp://$JETSON_IP/live/streamA live=1" \
        -c copy \
        -f segment \
        -segment_time "$SEGMENT_LEN" \
        -reset_timestamps 1 \
        -strftime 1 \
        -movflags +faststart \
        -loglevel warning \
        "$DATA_DIR/%Y_%m_%d_T%H%M_A.mp4"
}

# Added robust short recording because sometimes it fails to capture the live stream even if it exists and very inconsistent

while true; do
    now=$(date +%s)
    TIME=$(( ((SEGMENT_LEN - now % SEGMENT_LEN) % SEGMENT_LEN) - 2 ))

    # if less than 1/30 of segement length until boundary just sleep
    if [ "$TIME" -lt "$MIN_CUTOFF" ]; then
        echo -e "\n[INFO] Only $TIME seconds left before boundary. Skipping short segment.\n"
        record_aligned_segments
        continue
    fi

    echo -e "\n[INFO] Attempting short pre-alignment recording for $TIME seconds...\n"

    # short segment of $TIME instead of sleeping 
    if ffmpeg -rw_timeout 15000000 \
        -f flv -i "rtmp://$JETSON_IP/live/streamA live=1" \
        -c copy \
        -t "$TIME" \
        -movflags +faststart \
        "$DATA_DIR/$(date +%Y_%m_%d_T%H%M)_A.mp4"; then

        echo -e "\n[INFO] Short segment completed successfully. Proceeding to long term recorder\n"

        record_aligned_segments
        continue
    else
        echo -e "\n[WARN] Short segment failed at $(date). Retrying in 5 seconds...\n"
        sleep 5
    fi
done




