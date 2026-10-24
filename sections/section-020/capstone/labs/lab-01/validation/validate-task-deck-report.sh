#!/usr/bin/env bash
# PASS when the Task deck-report declares output writable and config
# read-only, and a grader TaskRun with emptyDir volumes for output and cache
# succeeds with entries = 1.
set -uo pipefail

NS="starfleet"

output_ro="$(kubectl -n "$NS" get task deck-report -o jsonpath='{.spec.workspaces[?(@.name=="output")].readOnly}' 2>/dev/null)"
config_ro="$(kubectl -n "$NS" get task deck-report -o jsonpath='{.spec.workspaces[?(@.name=="config")].readOnly}' 2>/dev/null)"
if [ "$output_ro" = "true" ]; then
  echo "FAIL: the workspace output of Task deck-report is still readOnly."
  exit 1
fi
if [ "$config_ro" != "true" ]; then
  echo "FAIL: the workspace config of Task deck-report must stay readOnly (found '${config_ro}')."
  exit 1
fi

manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT
cat > "$manifest" <<'YAML'
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: deck-report-grader-
  namespace: starfleet
  labels:
    astrona.io/grader: "true"
spec:
  taskRef:
    name: deck-report
  params:
    - name: run-date
      value: "2026-12-31"
  workspaces:
    - name: output
      emptyDir: {}
    - name: config
      configMap:
        name: report-config
    - name: cache
      emptyDir: {}
YAML

name="$(kubectl create -f "$manifest" -o jsonpath='{.metadata.name}' 2>/dev/null)"
if [ -z "$name" ]; then
  echo "FAIL: the grader could not create a TaskRun of the Task deck-report."
  exit 1
fi
status=""
for _ in $(seq 1 60); do
  status="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null)"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
entries="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="entries")].value}' 2>/dev/null)"
kubectl -n "$NS" delete taskrun "$name" --wait=false >/dev/null 2>&1 || true

if [ "$status" != "True" ] || [ "$entries" != "1" ]; then
  echo "FAIL: a grader TaskRun of deck-report with empty volumes did not succeed with entries=1 (Succeeded=${status:-none}, entries='${entries}')."
  exit 1
fi

echo "PASS: output is writable, config is read-only, and a grader run with empty volumes reports entries=1."
exit 0
