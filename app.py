from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/healthz")
def healthz():
    """Unauthenticated liveness/readiness endpoint; exposes no patient data."""
    return jsonify(status="ok"), 200


@app.get("/")
def index():
    return jsonify(service="healthcare-demo", status="running"), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
