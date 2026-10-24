#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab starts without the Task.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$SCRIPT_DIR/task-image-build.yaml"
kubectl -n starfleet delete taskrun image-build-run --ignore-not-found --wait=true
kubectl apply -f "$SCRIPT_DIR/taskrun-image-build-run.yaml"
kubectl -n starfleet wait --for=condition=Succeeded taskrun/image-build-run --timeout=600s
