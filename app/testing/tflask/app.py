from flask import Flask, render_template
import os
from dotenv import load_dotenv

app = Flask(__name__)
load_dotenv()


@app.route('/')
def video():
    JETSON_HOST=os.getenv("JETSON_HOST")
    JETSON_PORT=os.getenv("JETSON_PORT")
    print(f"Getting stream from {JETSON_HOST}:{JETSON_PORT}")
    return render_template("video.html",
        jetson_host=JETSON_HOST,
        jetson_port=JETSON_PORT
    )


if __name__ == "__main__":
    app.run(debug=True)