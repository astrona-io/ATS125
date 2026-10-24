#!/usr/bin/env bash
# PASS when the TaskRun image-tag-run reports exactly
# image-ref = registry.registry.svc.cluster.local:5000/starfleet/bridge:2.1 and
# label-count = 2 (no newline, no other characters).
set -uo pipefail

NS="starfleet"
TR="image-tag-run"
EXPECTED_REF="registry.registry.svc.cluster.local:5000/starfleet/bridge:2.1"
EXPECTED_COUNT="2"

ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="image-ref")].value}' 2>/dev/null)"
count="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="label-count")].value}' 2>/dev/null)"

if [ "$ref" != "$EXPECTED_REF" ]; then
  echo "FAIL: TaskRun $TR has image-ref='${ref}', expected '$EXPECTED_REF'."
  exit 1
fi
if [ "$count" != "$EXPECTED_COUNT" ]; then
  printf 'FAIL: TaskRun %s has label-count=%q, expected %q (check for a trailing newline).\n' "$TR" "$count" "$EXPECTED_COUNT"
  exit 1
fi

echo "PASS: TaskRun $TR reports image-ref='$EXPECTED_REF' and label-count='$EXPECTED_COUNT'."
exit 0
