from flask import Flask, render_template

app = Flask(__name__, template_folder='/templates')

@app.route("/")
def index():
    return render_template("viewer.html", hls_url="http://localhost:8080/hls/stream.m3u8")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)