from flask import Flask, render_template, jsonify, request, send_file, abort
from dotenv import load_dotenv
import numpy as np

import os
import logging
import subprocess
from datetime import datetime

app = Flask(__name__, template_folder='/templates')

# load all environment files (i.e .env)
load_dotenv()

# Configure logging globally
logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s [%(name)s] %(message)s"
)
logger = logging.getLogger(__name__)


def clear_tmp():
    subprocess.run("rm -rf /tmp/*.jpg /tmp/*.mp4 /tmp/*.txt", shell=True, check=True)


@app.route("/")
def index():
    JETSON_IP=os.getenv("JETSON_IP")
    return render_template("viewer.html", hls_url=f"http://{JETSON_IP}:8080/hls/streamA.m3u8")

@app.route("/recordings")
def list_recordings():
    RECORDINGS_PATH=os.getenv("RECORDINGS_PATH", "/recordings")
    files = sorted(os.listdir(RECORDINGS_PATH))
    return jsonify(files)

@app.route("/clip-form")
def clip_form():
    return render_template("clip.html")


@app.route("/clip")
def download_clip():
    """
    API route that dispatches a ffmpeg worker to cut a video
    """
    start_ts = request.args.get("start")  # e.g., 2025-06-20T13:00:00
    end_ts = request.args.get("end")      # e.g., 2025-06-20T13:01:30

    logging.info(f"Received clip request: start={start_ts}, end={end_ts}")

    # convert to datetime objects
    start = datetime.fromisoformat(start_ts)
    end = datetime.fromisoformat(end_ts)

    # used later for how long to record the concatenated video file
    duration = (end - start).total_seconds()
    start_offset = f"{start.strftime('00:00:%S')}"

    start = start.replace(second=0, microsecond=0)

    # start.replace(minute=0, second=0, microsecond=0)

    logging.info(f"Start time aligned to boundry is {start}")

    # make sure the end is after start
    if start > end:
        return abort(404, description="Cannot have start clip time be ahead of the end clip time")
    
    RECORDINGS_PATH=os.getenv("RECORDINGS_PATH", "/recordings")
    SEGMENT_LEN=int(os.getenv("SEGMENT_LEN", 3600))

    raw_clips = np.arange(start, end, np.timedelta64(SEGMENT_LEN, "s"))
    clip_full_file_names = [os.path.join(RECORDINGS_PATH, f"{_clip}-A.mp4") for _clip in raw_clips]

    logging.info(f"Clips that are needed: {clip_full_file_names}")

    valid_clip_full_file_names = [f"file '{p}'" for p in clip_full_file_names if os.path.isfile(p)]

    logging.info(f"Missing {len(clip_full_file_names) - len(valid_clip_full_file_names)} clips")

    valid_clip_files = "\n".join(valid_clip_full_file_names)

    clip_files_path = f"/tmp/concat_list-{"A"}-{start.isoformat()}.txt"
    full_clip_path = f"/tmp/full_clip-{"A"}-{start.isoformat()}.mp4"
    output_clipped_path = f"/tmp/clip-{"A"}-{start.isoformat()}.mp4"

    with open(clip_files_path, "w") as f:
        f.write(valid_clip_files)

    cmd = [
        "ffmpeg",
        "-f", "concat",
        "-safe", "0",
        "-i", clip_files_path,
        "-c", "copy",
        "-y",
        full_clip_path
    ]

    subprocess.run(cmd, check=True)

    logging.info(f"Concatenated {len(valid_clip_full_file_names)} existing clips into {full_clip_path}")

    cmd = [
        "ffmpeg",
        "-ss", start_offset,
        # "-ss", f"{start.strftime('00:%M:%S')}", # use when SEGMENT_LEN=3600 because also have to worry about minutes
        "-i", full_clip_path,
        "-t", str(duration),
        "-c", "copy",
        "-y", # answer yes to any pop ups
        output_clipped_path
    ]

    subprocess.run(cmd, check=True)
    return send_file(output_clipped_path, as_attachment=True)


@app.route("/frame")
def frame():
    ts = datetime.fromisoformat(request.args.get("ts"))   
    camera  = request.args.get("camera", "A")  # default to camera A
    
    RECORDINGS_PATH=os.getenv("RECORDINGS_PATH", "/recordings")

    FILE_FMT='%Y-%m-%dT%H:%M:00.000000'

    path = os.path.join(RECORDINGS_PATH, f"{ts.strftime(FILE_FMT)}-{camera}.mp4")

    if not os.path.isfile(path):
        abort(404, "Segment not found")

    output_frame_path = f"/tmp/frame-{camera}-{ts.isoformat()}.jpg"

    cmd  = [
        "ffmpeg", 
        "-ss", f"{ts.strftime('00:00:%S')}",
        # "-ss", f"{start.strftime('00:%M:%S')}", # use when SEGMENT_LEN=3600 because also have to worry about minutes
        "-i", str(path),
        "-frames:v", "1", 
        "-q:v", "2", 
        "-y", 
        output_frame_path
    ]
    
    subprocess.run(cmd, check=True)
    return send_file(output_frame_path, mimetype="image/jpeg")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)