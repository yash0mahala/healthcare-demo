# Teacher demonstration guide: items 7–9

## Before the demonstration

Use a local Kubernetes cluster such as Minikube, Kind, or Docker Desktop Kubernetes. Jenkins must run on a Linux agent labelled `linux-docker-k8s`, with Docker, `kubectl`, Python 3, Bash, and `sed`. Use a container registry account; Docker Hub is sufficient for a classroom demo.

In Jenkins, create a Pipeline job from this repository and set these environment variables:

```text
REGISTRY_HOST=docker.io
IMAGE_REPOSITORY=YOUR_DOCKERHUB_USER/healthcare-demo
DEPLOY_NAMESPACE=healthcare-demo
```

Create a Jenkins username/password credential named `registry-credentials`. Do not show the credential value during the demo.

Point the Jenkins agent's `kubectl` context at your demo cluster, then initialise the cluster once:

```sh
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/rbac.yaml
kubectl apply -f k8s/network-policy.yaml
kubectl apply -f k8s/service.yaml
```

## Part 1 — demonstrate item 7: CI/CD with Jenkins

1. Open `Jenkinsfile` and explain the stages: **Test → SAST → Dependency audit → Build image → Trivy scan → SBOM → Publish image → Blue-green deploy**.
2. Trigger **Build Now** in Jenkins.
3. Open the console output and show that each quality/security stage passed. Open the archived artifacts to show `semgrep.json`, `trivy-image.json`, and `sbom.cdx.json`.
4. Show that the Docker image was pushed with the Jenkins build number and Git revision in its tag.

What to say: “The pipeline will not publish or deploy a failed test, SAST finding, dependency issue, or high/critical fixable image vulnerability.”

## Part 2 — demonstrate item 8: blue-green deployment

After the first successful build, run:

```sh
kubectl -n healthcare-demo get deployments,pods,service -L app.kubernetes.io/color
kubectl -n healthcare-demo get service healthcare-demo -o jsonpath='{.spec.selector.app\.kubernetes\.io/color}{"\n"}'
```

The first build creates and serves **blue**.

Make a harmless visible change to `app.py` (for example change `"running"` to `"running-v2"`), commit it, and trigger a second Jenkins build. Run the commands again: both blue and green deployments remain, but the `Service` selector is now **green**. Explain that Jenkins waited for the inactive colour's readiness probe before switching traffic.

To demonstrate rollback, return traffic to blue without rebuilding:

```sh
kubectl -n healthcare-demo patch service healthcare-demo --type merge -p '{"spec":{"selector":{"app.kubernetes.io/name":"healthcare-demo","app.kubernetes.io/component":"api","app.kubernetes.io/color":"blue"}}}'
```

Then repeat the selector command to prove the rollback. The old deployment stays available, so rollback is quick.

## Part 3 — demonstrate item 9: DevSecOps controls

Show these files and explain the control next to it:

| File/stage | Evidence to show |
| --- | --- |
| Jenkins `SAST`, `Dependency audit`, `Image vulnerability scan` | Security gates block unsafe code/images. |
| Jenkins `SBOM` | CycloneDX software inventory is retained as a build artifact. |
| `k8s/deployment.yaml` | Non-root user, read-only filesystem, dropped capabilities, seccomp, readiness/liveness probes, resource limits. |
| `k8s/network-policy.yaml` | Default-deny network isolation and only port 8080 allowed inbound. |
| `k8s/jenkins-deployer-rbac.yaml` | Jenkins gets only namespace-scoped deployment/service/pod permissions. |
| `SECURITY.md` | PHI is excluded from code/logs and remaining production controls are documented. |

## Suggested screenshots/evidence

1. Jenkins console with all stages green.
2. Jenkins artifacts page containing SAST, Trivy, and SBOM reports.
3. Terminal before and after the second build showing the Service selector changing blue → green.
4. The `securityContext` and `NetworkPolicy` manifests.

Never put a real patient record, password, access token, or registry credential in the demo, repository, or screenshots.
