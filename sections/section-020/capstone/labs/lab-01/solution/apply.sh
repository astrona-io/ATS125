#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Make the workspace output writable again.
kubectl apply -f "$SCRIPT_DIR/task-deck-report.yaml"

# 2. One PersistentVolumeClaim per TaskRun, and the right subPath.
kubectl -n starfleet delete taskrun deck-report-run --ignore-not-found --wait=true
kubectl apply -f "$SCRIPT_DIR/taskrun-deck-report-run.yaml"
kubectl -n starfleet wait --for=condition=Succeeded taskrun/deck-report-run --timeout=300s
