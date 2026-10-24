#!/usr/bin/env bash
# PASS when the TaskRun crew-manifest-run refers to the Task crew-manifest,
# passes crew=[bridge, scout, shuttle] and deck=engineering, ran the steps
# collect, measure and report in that order, and succeeded.
set -uo pipefail

NS="starfleet"
TR="crew-manifest-run"

if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."
  exit 1
fi
task_ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.taskRef.name}')"
if [ "$task_ref" != "crew-manifest" ]; then
  echo "FAIL: TaskRun $TR must use taskRef name crew-manifest (found '${task_ref:-an embedded taskSpec}')."
  exit 1
fi
crew="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.params[?(@.name=="crew")].value}')"
deck="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.params[?(@.name=="deck")].value}')"
if [ "$crew" != '["bridge","scout","shuttle"]' ] || [ "$deck" != "engineering" ]; then
  echo "FAIL: TaskRun $TR must pass crew=[bridge, scout, shuttle] and deck=engineering (found crew='$crew', deck='$deck')."
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
steps="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.steps[*].name}')"
if [ "$steps" != "collect measure report" ]; then
  echo "FAIL: TaskRun $TR must run the steps 'collect measure report' in that order (found '$steps')."
  exit 1
fi

echo "PASS: TaskRun $TR uses crew-manifest with the expected parameters, ran its three steps and succeeded."
exit 0
