#!/usr/bin/env bash
# PASS when the TaskRun crew-roster-run refers to the Task crew-roster, binds
# source to the PersistentVolumeClaim roster-data with subPath bridge,
# settings to the ConfigMap roster-settings and token to the Secret
# roster-token, and succeeded.
set -uo pipefail

NS="starfleet"
TR="crew-roster-run"

if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."
  exit 1
fi
task_ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.taskRef.name}')"
if [ "$task_ref" != "crew-roster" ]; then
  echo "FAIL: TaskRun $TR must use taskRef name crew-roster (found '${task_ref:-an embedded taskSpec}')."
  exit 1
fi

source_claim="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.workspaces[?(@.name=="source")].persistentVolumeClaim.claimName}')"
source_subpath="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.workspaces[?(@.name=="source")].subPath}')"
settings_cm="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.workspaces[?(@.name=="settings")].configMap.name}')"
token_secret="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.workspaces[?(@.name=="token")].secret.secretName}')"
if [ "$source_claim" != "roster-data" ] || [ "$source_subpath" != "bridge" ]; then
  echo "FAIL: workspace source must bind persistentVolumeClaim roster-data with subPath bridge (found claim='$source_claim', subPath='$source_subpath')."
  exit 1
fi
if [ "$settings_cm" != "roster-settings" ]; then
  echo "FAIL: workspace settings must bind the ConfigMap roster-settings (found '${settings_cm}')."
  exit 1
fi
if [ "$token_secret" != "roster-token" ]; then
  echo "FAIL: workspace token must bind the Secret roster-token (found '${token_secret}')."
  exit 1
fi

status=""
for _ in $(seq 1 20); do
  status="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}')"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
if [ "$status" != "True" ]; then
  reason="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].reason}')"
  echo "FAIL: TaskRun $TR has Succeeded=${status:-none} (reason: ${reason:-none})."
  exit 1
fi

echo "PASS: TaskRun $TR binds the PVC (subPath bridge), the ConfigMap and the Secret, and succeeded."
exit 0
