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

    # file names: 2025_06_20_T1635_A.mp4
    filename = f"{start.strftime('%Y_%m_%d_T%H%M_A')}.mp4"
    RECORDINGS_PATH=os.getenv("RECORDINGS_PATH", "/recordings")
    input_path = os.path.join(RECORDINGS_PATH, filename)
    output_path = "/tmp/clip.mp4"

    # remove temporary file if it already exists
    if os.path.exists(output_path):
        os.remove(output_path)


    logging.info(f"Created file path: {input_path}")

    if not os.path.isfile(input_path):
        return abort(404, description="Recording not found.")

    duration = (end - start).total_seconds()

    cmd = [
        "ffmpeg",
        "-ss", f"{start.strftime('00:00:%S')}",
        "-i", input_path,
        "-t", str(duration),
        "-c", "copy",
        "-y", # answer yes to any pop ups
        output_path
    ]

    subprocess.run(cmd, check=True)
    return send_file(output_path, as_attachment=True)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)