#!/usr/bin/env bash
# PASS when the Task launch-log has a step compose that uses the StepAction
# compose-line with ref (no image, script or command in the step), passes
# prefix=launch, and the Task has a result named entry.
set -uo pipefail
NS="starfleet"
if ! kubectl -n "$NS" get task launch-log >/dev/null 2>&1; then
  echo "FAIL: Task launch-log does not exist in $NS."; exit 1
fi
ref="$(kubectl -n "$NS" get task launch-log -o jsonpath='{.spec.steps[?(@.name=="compose")].ref.name}')"
if [ "$ref" != "compose-line" ]; then
  echo "FAIL: the step compose must use ref name compose-line (found '${ref}')."; exit 1
fi
for field in image script command; do
  v="$(kubectl -n "$NS" get task launch-log -o jsonpath="{.spec.steps[?(@.name==\"compose\")].$field}")"
  if [ -n "$v" ]; then
    echo "FAIL: the step compose must not set $field; it comes from the StepAction."; exit 1
  fi
done
prefix="$(kubectl -n "$NS" get task launch-log -o jsonpath='{.spec.steps[?(@.name=="compose")].params[?(@.name=="prefix")].value}')"
if [ "$prefix" != "launch" ]; then
  echo "FAIL: the step compose must pass prefix=launch (found '${prefix}')."; exit 1
fi
results="$(kubectl -n "$NS" get task launch-log -o jsonpath='{.spec.results[*].name}')"
if [ "$results" != "entry" ]; then
  echo "FAIL: the Task must declare the result entry (found '${results}')."; exit 1
fi
echo "PASS: Task launch-log uses the StepAction compose-line and declares the result entry."
exit 0
