from flask import Flask, render_template
import os
from dotenv import load_dotenv

app = Flask(__name__)
load_dotenv()


@app.route('/')
def video():
    return render_template("video.html",
        jetson_host=os.getenv("JETSON_HOST"),
        jetson_port=os.getenv("JETSON_PORT")
    )


if __name__ == "__main__":
    app.run(debug=True)