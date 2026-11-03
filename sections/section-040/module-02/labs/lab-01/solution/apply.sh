#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEP="$(kubectl -n starfleet get taskrun archive-run -o jsonpath='{range .status.steps[*]}{.name}{" "}{.terminated.exitCode}{"\n"}{end}' | awk '$2 != "" && $2 != 0 {print $1; exit}')"
CODE="$(kubectl -n starfleet get taskrun archive-run -o jsonpath='{range .status.steps[*]}{.name}{" "}{.terminated.exitCode}{"\n"}{end}' | awk '$2 != "" && $2 != 0 {print $2; exit}')"
kubectl -n starfleet create configmap archive-diagnosis --from-literal=failedStep="$STEP" --from-literal=exitCode="$CODE"
kubectl apply -f "$SCRIPT_DIR/task-archive-fixed.yaml"
kubectl apply -f "$SCRIPT_DIR/taskrun-archive-fixed-run.yaml"
kubectl -n starfleet wait --for=condition=Succeeded taskrun/archive-fixed-run --timeout=300s
