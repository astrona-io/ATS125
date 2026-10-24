#!/usr/bin/env bash
# Creates the starting state for ats-125-capstone-030.
#
# 1. Applies the ConfigMap bridge-app-files, the PersistentVolumeClaim
#    bridge-source and a seed pod that copies the source into bridge-app/.
# 2. Waits until the seed pod has finished, then deletes it.
# 3. Applies the Task image-build (three faults) and the TaskRun
#    image-build-run, and waits until the TaskRun has ended. Because of the
#    faults it ends with Succeeded=True, but nothing is pushed.
#
# Finding and fixing the three faults is the task.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

apply_with_retry() {
  # apply_with_retry FILE: the webhook can refuse the first objects while it starts.
  local attempt
  for attempt in $(seq 1 30); do
    kubectl apply -f "$1" && return 0
    echo "[lab] kubectl apply -f $1 failed (attempt $attempt), retrying in 5s..."
    sleep 5
  done
  return 1
}

wait_for_taskrun_end() {
  # wait_for_taskrun_end NAME: waits until the Succeeded condition is True or False.
  local status=""
  for _ in $(seq 1 100); do
    status="$(kubectl -n starfleet get taskrun "$1" \
      -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null || true)"
    if [ "$status" = "True" ] || [ "$status" = "False" ]; then
      echo "[lab] TaskRun $1 ended with Succeeded=$status."
      return 0
    fi
    sleep 3
  done
  echo "ERROR: TaskRun $1 did not end in time." >&2
  return 1
}

apply_with_retry "$MANIFESTS/bridge-source.yaml"
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded pod/seed-bridge-source --timeout=300s
kubectl -n starfleet logs seed-bridge-source
kubectl -n starfleet delete pod seed-bridge-source --wait=true

apply_with_retry "$MANIFESTS/task-image-build.yaml"
apply_with_retry "$MANIFESTS/taskrun-image-build-run.yaml"
wait_for_taskrun_end image-build-run

echo "[lab] Starting state ready."
kubectl -n starfleet get pvc,tasks,taskruns
echo "[lab] image-build-run reports success, but the registry has no image. Finding out why is the task."
