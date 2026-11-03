#!/usr/bin/env bash
# PASS when the Task archive-fixed exists, the TaskRun archive-fixed-run
# uses it, succeeded and reports size = 12. The Task archive stays unchanged.
set -uo pipefail
NS="starfleet"
TR="archive-fixed-run"
if ! kubectl -n "$NS" get task archive-fixed >/dev/null 2>&1; then
  echo "FAIL: Task archive-fixed does not exist in $NS."; exit 1
fi
if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."; exit 1
fi
ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.taskRef.name}')"
if [ "$ref" != "archive-fixed" ]; then
  echo "FAIL: TaskRun $TR must use taskRef archive-fixed (found '${ref:-an embedded taskSpec}')."; exit 1
fi
status=""
for _ in $(seq 1 60); do
  status="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}')"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
if [ "$status" != "True" ]; then
  echo "FAIL: TaskRun $TR has Succeeded=${status:-none}."; exit 1
fi
size="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="size")].value}')"
if [ "$size" != "12" ]; then
  printf 'FAIL: size=%q, expected "12".\n' "$size"; exit 1
fi
if ! kubectl -n "$NS" get task archive -o jsonpath='{.spec.steps[0].script}' | grep -q '/tmp/report.txt'; then
  echo "FAIL: the Task archive must stay unchanged; put the fix in archive-fixed."; exit 1
fi
echo "PASS: archive-fixed-run succeeded with size=12 and archive is unchanged."
exit 0
