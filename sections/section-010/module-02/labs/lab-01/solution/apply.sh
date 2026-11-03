#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$SCRIPT_DIR/task-launch-log.yaml"
kubectl apply -f "$SCRIPT_DIR/taskrun-launch-log-run.yaml"
kubectl -n starfleet wait --for=condition=Succeeded taskrun/launch-log-run --timeout=300s
