#!/usr/bin/env bash
# PASS when the Task image-tag keeps REGISTRY in its stepTemplate only, and a
# grader TaskRun with app=probe, no version and three labels reports
# image-ref = registry.registry.svc.cluster.local:5000/starfleet/probe:1.0 and
# label-count = 3. A Task that types the values into the script fails here.
set -uo pipefail

NS="starfleet"

template_registry="$(kubectl -n "$NS" get task image-tag -o jsonpath='{.spec.stepTemplate.env[?(@.name=="REGISTRY")].value}' 2>/dev/null)"
if [ "$template_registry" != "registry.registry.svc.cluster.local:5000" ]; then
  echo "FAIL: the stepTemplate of Task image-tag must keep REGISTRY=registry.registry.svc.cluster.local:5000 (found '${template_registry}')."
  exit 1
fi
step_env_names="$(kubectl -n "$NS" get task image-tag -o jsonpath='{.spec.steps[*].env[*].name}' 2>/dev/null)"
for env_name in $step_env_names; do
  if [ "$env_name" = "REGISTRY" ]; then
    echo "FAIL: a step of Task image-tag still sets its own REGISTRY variable; it must come from the stepTemplate."
    exit 1
  fi
done
steps="$(kubectl -n "$NS" get task image-tag -o jsonpath='{.spec.steps[*].name}' 2>/dev/null)"
if [ "$steps" != "compose count-labels" ]; then
  echo "FAIL: Task image-tag must keep the two steps 'compose count-labels' (found '${steps}')."
  exit 1
fi

manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT
cat > "$manifest" <<'YAML'
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: image-tag-grader-
  namespace: starfleet
  labels:
    astrona.io/grader: "true"
spec:
  taskRef:
    name: image-tag
  params:
    - name: app
      value: probe
    - name: labels
      value:
        - team=probe
        - tier=batch
        - zone=outpost
YAML

name="$(kubectl create -f "$manifest" -o jsonpath='{.metadata.name}' 2>/dev/null)"
if [ -z "$name" ]; then
  echo "FAIL: the grader could not create a TaskRun of the Task image-tag."
  exit 1
fi

status=""
for _ in $(seq 1 60); do
  status="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null)"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
ref="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="image-ref")].value}' 2>/dev/null)"
count="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="label-count")].value}' 2>/dev/null)"
kubectl -n "$NS" delete taskrun "$name" --wait=false >/dev/null 2>&1 || true

if [ "$status" != "True" ]; then
  echo "FAIL: a grader TaskRun of image-tag (app=probe, three labels) did not succeed (Succeeded=${status:-none})."
  exit 1
fi
if [ "$ref" != "registry.registry.svc.cluster.local:5000/starfleet/probe:1.0" ]; then
  echo "FAIL: a grader TaskRun reported image-ref='${ref}', expected 'registry.registry.svc.cluster.local:5000/starfleet/probe:1.0'."
  exit 1
fi
if [ "$count" != "3" ]; then
  printf 'FAIL: a grader TaskRun with three labels reported label-count=%q, expected "3".\n' "$count"
  exit 1
fi

echo "PASS: REGISTRY comes from the stepTemplate; a grader run reports probe:1.0 and label-count 3."
exit 0
