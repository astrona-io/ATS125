#!/usr/bin/env bash
# PASS when the TaskRun flaky-sync-run uses taskRef flaky-sync, has
# retries of 2 or more, succeeded, and recorded two failed attempts.
set -uo pipefail
NS="starfleet"
TR="flaky-sync-run"
if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."; exit 1
fi
ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.taskRef.name}')"
if [ "$ref" != "flaky-sync" ]; then
  echo "FAIL: TaskRun $TR must use taskRef flaky-sync (found '${ref:-an embedded taskSpec}')."; exit 1
fi
retries="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.retries}')"
if [ -z "$retries" ] || [ "$retries" -lt 2 ]; then
  echo "FAIL: spec.retries must be 2 or more (found '${retries:-none}')."; exit 1
fi
status=""
for _ in $(seq 1 90); do
  status="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}')"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
if [ "$status" != "True" ]; then
  echo "FAIL: TaskRun $TR has Succeeded=${status:-none}."; exit 1
fi
failed="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.retriesStatus[*].conditions[0].status}')"
count=0
for s in $failed; do [ "$s" = "False" ] && count=$((count + 1)); done
if [ "$count" -ne 2 ]; then
  echo "FAIL: expected 2 failed attempts in status.retriesStatus (found $count)."; exit 1
fi
echo "PASS: TaskRun $TR used flaky-sync, succeeded after $count failed attempts."
exit 0
