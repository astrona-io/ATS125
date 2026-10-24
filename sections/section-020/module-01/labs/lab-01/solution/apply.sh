#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab starts without the TaskRun.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl -n starfleet delete taskrun crew-roster-run --ignore-not-found --wait=true
kubectl apply -f "$SCRIPT_DIR/taskrun-crew-roster-run.yaml"
kubectl -n starfleet wait --for=condition=Succeeded taskrun/crew-roster-run --timeout=300s
