from flask import Flask, render_template
import os
from dotenv import load_dotenv

load_dotenv()
app = Flask(__name__, template_folder='/templates')

@app.route("/")
def index():
    JETSON_IP=os.getenv("JETSON_IP")
    return render_template("viewer.html", hls_url=f"http://{JETSON_IP}:8080/hls/stream.m3u8")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)