#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Fix the Task: vfs storage driver, no TLS verification for the lab
#    registry, and a report step that fails the run when a step failed.
kubectl apply -f "$SCRIPT_DIR/task-image-build.yaml"

# 2. Create the TaskRun again so it runs the fixed Task.
kubectl -n starfleet delete taskrun image-build-run --ignore-not-found --wait=true
kubectl apply -f "$SCRIPT_DIR/taskrun-image-build-run.yaml"
kubectl -n starfleet wait --for=condition=Succeeded taskrun/image-build-run --timeout=600s
