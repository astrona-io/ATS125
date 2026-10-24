#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Fix the Task: the Secret key, the shebang and the DECK variable.
kubectl apply -f "$SCRIPT_DIR/task-crew-manifest.yaml"

# 2. Create the TaskRun again so it runs the fixed Task.
kubectl -n starfleet delete taskrun crew-manifest-run --ignore-not-found --wait=true
kubectl apply -f "$SCRIPT_DIR/taskrun-crew-manifest-run.yaml"
kubectl -n starfleet wait --for=condition=Succeeded taskrun/crew-manifest-run --timeout=300s
