#!/usr/bin/env bash
set -euo pipefail

namespace="${1:?namespace is required}"
image="${2:?immutable image reference is required}"
service="healthcare-demo"
manifest_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../k8s" && pwd)"

for command in kubectl sed; do
  command -v "$command" >/dev/null || { echo "Missing required command: $command" >&2; exit 1; }
done

# No existing colour deployment means this is the first release: blue becomes stable.
active_color="$(kubectl -n "$namespace" get service "$service" -o jsonpath='{.spec.selector.app\.kubernetes\.io/color}' 2>/dev/null || true)"
if ! kubectl -n "$namespace" get deployment "$service-blue" >/dev/null 2>&1 \
  && ! kubectl -n "$namespace" get deployment "$service-green" >/dev/null 2>&1; then
  next_color="blue"
elif [[ "$active_color" == "blue" ]]; then
  next_color="green"
else
  next_color="blue"
fi

echo "Deploying $image to inactive colour: $next_color"
sed -e "s|COLOR_PLACEHOLDER|$next_color|g" -e "s|IMAGE_PLACEHOLDER|$image|g" \
  "$manifest_dir/deployment.yaml" | kubectl -n "$namespace" apply -f -

kubectl -n "$namespace" rollout status "deployment/$service-$next_color" --timeout=180s

# Traffic changes only after rollout status confirms the new replicas are ready.
kubectl -n "$namespace" patch service "$service" --type merge \
  -p "{\"spec\":{\"selector\":{\"app.kubernetes.io/name\":\"healthcare-demo\",\"app.kubernetes.io/component\":\"api\",\"app.kubernetes.io/color\":\"$next_color\"}}}"

echo "Traffic switched to $next_color. Previous colour remains available for rollback."
