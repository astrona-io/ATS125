#!/usr/bin/env bash
# PASS when a grader TaskRun of ship-card with ship {name: probe, class: scout}
# reports card=probe/scout, tags=["probe","scout"] and its own name as
# run-name. A Task with typed values or a typed run name fails here.
set -uo pipefail
NS="starfleet"
manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT
cat > "$manifest" <<'YAML'
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: ship-card-grader-
  namespace: starfleet
  labels:
    astrona.io/grader: "true"
spec:
  taskRef:
    name: ship-card
  params:
    - name: ship
      value:
        name: probe
        class: scout
YAML
name="$(kubectl create -f "$manifest" -o jsonpath='{.metadata.name}' 2>/dev/null)"
if [ -z "$name" ]; then
  echo "FAIL: the grader could not create a TaskRun of the Task ship-card."; exit 1
fi
status=""
for _ in $(seq 1 60); do
  status="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null)"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
card="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="card")].value}' 2>/dev/null)"
tags="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="tags")].value}' 2>/dev/null)"
run="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="run-name")].value}' 2>/dev/null)"
kubectl -n "$NS" delete taskrun "$name" --wait=false >/dev/null 2>&1 || true
if [ "$status" != "True" ]; then
  echo "FAIL: the grader TaskRun did not succeed (Succeeded=${status:-none})."; exit 1
fi
if [ "$card" != "probe/scout" ]; then
  printf 'FAIL: the grader run reported card=%q, expected "probe/scout".\n' "$card"; exit 1
fi
if [ "$tags" != '["probe","scout"]' ]; then
  printf 'FAIL: the grader run reported tags=%q, expected ["probe","scout"].\n' "$tags"; exit 1
fi
if [ "$run" != "$name" ]; then
  printf 'FAIL: the grader run reported run-name=%q, expected "%s".\n' "$run" "$name"; exit 1
fi
echo "PASS: a grader run reported its own card, tags and run name."
exit 0
