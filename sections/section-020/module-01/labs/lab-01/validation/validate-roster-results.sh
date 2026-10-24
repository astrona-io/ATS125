#!/usr/bin/env bash
# PASS when crew-roster-run reports roster = "bridge: 3 crew members" and
# signed = "true", and the Task still declares settings read-only and token
# optional.
set -uo pipefail

NS="starfleet"
TR="crew-roster-run"

roster="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="roster")].value}' 2>/dev/null)"
signed="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="signed")].value}' 2>/dev/null)"
if [ "$roster" != "bridge: 3 crew members" ]; then
  echo "FAIL: TaskRun $TR has roster='${roster}', expected 'bridge: 3 crew members'."
  exit 1
fi
if [ "$signed" != "true" ]; then
  echo "FAIL: TaskRun $TR has signed='${signed}', expected 'true'. Bind the token workspace."
  exit 1
fi

settings_ro="$(kubectl -n "$NS" get task crew-roster -o jsonpath='{.spec.workspaces[?(@.name=="settings")].readOnly}' 2>/dev/null)"
token_optional="$(kubectl -n "$NS" get task crew-roster -o jsonpath='{.spec.workspaces[?(@.name=="token")].optional}' 2>/dev/null)"
if [ "$settings_ro" != "true" ] || [ "$token_optional" != "true" ]; then
  echo "FAIL: do not change the Task: settings must stay readOnly and token optional (found readOnly='$settings_ro', optional='$token_optional')."
  exit 1
fi

echo "PASS: TaskRun $TR reports 'bridge: 3 crew members' and signed='true'."
exit 0
