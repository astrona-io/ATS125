#!/usr/bin/env bash
# PASS when the steps build and push keep onError: continue, and a grader
# TaskRun whose Dockerfile does not exist ends with Succeeded=False and the
# reason StepFailed, with build ending "Continued" and report running and
# ending with a non-zero exit code. A report step that always exits 0, or a
# Task without onError: continue, fails here.
set -uo pipefail

NS="starfleet"

build_on_error="$(kubectl -n "$NS" get task image-build -o jsonpath='{.spec.steps[?(@.name=="build")].onError}' 2>/dev/null)"
push_on_error="$(kubectl -n "$NS" get task image-build -o jsonpath='{.spec.steps[?(@.name=="push")].onError}' 2>/dev/null)"
steps="$(kubectl -n "$NS" get task image-build -o jsonpath='{.spec.steps[*].name}' 2>/dev/null)"
if [ "$steps" != "build push report" ]; then
  echo "FAIL: Task image-build must keep the steps 'build push report' (found '${steps}')."
  exit 1
fi
if [ "$build_on_error" != "continue" ] || [ "$push_on_error" != "continue" ]; then
  echo "FAIL: the steps build and push must keep onError: continue so that report always runs (found '$build_on_error', '$push_on_error')."
  exit 1
fi

manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT
cat > "$manifest" <<'YAML'
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: image-build-fail-grader-
  namespace: starfleet
  labels:
    astrona.io/grader: "true"
spec:
  taskRef:
    name: image-build
  params:
    - name: IMAGE
      value: registry.registry.svc.cluster.local:5000/starfleet/grader-app:never
    - name: CONTEXT
      value: bridge-app
    - name: DOCKERFILE
      value: Missing.Dockerfile
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: bridge-source
YAML

name="$(kubectl create -f "$manifest" -o jsonpath='{.metadata.name}' 2>/dev/null)"
if [ -z "$name" ]; then
  echo "FAIL: the grader could not create a TaskRun of the Task image-build."
  exit 1
fi
status=""
for _ in $(seq 1 60); do
  status="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null)"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
reason="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].reason}' 2>/dev/null)"
build_reason="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.steps[?(@.name=="build")].terminationReason}' 2>/dev/null)"
report_reason="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.steps[?(@.name=="report")].terminationReason}' 2>/dev/null)"
report_code="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.steps[?(@.name=="report")].terminated.exitCode}' 2>/dev/null)"
kubectl -n "$NS" delete taskrun "$name" --wait=false >/dev/null 2>&1 || true

if [ "$status" != "False" ] || [ "$reason" != "StepFailed" ]; then
  echo "FAIL: a grader TaskRun with a missing Dockerfile ended with Succeeded=${status:-none} (reason ${reason:-none}); it must fail with StepFailed."
  exit 1
fi
if [ "$build_reason" != "Continued" ]; then
  echo "FAIL: in the grader run the step build ended with terminationReason '${build_reason}', expected 'Continued'."
  exit 1
fi
if [ "$report_reason" = "Skipped" ] || [ -z "$report_code" ] || [ "$report_code" = "0" ]; then
  echo "FAIL: in the grader run the step report must run and end with a non-zero exit code (terminationReason '${report_reason}', exit code '${report_code}')."
  exit 1
fi

echo "PASS: a failed build lets report run, and report fails the TaskRun with StepFailed."
exit 0
