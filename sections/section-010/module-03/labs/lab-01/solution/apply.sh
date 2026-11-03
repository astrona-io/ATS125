#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$SCRIPT_DIR/task-ship-card.yaml"
kubectl apply -f "$SCRIPT_DIR/taskrun-ship-card-run.yaml"
kubectl -n starfleet wait --for=condition=Succeeded taskrun/ship-card-run --timeout=300s
