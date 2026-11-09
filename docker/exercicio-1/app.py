from flask import Flask, Response

app = Flask(__name__)


@app.get("/")
def hello():
    return Response("Hello from Docker!", mimetype="text/plain")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)
