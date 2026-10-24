#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays broken for the learner.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Fix the Task: no REGISTRY override in compose, no newline in label-count.
kubectl apply -f "$SCRIPT_DIR/task-image-tag.yaml"

# 2. A started TaskRun cannot be changed: delete it and create it again with
#    labels as an array.
kubectl -n starfleet delete taskrun image-tag-run --ignore-not-found --wait=true
kubectl apply -f "$SCRIPT_DIR/taskrun-image-tag-run.yaml"
kubectl -n starfleet wait --for=condition=Succeeded taskrun/image-tag-run --timeout=300s
