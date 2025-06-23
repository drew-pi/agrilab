from flask import Flask, render_template, jsonify, request, send_file, abort
from dotenv import load_dotenv
import numpy as np

import os
import logging
import subprocess
import zipfile
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
    return render_template("viewer.html", ip=JETSON_IP)

@app.route("/recordings")
def list_recordings():
    RECORDINGS_PATH=os.getenv("RECORDINGS_PATH", "/recordings")
    files = sorted(os.listdir(RECORDINGS_PATH))
    return jsonify(files)

@app.route("/clip-form")
def clip_form():
    return render_template("clip.html")



def make_clip(start, start_offset, duration, camera, RECORDINGS_PATH, raw_clips, output_clipped_path):
    """
    make_clip is a helper function for the /clip API endpoint that dispatches the ffmpeg subprocesses and validates all clips in the given range
        - cleans up after itself by removing all intermediate files created
    """
    # file names
    clip_files_path = f"/tmp/concat_list_{camera}_{start.isoformat().replace(':', '-')}.txt"
    full_clip_path = f"/tmp/full_clip-{camera}-{start.isoformat().replace(':', '-')}.mp4"

    clip_full_file_names = [os.path.join(RECORDINGS_PATH, f"{_clip}-{camera}.mp4") for _clip in raw_clips]

    logging.info(f"Clips that are needed: {clip_full_file_names}")

    valid_clip_full_file_names = [f"file '{p}'" for p in clip_full_file_names if os.path.isfile(p)]

    logging.info(f"Missing {len(clip_full_file_names) - len(valid_clip_full_file_names)} clips")

    valid_clip_files = "\n".join(valid_clip_full_file_names)

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

    # remove intermediate steps (if they exist)
    os.path.exists(clip_files_path) and os.remove(clip_files_path)
    os.path.exists(full_clip_path) and os.remove(full_clip_path)





@app.route("/clip")
def download_clip():
    """
    API route that returns a video recording from a specified start to end point
    """

    start_ts = request.args.get("start")  # e.g., 2025-06-20T13:00:00
    end_ts = request.args.get("end")      # e.g., 2025-06-20T13:01:30

    camera = request.args.get("camera") # A, B or BOTH


    logging.info(f"Received clip request for camera {camera}: start={start_ts}, end={end_ts}")

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

    # paths
    zip_path = f"/tmp/clip-AB-{start.isoformat().replace(':', '-')}.zip"

    output_clipped_path_A = f"/tmp/{start.isoformat().replace(':', '-')}-cameraA.mp4"
    output_clipped_path_B = f"/tmp/{start.isoformat().replace(':', '-')}-cameraB.mp4"

    with zipfile.ZipFile(zip_path, 'w') as zipf:
        if camera == "A":
            make_clip(start, start_offset, duration, "A", RECORDINGS_PATH, raw_clips, output_clipped_path_A)
            zipf.write(output_clipped_path_A, arcname="cameraA.mp4")
        elif camera == "B":
            make_clip(start, start_offset, duration, "B", RECORDINGS_PATH, raw_clips, output_clipped_path_B)
            zipf.write(output_clipped_path_B, arcname="cameraB.mp4")
        else: # both
            make_clip(start, start_offset, duration, "A", RECORDINGS_PATH, raw_clips, output_clipped_path_A)
            make_clip(start, start_offset, duration, "B", RECORDINGS_PATH, raw_clips, output_clipped_path_B)

            zipf.write(output_clipped_path_A, arcname="cameraA.mp4")
            zipf.write(output_clipped_path_B, arcname="cameraB.mp4")

        # remove intermediate files after zipping (if they exist)
        os.path.exists(output_clipped_path_A) and os.remove(output_clipped_path_A)
        os.path.exists(output_clipped_path_B) and os.remove(output_clipped_path_B)

    return send_file(zip_path, mimetype="application/zip", as_attachment=True)




def get_frame(timestamp, output_path, camera, RECORDINGS_PATH, FILE_FMT):
    """
    get_frame is a helper function for the /frame API endpoint which dispatches the ffmpeg subprocess to capture the specified frame
        - cleans up after itself by removing all intermediate files created
    """
    
    path = os.path.join(RECORDINGS_PATH, f"{timestamp.strftime(FILE_FMT)}-{camera}.mp4")

    if not os.path.isfile(path):
        abort(404, "Segment not found")

    cmd  = [
        "ffmpeg", 
        "-ss", f"{timestamp.strftime('00:00:%S')}",
        # "-ss", f"{start.strftime('00:%M:%S')}", # use when SEGMENT_LEN=3600 because also have to worry about minutes
        "-i", str(path),
        "-frames:v", "1", 
        "-q:v", "2", 
        "-y", 
        output_path
    ]
    subprocess.run(cmd, check=True)

    logging.info(f"Sucessfully captured frame {path} and loaded into {output_path}")
    


@app.route("/frame")
def frame():
    """
    API route that returns specified frame
    """

    ts = datetime.fromisoformat(request.args.get("ts"))   
    camera  = request.args.get("camera")  # default to camera A
    
    RECORDINGS_PATH=os.getenv("RECORDINGS_PATH", "/recordings")

    FILE_FMT='%Y-%m-%dT%H:%M:00.000000'

    output_frame_path_A = f"/tmp/{ts.isoformat().replace(':', '-')}-frameA.jpg"
    output_frame_path_B = f"/tmp/{ts.isoformat().replace(':', '-')}-frameB.jpg"
    zip_path = f"/tmp/frame-AB-{ts.isoformat().replace(':', '-')}.zip"

    with zipfile.ZipFile(zip_path, 'w') as zipf:
        if camera == "A":
            get_frame(ts, output_frame_path_A, "A", RECORDINGS_PATH, FILE_FMT)
            zipf.write(output_frame_path_A, arcname="cameraA.jpg")
        elif camera == "B":
            get_frame(ts, output_frame_path_B, "B", RECORDINGS_PATH, FILE_FMT)
            zipf.write(output_frame_path_B, arcname="cameraB.jpg")
        else: # both
            get_frame(ts, output_frame_path_A, "A", RECORDINGS_PATH, FILE_FMT)
            get_frame(ts, output_frame_path_B, "B", RECORDINGS_PATH, FILE_FMT)

            zipf.write(output_frame_path_A, arcname="cameraA.jpg")
            zipf.write(output_frame_path_B, arcname="cameraB.jpg")

         # remove intermediate files after zipping (if they exist)
        os.path.exists(output_frame_path_A) and os.remove(output_frame_path_A)
        os.path.exists(output_frame_path_B) and os.remove(output_frame_path_B)

    return send_file(zip_path, mimetype="application/zip", as_attachment=True)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)