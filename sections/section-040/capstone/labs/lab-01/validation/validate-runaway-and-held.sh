#!/usr/bin/env bash
# PASS when nightly-report-runaway was cancelled (reason TaskRunCancelled)
# and nightly-report-held has no spec.status, succeeded and reports
# "nightly report attempt 0".
set -uo pipefail
NS="starfleet"
for tr in nightly-report-runaway nightly-report-held; do
  if ! kubectl -n "$NS" get taskrun "$tr" >/dev/null 2>&1; then
    echo "FAIL: TaskRun $tr does not exist in $NS (do not delete it)."; exit 1
  fi
done
reason=""
for _ in $(seq 1 40); do
  reason="$(kubectl -n "$NS" get taskrun nightly-report-runaway -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].reason}')"
  [ "$reason" = "TaskRunCancelled" ] && break
  sleep 3
done
if [ "$reason" != "TaskRunCancelled" ]; then
  echo "FAIL: nightly-report-runaway has the reason '${reason:-none}', expected TaskRunCancelled."; exit 1
fi
spec_status="$(kubectl -n "$NS" get taskrun nightly-report-held -o jsonpath='{.spec.status}')"
if [ -n "$spec_status" ]; then
  echo "FAIL: nightly-report-held still has spec.status '$spec_status'."; exit 1
fi
status=""
for _ in $(seq 1 60); do
  status="$(kubectl -n "$NS" get taskrun nightly-report-held -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}')"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
if [ "$status" != "True" ]; then
  echo "FAIL: nightly-report-held has Succeeded=${status:-none}."; exit 1
fi
report="$(kubectl -n "$NS" get taskrun nightly-report-held -o jsonpath='{.status.results[?(@.name=="report")].value}')"
if [ "$report" != "nightly report attempt 0" ]; then
  printf 'FAIL: report=%q, expected "nightly report attempt 0".\n' "$report"; exit 1
fi
echo "PASS: the runaway run was cancelled and the held run was released and succeeded."
exit 0
