#!/bin/bash

## Usage
# bash scripts/record.sh [A|B]
## 

set -euo pipefail
trap 'echo "[ERROR] Command failed at line $LINENO: $BASH_COMMAND" >&2' ERR

source .env.local

# check to see if only one argument passed in
if [[ $# -ne 1 ]]; then
    echo "[ERROR] Invalid input, found $# parameters."
    exit 1
fi

if [[ "$1" =~ ^[AB]$ ]]; then
    CAMERA_ID="$1"
else
    echo "[ERROR] Invalid camera ID. Used ID $1 instead"
    exit 1
fi

echo "[INFO] Recording camera $CAMERA_ID stream"
echo "[INFO] Using segment length=$SEGMENT_LEN"
echo "[INFO] Using jetson ip=$JETSON_IP"
echo "[INFO] Using data directory=$DATA_DIR"
echo "[INFO] Using file format=$FILE_FMT-$CAMERA_ID.mp4"

SAVE_DIR=$DATA_DIR
# making sure that the directory exists
mkdir -p $SAVE_DIR

echo "[INFO] Saving files to $SAVE_DIR"

MIN_CUTOFF=$(( SEGMENT_LEN / 30 ))

record_aligned_segments() {
    now=$(date +%s)
    WAIT_TIME=$(( (SEGMENT_LEN - now % SEGMENT_LEN) % SEGMENT_LEN ))
    echo -e "\n[INFO] Starting aligned segmentation loop in $WAIT_TIME seconds\n"
    sleep $WAIT_TIME

    echo -e "\n[INFO] Starting aligned segmentation loop at $(date)\n"

    ffmpeg -rw_timeout 15000000 \
        -f flv -i "rtmp://$JETSON_IP/live/stream$CAMERA_ID live=1" \
        -c copy \
        -f segment \
        -segment_time "$SEGMENT_LEN" \
        -reset_timestamps 1 \
        -strftime 1 \
        -movflags +faststart \
        -loglevel warning \
        "$SAVE_DIR/$FILE_FMT-$CAMERA_ID.mp4"
}

# Added robust short recording because sometimes it fails to capture the live stream even if it exists and very inconsistent

while true; do
    now=$(date +%s)
    TIME=$(( ((SEGMENT_LEN - now % SEGMENT_LEN) % SEGMENT_LEN) - 2 ))

    # if less than 1/30 of segement length until boundary just sleep
    if [ "$TIME" -ge 0 ] && [ "$TIME" -lt "$MIN_CUTOFF" ]; then
        echo -e "\n[INFO] Only $TIME seconds left before boundary. Skipping short segment.\n"
        record_aligned_segments
        continue
    fi

    echo -e "\n[INFO] Attempting short pre-alignment recording for $TIME seconds...\n"

    # short segment of $TIME instead of sleeping 
    if ffmpeg -rw_timeout 15000000 \
        -f flv -i "rtmp://$JETSON_IP/live/stream$CAMERA_ID live=1" \
        -c copy \
        -t "$TIME" \
        -movflags +faststart \
        -y \
        "$SAVE_DIR/$(date +$FILE_FMT)-$CAMERA_ID.mp4"; then

        echo -e "\n[INFO] Short segment completed successfully. Proceeding to long term recorder\n"

        record_aligned_segments
        continue
    else
        echo -e "\n[WARN] Short segment failed at $(date). Retrying in 1 second...\n"
        sleep 1
    fi
done

while true; do
    now=$(date +%s)
    TIME=$(( (SEGMENT_LEN - now % SEGMENT_LEN) % SEGMENT_LEN ))

    if (( TIME < 2 )); then
        echo -e "\n[INFO] Less than 2s remaining until boundary. Restarting the loop\n"
        sleep $TIME
        continue
    elif (( TIME < MIN_CUTOFF )); then
        echo -e "\n[INFO] $TIME seconds left until boundary. Skipping short segment and starting aligned recorder.\n"
        record_aligned_segments
        continue
    else
        echo -e "\n[INFO] Attempting short pre-alignment recording for $TIME seconds...\n"
    fi

    if ffmpeg -rw_timeout 15000000 \
        -f flv -i "rtmp://$JETSON_IP/live/stream$CAMERA_ID live=1" \
        -c copy \
        -t "$TIME" \
        -movflags +faststart \
        -y \
        "$SAVE_DIR/$(date +$FILE_FMT)-$CAMERA_ID.mp4"; then

        echo -e "\n[INFO] Short segment completed successfully. Proceeding to long term aligned recorder\n"
        record_aligned_segments
    else
        echo -e "\n[WARN] Short segment failed at $(date). Retrying in 1 second...\n"
        sleep 1
    fi
done




