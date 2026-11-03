#!/usr/bin/env bash
# PASS when the TaskRun status-reader-run uses taskRef status-reader,
# succeeded, and reports body = "all systems nominal" with no newline.
set -uo pipefail
NS="starfleet"
TR="status-reader-run"
if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."; exit 1
fi
ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.taskRef.name}')"
if [ "$ref" != "status-reader" ]; then
  echo "FAIL: TaskRun $TR must use taskRef status-reader (found '${ref:-an embedded taskSpec}')."; exit 1
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
body="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="body")].value}')"
if [ "$body" != "all systems nominal" ]; then
  printf 'FAIL: body=%q, expected "all systems nominal".\n' "$body"; exit 1
fi
echo "PASS: TaskRun $TR succeeded and reported body='all systems nominal'."
exit 0
