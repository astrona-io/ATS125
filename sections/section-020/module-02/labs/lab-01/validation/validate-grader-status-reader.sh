#!/usr/bin/env bash
# PASS when a grader TaskRun of status-reader with message "docking complete"
# reports body = "docking complete". A Task that types the text into the
# step fetch fails here.
set -uo pipefail
NS="starfleet"
manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT
cat > "$manifest" <<'YAML'
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: status-reader-grader-
  namespace: starfleet
  labels:
    astrona.io/grader: "true"
spec:
  taskRef:
    name: status-reader
  params:
    - name: message
      value: docking complete
YAML
name="$(kubectl create -f "$manifest" -o jsonpath='{.metadata.name}' 2>/dev/null)"
if [ -z "$name" ]; then
  echo "FAIL: the grader could not create a TaskRun of the Task status-reader."; exit 1
fi
status=""
for _ in $(seq 1 80); do
  status="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null)"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
body="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="body")].value}' 2>/dev/null)"
kubectl -n "$NS" delete taskrun "$name" --wait=false >/dev/null 2>&1 || true
if [ "$status" != "True" ]; then
  echo "FAIL: the grader TaskRun did not succeed (Succeeded=${status:-none})."; exit 1
fi
if [ "$body" != "docking complete" ]; then
  printf 'FAIL: the grader run reported body=%q, expected "docking complete".\n' "$body"; exit 1
fi
echo "PASS: a grader run reported body='docking complete'."
exit 0
