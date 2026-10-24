#!/usr/bin/env bash
# PASS when reports/history.txt in report-data still starts with the two
# earlier lines, holds the line "2026-10-15 engineering: ok", and has as many
# lines as the result entries of deck-report-run says (at least 3).
# A grader TaskRun reads the file through a read-only workspace.
set -uo pipefail

NS="starfleet"

entries="$(kubectl -n "$NS" get taskrun deck-report-run -o jsonpath='{.status.results[?(@.name=="entries")].value}' 2>/dev/null)"

manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT
cat > "$manifest" <<'YAML'
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: report-history-grader-
  namespace: starfleet
  labels:
    astrona.io/grader: "true"
spec:
  workspaces:
    - name: data
      persistentVolumeClaim:
        claimName: report-data
      subPath: reports
  taskSpec:
    workspaces:
      - name: data
        readOnly: true
    results:
      - name: head
      - name: lines
      - name: has-new-line
    steps:
      - name: read
        image: busybox:1.37.0
        script: |
          #!/bin/sh
          set -eu
          history="$(workspaces.data.path)/history.txt"
          head -n 2 "$history" | tr '\n' '|' > "$(results.head.path)"
          printf '%s' "$(grep -c . "$history")" > "$(results.lines.path)"
          if grep -qx '2026-10-15 engineering: ok' "$history"; then
            printf 'yes' > "$(results.has-new-line.path)"
          else
            printf 'no' > "$(results.has-new-line.path)"
          fi
YAML

name="$(kubectl create -f "$manifest" -o jsonpath='{.metadata.name}' 2>/dev/null)"
if [ -z "$name" ]; then
  echo "FAIL: the grader could not create its TaskRun to read report-data."
  exit 1
fi
status=""
for _ in $(seq 1 60); do
  status="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null)"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
head_lines="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="head")].value}' 2>/dev/null)"
lines="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="lines")].value}' 2>/dev/null)"
has_new_line="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="has-new-line")].value}' 2>/dev/null)"
kubectl -n "$NS" delete taskrun "$name" --wait=false >/dev/null 2>&1 || true

if [ "$status" != "True" ]; then
  echo "FAIL: reports/history.txt could not be read from report-data (grader run Succeeded=${status:-none})."
  exit 1
fi
if [ "$head_lines" != "2026-10-01 bridge: ok|2026-10-08 scout: ok|" ]; then
  echo "FAIL: reports/history.txt must still start with the two earlier lines (found '${head_lines}')."
  exit 1
fi
if [ "$has_new_line" != "yes" ]; then
  echo "FAIL: reports/history.txt has no line '2026-10-15 engineering: ok'."
  exit 1
fi
if [ -z "$lines" ] || [ "$lines" -lt 3 ] || [ "$entries" != "$lines" ]; then
  echo "FAIL: deck-report-run reports entries='${entries}', but reports/history.txt has ${lines:-0} lines (at least 3 expected, and both must match)."
  exit 1
fi

echo "PASS: reports/history.txt keeps the old lines, has the new line, and has $lines lines like the result entries."
exit 0
