from app import app


def test_healthz_is_healthy():
    response = app.test_client().get("/healthz")
    assert response.status_code == 200
    assert response.json == {"status": "ok"}


def test_index_exposes_no_patient_data():
    response = app.test_client().get("/")
    assert response.status_code == 200
    assert response.json == {"service": "healthcare-demo", "status": "running"}
