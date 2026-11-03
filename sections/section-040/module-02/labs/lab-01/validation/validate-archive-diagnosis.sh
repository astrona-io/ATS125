#!/usr/bin/env bash
# PASS when the ConfigMap archive-diagnosis has failedStep and exitCode
# that match the failed step of the TaskRun archive-run.
set -uo pipefail
NS="starfleet"
if ! kubectl -n "$NS" get configmap archive-diagnosis >/dev/null 2>&1; then
  echo "FAIL: ConfigMap archive-diagnosis does not exist in $NS."; exit 1
fi
want_step="$(kubectl -n "$NS" get taskrun archive-run -o jsonpath='{range .status.steps[*]}{.name}{" "}{.terminated.exitCode}{"\n"}{end}' | awk '$2 != "" && $2 != 0 {print $1; exit}')"
want_code="$(kubectl -n "$NS" get taskrun archive-run -o jsonpath='{range .status.steps[*]}{.name}{" "}{.terminated.exitCode}{"\n"}{end}' | awk '$2 != "" && $2 != 0 {print $2; exit}')"
if [ -z "$want_step" ]; then
  echo "FAIL: the grader cannot find the failed step of archive-run."; exit 1
fi
step="$(kubectl -n "$NS" get configmap archive-diagnosis -o jsonpath='{.data.failedStep}')"
code="$(kubectl -n "$NS" get configmap archive-diagnosis -o jsonpath='{.data.exitCode}')"
if [ "$step" != "$want_step" ]; then
  printf 'FAIL: failedStep=%q, expected the step that failed in archive-run.\n' "$step"; exit 1
fi
if [ "$code" != "$want_code" ]; then
  printf 'FAIL: exitCode=%q, expected the exit code of that step.\n' "$code"; exit 1
fi
echo "PASS: archive-diagnosis names the failed step and its exit code."
exit 0
