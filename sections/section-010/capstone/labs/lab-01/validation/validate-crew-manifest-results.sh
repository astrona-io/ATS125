#!/usr/bin/env bash
# PASS when the TaskRun crew-manifest-run reports crew-count = 3 and
# summary = "engineering: 3 crew members".
set -uo pipefail

NS="starfleet"
TR="crew-manifest-run"

count="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="crew-count")].value}' 2>/dev/null)"
summary="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="summary")].value}' 2>/dev/null)"
if [ "$count" != "3" ]; then
  echo "FAIL: TaskRun $TR has crew-count='${count}', expected '3'."
  exit 1
fi
if [ "$summary" != "engineering: 3 crew members" ]; then
  echo "FAIL: TaskRun $TR has summary='${summary}', expected 'engineering: 3 crew members'."
  exit 1
fi

echo "PASS: TaskRun $TR reports crew-count='3' and summary='engineering: 3 crew members'."
exit 0
