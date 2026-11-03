#!/usr/bin/env bash
# PASS when nightly-report-retry uses taskRef nightly-report with flaky=true,
# has retries >= 1, a timeout between 1 second and 10 minutes, a memory limit
# for the step publish through stepSpecs, succeeded, and reports
# "nightly report attempt 1".
set -uo pipefail
NS="starfleet"
TR="nightly-report-retry"
if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."; exit 1
fi
ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.taskRef.name}')"
if [ "$ref" != "nightly-report" ]; then
  echo "FAIL: TaskRun $TR must use taskRef nightly-report (found '${ref:-an embedded taskSpec}')."; exit 1
fi
flaky="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.params[?(@.name=="flaky")].value}')"
if [ "$flaky" != "true" ]; then
  echo "FAIL: the parameter flaky must be true (found '${flaky:-none}')."; exit 1
fi
retries="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.retries}')"
if [ -z "$retries" ] || [ "$retries" -lt 1 ]; then
  echo "FAIL: spec.retries must be 1 or more (found '${retries:-none}')."; exit 1
fi
timeout="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.timeout}')"
if ! [[ "$timeout" =~ ^([0-9]+h)?([0-9]+m)?([0-9]+s)?$ ]] || [ -z "$timeout" ]; then
  echo "FAIL: cannot read spec.timeout '${timeout}'."; exit 1
fi
h="${BASH_REMATCH[1]%h}"; m="${BASH_REMATCH[2]%m}"; s="${BASH_REMATCH[3]%s}"
total=$(( ${h:-0} * 3600 + ${m:-0} * 60 + ${s:-0} ))
if [ "$total" -lt 1 ] || [ "$total" -gt 600 ]; then
  echo "FAIL: spec.timeout '$timeout' must be between 1 second and 10 minutes."; exit 1
fi
mem="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.stepSpecs[?(@.name=="publish")].computeResources.limits.memory}')"
if [ -z "$mem" ]; then
  echo "FAIL: stepSpecs must set a memory limit for the step publish."; exit 1
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
report="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="report")].value}')"
if [ "$report" != "nightly report attempt 1" ]; then
  printf 'FAIL: report=%q, expected "nightly report attempt 1".\n' "$report"; exit 1
fi
echo "PASS: $TR succeeded on attempt 1 with retries $retries, timeout $timeout and a memory limit."
exit 0
