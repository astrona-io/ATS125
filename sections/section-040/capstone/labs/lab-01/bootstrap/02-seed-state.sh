#!/usr/bin/env bash
# Creates the starting state for ats-125-capstone-040.
#
# Applies the Task nightly-report and three TaskRuns: nightly-report-timeout has timed out, nightly-report-runaway is running for an hour, nightly-report-held is pending.
#
# Finding and fixing what is wrong is the task.
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
  for _ in $(seq 1 90); do
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

apply_with_retry "$MANIFESTS/nightly-report-task.yaml"
apply_with_retry "$MANIFESTS/nightly-report-runs.yaml"
wait_for_taskrun_end nightly-report-timeout

echo "[lab] Starting state ready."
kubectl -n starfleet get tasks,taskruns 2>/dev/null || true
