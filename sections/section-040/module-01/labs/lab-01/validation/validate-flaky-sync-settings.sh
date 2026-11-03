#!/usr/bin/env bash
# PASS when flaky-sync-run sets a timeout that is not unlimited and not
# longer than 10 minutes, and reports the result attempt = 2.
set -uo pipefail
NS="starfleet"
TR="flaky-sync-run"
if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."; exit 1
fi
timeout="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.timeout}')"
if [ -z "$timeout" ]; then
  echo "FAIL: spec.timeout is not set."; exit 1
fi
if ! [[ "$timeout" =~ ^([0-9]+h)?([0-9]+m)?([0-9]+s)?$ ]]; then
  echo "FAIL: cannot read spec.timeout '$timeout'."; exit 1
fi
h="${BASH_REMATCH[1]%h}"; m="${BASH_REMATCH[2]%m}"; s="${BASH_REMATCH[3]%s}"
total=$(( ${h:-0} * 3600 + ${m:-0} * 60 + ${s:-0} ))
if [ "$total" -eq 0 ]; then
  echo "FAIL: spec.timeout '$timeout' means no limit."; exit 1
fi
if [ "$total" -gt 600 ]; then
  echo "FAIL: spec.timeout '$timeout' is longer than 10 minutes."; exit 1
fi
attempt="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="attempt")].value}')"
if [ "$attempt" != "2" ]; then
  printf 'FAIL: result attempt=%q, expected "2".\n' "$attempt"; exit 1
fi
echo "PASS: timeout is $timeout and the final attempt reported attempt=2."
exit 0
