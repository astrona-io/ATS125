#!/usr/bin/env bash
# PASS when the TaskRun launch-log-run uses taskRef launch-log, passes the
# message "engines online", succeeded and reports entry exactly as
# "launch: engines online".
set -uo pipefail
NS="starfleet"
TR="launch-log-run"
if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."; exit 1
fi
ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.taskRef.name}')"
if [ "$ref" != "launch-log" ]; then
  echo "FAIL: TaskRun $TR must use taskRef launch-log (found '${ref:-an embedded taskSpec}')."; exit 1
fi
msg="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.params[?(@.name=="message")].value}')"
if [ "$msg" != "engines online" ]; then
  echo "FAIL: TaskRun $TR must pass message='engines online' (found '${msg}')."; exit 1
fi
status=""
for _ in $(seq 1 30); do
  status="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}')"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
if [ "$status" != "True" ]; then
  echo "FAIL: TaskRun $TR has Succeeded=${status:-none}."; exit 1
fi
entry="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="entry")].value}')"
if [ "$entry" != "launch: engines online" ]; then
  printf 'FAIL: TaskRun %s reported entry=%q, expected "launch: engines online".\n' "$TR" "$entry"; exit 1
fi
echo "PASS: TaskRun $TR succeeded and reported entry='launch: engines online'."
exit 0
