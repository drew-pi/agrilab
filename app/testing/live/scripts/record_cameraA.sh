#!/bin/bash

source .env

# get the current time
now=$(date +%s)
WAIT_TIME=$(($SEGMENT_LEN - $now % $SEGMENT_LEN))

echo "Waiting for $WAIT_TIME seconds until next recording start"
sleep $WAIT_TIME
echo "Starting recording for $STREAM" 

# Run ffmpeg to record from the RTMP stream and split into hourly segments (at each hour exactly)
ffmpeg -f flv -i rtmp://$JETSON_IP/live/streamA \
    -c copy \
    -f segment \
    -segment_time $SEGMENT_LEN \
    -reset_timestamps 1 \
    -strftime 1 \
    -movflags +faststart \
    -loglevel warning \
    "$DATA_DIR/%Y_%m_%d_T%H%M_A.mp4"


