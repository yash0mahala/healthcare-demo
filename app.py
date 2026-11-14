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
    # Development server is local only. Production uses Gunicorn in the container.
    app.run(host="127.0.0.1", port=8080)
