#!/usr/bin/env bash
# Installs the environment for ats-125-playground-030-01.
#
# Playground preparation only. There is no task and no grading.
# This script:
#   1. puts the tkn command-line tool (pinned) on the PATH,
#   2. applies lab-start.yaml: the namespace starfleet, the registry and the client pod,
#   3. installs Tekton Pipelines v1.17.1 from the release manifest and waits for the webhook,
#   4. does not install the Tekton Dashboard,
#   5. waits until the in-cluster registry answers,
#   6. fills the PersistentVolumeClaim bridge-source with a small Dockerfile.
set -euo pipefail

TKN_VERSION="0.46.2"
PIPELINES_VERSION="v1.17.1"
DASHBOARD_VERSION="v0.73.0"
INSTALL_PIPELINES="yes"   # yes or no
INSTALL_DASHBOARD="no"   # no, read-only or full
LOG="[playground]"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# Pin the version rather than accepting whatever tkn happens to be on the
# machine: the course is written against tkn ${TKN_VERSION}.
have_version=""
if command -v tkn >/dev/null 2>&1; then
  have_version="$(tkn version --component client 2>/dev/null || true)"
  have_version="${have_version#v}"
fi
if [ "$have_version" != "$TKN_VERSION" ]; then
  case "$(uname -s)" in
    Darwin) TKN_OS="Darwin"; TKN_ARCH="all" ;;
    Linux)
      TKN_OS="Linux"
      case "$(uname -m)" in
        x86_64|amd64) TKN_ARCH="x86_64" ;;
        aarch64|arm64) TKN_ARCH="aarch64" ;;
        *) echo "ERROR: no tkn release for $(uname -m)." >&2; exit 1 ;;
      esac ;;
    *) echo "ERROR: no tkn release for $(uname -s)." >&2; exit 1 ;;
  esac
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT
  echo "$LOG Downloading tkn ${TKN_VERSION} (${TKN_OS}/${TKN_ARCH})..."
  curl -fsSL -o "$WORK/tkn.tar.gz" \
    "https://github.com/tektoncd/cli/releases/download/v${TKN_VERSION}/tkn_${TKN_VERSION}_${TKN_OS}_${TKN_ARCH}.tar.gz"
  tar -xzf "$WORK/tkn.tar.gz" -C "$WORK" tkn
  install -m 0755 "$WORK/tkn" "$BIN_DIR/tkn"
fi
echo "$LOG tkn client version: $(tkn version --component client)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done
[ -n "$MANIFEST_DIR" ] || { echo "ERROR: manifests folder not found." >&2; exit 1; }

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"

apply_with_retry() {
  # apply_with_retry ARGS...: kubectl apply, retried while the API server or
  # the Tekton webhook is still starting.
  local attempt
  for attempt in $(seq 1 30); do
    if kubectl apply "$@"; then
      return 0
    fi
    echo "$LOG kubectl apply failed (attempt $attempt), retrying in 5s..."
    sleep 5
  done
  echo "ERROR: kubectl apply $* kept failing." >&2
  return 1
}

wait_for_tekton_webhook() {
  # The webhook validates every Tekton object. A Deployment can be Available a
  # moment before its Service answers, so retry a server-side dry run of a
  # small Task until the webhook accepts it.
  local probe attempt
  probe="$(mktemp)"
  cat > "$probe" <<'YAML'
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: webhook-probe
  namespace: starfleet
spec:
  steps:
    - name: probe
      image: busybox:1.37.0
      script: |
        echo probe
YAML
  for attempt in $(seq 1 60); do
    if kubectl apply --dry-run=server -f "$probe" >/dev/null 2>&1; then
      rm -f "$probe"
      echo "$LOG The Tekton webhook answers."
      return 0
    fi
    sleep 5
  done
  rm -f "$probe"
  echo "ERROR: the Tekton webhook did not accept a Task within 5 minutes." >&2
  return 1
}

if [ "$INSTALL_PIPELINES" = "yes" ]; then
  echo "$LOG Installing Tekton Pipelines ${PIPELINES_VERSION}..."
  apply_with_retry -f "https://infra.tekton.dev/tekton-releases/pipeline/previous/${PIPELINES_VERSION}/release.yaml"
  for deployment in tekton-pipelines-controller tekton-pipelines-webhook tekton-events-controller; do
    kubectl -n tekton-pipelines rollout status "deployment/$deployment" --timeout=300s
  done
  kubectl -n tekton-pipelines-resolvers rollout status deployment/tekton-pipelines-remote-resolvers --timeout=300s
  wait_for_tekton_webhook
fi

case "$INSTALL_DASHBOARD" in
  read-only) DASHBOARD_FILE="release.yaml" ;;
  full) DASHBOARD_FILE="release-full.yaml" ;;
  *) DASHBOARD_FILE="" ;;
esac
if [ -n "$DASHBOARD_FILE" ]; then
  echo "$LOG Installing the Tekton Dashboard ${DASHBOARD_VERSION} (${DASHBOARD_FILE})..."
  apply_with_retry -f "https://infra.tekton.dev/tekton-releases/dashboard/previous/${DASHBOARD_VERSION}/${DASHBOARD_FILE}"
  kubectl -n tekton-pipelines rollout status deployment/tekton-dashboard --timeout=300s
fi

# The in-cluster OCI registry and the client pod come from lab-start.yaml.
# Wait until both run, then until the registry answers /v2/ from inside the
# cluster. No host port is used.
wait_for_registry() {
  local attempt code
  kubectl -n registry rollout status deployment/registry --timeout=300s
  kubectl -n registry rollout status deployment/client --timeout=300s
  for attempt in $(seq 1 60); do
    code="$(kubectl -n registry exec deploy/client -- \
      curl -s -o /dev/null -w '%{http_code}' http://registry.registry.svc.cluster.local:5000/v2/ 2>/dev/null || true)"
    if [ "$code" = "200" ]; then
      echo "$LOG The registry answers /v2/ inside the cluster."
      return 0
    fi
    sleep 5
  done
  echo "ERROR: the registry did not answer /v2/ within 5 minutes." >&2
  return 1
}
wait_for_registry

# Source code for the build examples: the PersistentVolumeClaim bridge-source
# with bridge-app/Dockerfile and bridge-app/message.txt, written by a seed pod.
kubectl apply -f "$MANIFEST_DIR/bridge-source.yaml"
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded pod/seed-bridge-source --timeout=300s
kubectl -n starfleet delete pod seed-bridge-source --wait=true

echo "$LOG Environment ready."
kubectl get pods -n tekton-pipelines 2>/dev/null || true
