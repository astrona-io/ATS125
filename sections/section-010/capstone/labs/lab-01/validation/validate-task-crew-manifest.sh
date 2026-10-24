#!/usr/bin/env bash
# PASS when:
# - the Secret report-token still has only the key api-token (the fix belongs
#   in the Task, not in the Secret);
# - the Task crew-manifest still fetches crew-count from the step result
#   lines of measure;
# - a grader TaskRun with crew=[probe, scout] and deck=hangar reports
#   crew-count = 2 and summary = "hangar: 2 crew members".
set -uo pipefail

NS="starfleet"

secret_keys="$(kubectl -n "$NS" get secret report-token -o go-template='{{range $key, $value := .data}}{{$key}} {{end}}' 2>/dev/null)"
if [ "$secret_keys" != "api-token " ]; then
  echo "FAIL: the Secret report-token must keep exactly the key api-token (found keys '${secret_keys}'). Fix the Task instead."
  exit 1
fi
count_value="$(kubectl -n "$NS" get task crew-manifest -o jsonpath='{.spec.results[?(@.name=="crew-count")].value}' 2>/dev/null)"
if [ "$count_value" != '$(steps.measure.results.lines)' ]; then
  echo "FAIL: the result crew-count of Task crew-manifest must keep value \$(steps.measure.results.lines) (found '${count_value}')."
  exit 1
fi
steps="$(kubectl -n "$NS" get task crew-manifest -o jsonpath='{.spec.steps[*].name}' 2>/dev/null)"
if [ "$steps" != "collect measure report" ]; then
  echo "FAIL: Task crew-manifest must keep the steps 'collect measure report' (found '${steps}')."
  exit 1
fi

manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT
cat > "$manifest" <<'YAML'
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: crew-manifest-grader-
  namespace: starfleet
  labels:
    astrona.io/grader: "true"
spec:
  taskRef:
    name: crew-manifest
  params:
    - name: crew
      value:
        - probe
        - scout
    - name: deck
      value: hangar
YAML

name="$(kubectl create -f "$manifest" -o jsonpath='{.metadata.name}' 2>/dev/null)"
if [ -z "$name" ]; then
  echo "FAIL: the grader could not create a TaskRun of the Task crew-manifest."
  exit 1
fi
status=""
for _ in $(seq 1 60); do
  status="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null)"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
count="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="crew-count")].value}' 2>/dev/null)"
summary="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="summary")].value}' 2>/dev/null)"
kubectl -n "$NS" delete taskrun "$name" --wait=false >/dev/null 2>&1 || true

if [ "$status" != "True" ]; then
  echo "FAIL: a grader TaskRun of crew-manifest (crew=[probe, scout], deck=hangar) did not succeed (Succeeded=${status:-none})."
  exit 1
fi
if [ "$count" != "2" ] || [ "$summary" != "hangar: 2 crew members" ]; then
  echo "FAIL: a grader TaskRun reported crew-count='${count}' and summary='${summary}', expected '2' and 'hangar: 2 crew members'."
  exit 1
fi

echo "PASS: the Secret is unchanged and a grader run reports 'hangar: 2 crew members' with crew-count 2."
exit 0
