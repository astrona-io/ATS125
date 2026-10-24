#!/usr/bin/env bash
# PASS when the TaskRun deck-report-run refers to the Task deck-report, passes
# run-date=2026-10-15, binds output to report-data with subPath reports, binds
# no other PersistentVolumeClaim, and succeeded.
set -uo pipefail

NS="starfleet"
TR="deck-report-run"

if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."
  exit 1
fi
task_ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.taskRef.name}')"
run_date="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.params[?(@.name=="run-date")].value}')"
if [ "$task_ref" != "deck-report" ] || [ "$run_date" != "2026-10-15" ]; then
  echo "FAIL: TaskRun $TR must use taskRef deck-report and run-date=2026-10-15 (found taskRef='${task_ref:-none}', run-date='$run_date')."
  exit 1
fi

output_claim="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.workspaces[?(@.name=="output")].persistentVolumeClaim.claimName}')"
output_subpath="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.workspaces[?(@.name=="output")].subPath}')"
if [ "$output_claim" != "report-data" ] || [ "$output_subpath" != "reports" ]; then
  echo "FAIL: workspace output must bind report-data with subPath reports (found claim='$output_claim', subPath='$output_subpath')."
  exit 1
fi
claims="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.workspaces[*].persistentVolumeClaim.claimName}')"
for claim in $claims; do
  if [ "$claim" != "report-data" ]; then
    echo "FAIL: TaskRun $TR must bind no PersistentVolumeClaim other than report-data (found '$claim')."
    exit 1
  fi
done
templates="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.workspaces[*].volumeClaimTemplate}')"
if [ -n "$templates" ]; then
  echo "FAIL: TaskRun $TR must not create a new PersistentVolumeClaim with volumeClaimTemplate."
  exit 1
fi

status=""
for _ in $(seq 1 20); do
  status="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}')"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
if [ "$status" != "True" ]; then
  reason="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].reason}')"
  echo "FAIL: TaskRun $TR has Succeeded=${status:-none} (reason: ${reason:-none})."
  exit 1
fi

echo "PASS: TaskRun $TR binds report-data (subPath reports) as its only PVC and succeeded."
exit 0
