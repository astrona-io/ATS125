#!/usr/bin/env bash
# PASS when the TaskRun image-tag-run in starfleet refers to the Task
# image-tag (not an embedded taskSpec), passes app=bridge, version=2.1 and
# labels as the array [team=bridge, tier=web], and succeeded.
set -uo pipefail

NS="starfleet"
TR="image-tag-run"

if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."
  exit 1
fi

task_ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.taskRef.name}')"
if [ "$task_ref" != "image-tag" ]; then
  echo "FAIL: TaskRun $TR must use taskRef name image-tag (found '${task_ref:-an embedded taskSpec}')."
  exit 1
fi

app="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.params[?(@.name=="app")].value}')"
version="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.params[?(@.name=="version")].value}')"
labels="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.params[?(@.name=="labels")].value}')"
if [ "$app" != "bridge" ] || [ "$version" != "2.1" ]; then
  echo "FAIL: TaskRun $TR must pass app=bridge and version=2.1 (found app='$app', version='$version')."
  exit 1
fi
if [ "$labels" != '["team=bridge","tier=web"]' ]; then
  echo "FAIL: TaskRun $TR must pass labels as the array [team=bridge, tier=web] (found '$labels')."
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

echo "PASS: TaskRun $TR uses the Task image-tag with an array of two labels and succeeded."
exit 0
