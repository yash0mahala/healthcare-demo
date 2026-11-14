# Secure Blue-Green CI/CD Demo

This project implements:

1. **Item 7** — Jenkins CI/CD that tests, scans, containerizes, and deploys an application to Kubernetes.
2. **Item 8** — automated blue-green releases. The stable `Service` is switched only after the inactive colour passes its readiness check.
3. **Item 9** — DevSecOps controls suitable for a healthcare workload: SAST, dependency and image scanning, non-root/restricted containers, network isolation, least-privilege RBAC, and no repository secrets.

## Prerequisites

- Docker (for local container runs)
- A Kubernetes cluster and `kubectl` (for deployment)
- A Jenkins Linux agent labelled `linux-docker-k8s`, with Docker, `kubectl`, `python3`, Bash, and `sed`
- Jenkins credentials named `registry-credentials` for the container registry

## Local verification

```sh
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
pytest
python app.py
```

The service responds on `http://localhost:8080/healthz`.

## Deploy manually

Set an immutable image reference, then run the script. The first release uses blue; later releases automatically deploy to the inactive colour and switch traffic after readiness succeeds.

```sh
export IMAGE=registry.example.com/healthcare-demo:1.0.0
bash scripts/deploy-blue-green.sh healthcare-demo "$IMAGE"
```

Create the namespace controls once before the first deployment:

```sh
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/rbac.yaml
kubectl apply -f k8s/network-policy.yaml
kubectl apply -f k8s/service.yaml
```

## Jenkins configuration

1. Create a Pipeline job pointing at this repository and its `Jenkinsfile`.
2. Add a username/password or token credential with ID `registry-credentials`.
3. When selecting **Build with Parameters**, set `REGISTRY_HOST` (for example `docker.io`), `IMAGE_REPOSITORY` (for example `your-dockerhub-user/healthcare-demo`), and optionally `DEPLOY_NAMESPACE`. Do not set secrets in the Jenkinsfile.
4. Grant the Jenkins Kubernetes service account only the namespace-scoped permissions it needs to deploy these resources.

The pipeline expects an immutable build tag (`BUILD_NUMBER` plus the source revision). In production, add an image-signing key to Jenkins and require signed images at admission.
