#!/usr/bin/env bash
# Reference solution, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REASON="$(kubectl -n starfleet get taskrun nightly-report-timeout -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].reason}')"
kubectl -n starfleet create configmap nightly-diagnosis --from-literal=reason="$REASON"
kubectl -n starfleet patch taskrun nightly-report-runaway --type merge -p '{"spec":{"status":"TaskRunCancelled"}}'
kubectl -n starfleet patch taskrun nightly-report-held --type json -p '[{"op":"remove","path":"/spec/status"}]'
kubectl apply -f "$SCRIPT_DIR/taskrun-nightly-report-retry.yaml"
kubectl -n starfleet wait --for=condition=Succeeded taskrun/nightly-report-held --timeout=300s
kubectl -n starfleet wait --for=condition=Succeeded taskrun/nightly-report-retry --timeout=300s
