# DevSecOps controls for a healthcare deployment

This implementation deliberately keeps protected health information (PHI) out of source, build logs, container images, and health endpoints. Production use still requires an organisation-specific threat model, legal review, and compliance controls.

## Controls implemented in code and delivery

| Risk area | Control |
| --- | --- |
| Application weaknesses | Semgrep OWASP Top 10 scan blocks the pipeline on findings. |
| Vulnerable packages | `pip-audit` runs before image creation. |
| Vulnerable OS/image packages | Trivy blocks high and critical, fixable image vulnerabilities. |
| Software inventory | Trivy produces a CycloneDX SBOM artifact per build. |
| Privilege escalation | Containers are non-root, read-only, drop all Linux capabilities, and use RuntimeDefault seccomp. |
| Lateral movement | Namespace-wide default-deny network policy; inbound traffic is limited to the API port. |
| Excessive cluster access | A namespace-scoped Jenkins deployment role grants only deployment/service/pod actions. |
| Secret leakage | Registry credentials are Jenkins credentials; no secrets are stored in manifests or source. |
| Unsafe release | Only a ready inactive colour receives traffic; the previous colour is retained for rollback. |

## Required production controls outside this repository

- Use a managed secret store (for example, External Secrets plus a cloud KMS), short-lived workload identity, and scheduled secret rotation.
- Encrypt PHI in transit and at rest; enforce strong authentication/authorisation and audit access to PHI.
- Sign images with Cosign and enforce signature, digest-only image references, SBOM, and vulnerability policies with Kyverno or Gatekeeper.
- Send immutable audit logs and CI scan results to the organisation's monitored security logging system; never include PHI in logs.
- Patch base images regularly and run a formal incident-response, backup, and disaster-recovery process.
