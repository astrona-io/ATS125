#!/usr/bin/env bash
# Creates the starting state for ats-125-lab-020-01.
#
# 1. Applies the PersistentVolumeClaim roster-data, the ConfigMap
#    roster-settings, the Secret roster-token and a seed pod that writes
#    bridge/crew.txt and scout/crew.txt into the claim.
# 2. Waits until the seed pod has finished, then deletes it.
# 3. Applies the Task crew-roster.
#
# Writing the TaskRun that binds the workspaces is the task.
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

apply_with_retry "$MANIFESTS/roster-data.yaml"
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded pod/seed-roster-data --timeout=300s
kubectl -n starfleet logs seed-roster-data
kubectl -n starfleet delete pod seed-roster-data --wait=true

apply_with_retry "$MANIFESTS/task-crew-roster.yaml"

echo "[lab] Starting state ready."
kubectl -n starfleet get pvc,configmaps,secrets,tasks
echo "[lab] Write the TaskRun crew-roster-run that binds the three workspaces."
