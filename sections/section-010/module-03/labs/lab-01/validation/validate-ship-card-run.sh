#!/usr/bin/env bash
# PASS when the TaskRun ship-card-run uses taskRef ship-card, passes the
# object ship {name: bridge, class: flagship}, succeeded, and reports
# card=bridge/flagship, tags=["bridge","flagship"], run-name=ship-card-run.
set -uo pipefail
NS="starfleet"
TR="ship-card-run"
if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."; exit 1
fi
ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.taskRef.name}')"
if [ "$ref" != "ship-card" ]; then
  echo "FAIL: TaskRun $TR must use taskRef ship-card (found '${ref:-an embedded taskSpec}')."; exit 1
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
card="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="card")].value}')"
tags="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="tags")].value}')"
run="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="run-name")].value}')"
if [ "$card" != "bridge/flagship" ]; then
  printf 'FAIL: card=%q, expected "bridge/flagship".\n' "$card"; exit 1
fi
if [ "$tags" != '["bridge","flagship"]' ]; then
  printf 'FAIL: tags=%q, expected ["bridge","flagship"].\n' "$tags"; exit 1
fi
if [ "$run" != "ship-card-run" ]; then
  printf 'FAIL: run-name=%q, expected "ship-card-run".\n' "$run"; exit 1
fi
echo "PASS: TaskRun $TR succeeded with the expected card, tags and run-name."
exit 0
