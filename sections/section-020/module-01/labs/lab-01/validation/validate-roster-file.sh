#!/usr/bin/env bash
# PASS when the roster file was written into the PersistentVolumeClaim:
# a grader TaskRun mounts roster-data with subPath bridge, read-only, and
# reads roster.txt (first line "deck: bridge", four lines in all) and
# roster.sig (a sha256 value).
set -uo pipefail

NS="starfleet"

manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT
cat > "$manifest" <<'YAML'
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: roster-file-grader-
  namespace: starfleet
  labels:
    astrona.io/grader: "true"
spec:
  workspaces:
    - name: data
      persistentVolumeClaim:
        claimName: roster-data
      subPath: bridge
  taskSpec:
    workspaces:
      - name: data
        readOnly: true
    results:
      - name: first-line
      - name: lines
      - name: signature
    steps:
      - name: read
        image: busybox:1.37.0
        script: |
          #!/bin/sh
          set -eu
          head -n 1 "$(workspaces.data.path)/roster.txt" | tr -d '\n' > "$(results.first-line.path)"
          printf '%s' "$(grep -c . "$(workspaces.data.path)/roster.txt")" > "$(results.lines.path)"
          tr -d '\n' < "$(workspaces.data.path)/roster.sig" > "$(results.signature.path)"
YAML

name="$(kubectl create -f "$manifest" -o jsonpath='{.metadata.name}' 2>/dev/null)"
if [ -z "$name" ]; then
  echo "FAIL: the grader could not create its TaskRun to read the PersistentVolumeClaim roster-data."
  exit 1
fi
status=""
for _ in $(seq 1 60); do
  status="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null)"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
first_line="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="first-line")].value}' 2>/dev/null)"
lines="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="lines")].value}' 2>/dev/null)"
signature="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="signature")].value}' 2>/dev/null)"
kubectl -n "$NS" delete taskrun "$name" --wait=false >/dev/null 2>&1 || true

if [ "$status" != "True" ]; then
  echo "FAIL: bridge/roster.txt or bridge/roster.sig is missing from the PersistentVolumeClaim roster-data (grader run Succeeded=${status:-none})."
  exit 1
fi
if [ "$first_line" != "deck: bridge" ] || [ "$lines" != "4" ]; then
  echo "FAIL: bridge/roster.txt has first line '${first_line}' and ${lines:-0} lines, expected 'deck: bridge' and 4 lines."
  exit 1
fi
if [ "${#signature}" -ne 64 ]; then
  echo "FAIL: bridge/roster.sig does not hold a sha256 value (found '${signature}')."
  exit 1
fi

echo "PASS: bridge/roster.txt and bridge/roster.sig are in the PersistentVolumeClaim roster-data."
exit 0
