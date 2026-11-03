#!/usr/bin/env bash
# PASS when the ConfigMap nightly-diagnosis has the key reason with the
# reason of the Succeeded condition of nightly-report-timeout.
set -uo pipefail
NS="starfleet"
if ! kubectl -n "$NS" get configmap nightly-diagnosis >/dev/null 2>&1; then
  echo "FAIL: ConfigMap nightly-diagnosis does not exist in $NS."; exit 1
fi
want="$(kubectl -n "$NS" get taskrun nightly-report-timeout -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].reason}')"
got="$(kubectl -n "$NS" get configmap nightly-diagnosis -o jsonpath='{.data.reason}')"
if [ -z "$want" ] || [ "$got" != "$want" ]; then
  printf 'FAIL: reason=%q does not match the reason of nightly-report-timeout.\n' "$got"; exit 1
fi
echo "PASS: nightly-diagnosis holds the reason of nightly-report-timeout."
exit 0
