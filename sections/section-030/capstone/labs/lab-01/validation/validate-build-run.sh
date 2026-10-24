#!/usr/bin/env bash
# PASS when the TaskRun image-build-run used the Task image-build with
# IMAGE=.../starfleet/bridge-app:1.1, succeeded, every step (build, push,
# report) ended with exit code 0, BUILD_STATUS is "built and pushed" and
# IMAGE_URL equals IMAGE.
set -uo pipefail

NS="starfleet"
TR="image-build-run"
IMAGE="registry.registry.svc.cluster.local:5000/starfleet/bridge-app:1.1"

if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."
  exit 1
fi
task_ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.taskRef.name}')"
image_param="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.params[?(@.name=="IMAGE")].value}')"
if [ "$task_ref" != "image-build" ] || [ "$image_param" != "$IMAGE" ]; then
  echo "FAIL: TaskRun $TR must use taskRef image-build and IMAGE=$IMAGE (found '$task_ref', '$image_param')."
  exit 1
fi

status=""
for _ in $(seq 1 40); do
  status="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}')"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
if [ "$status" != "True" ]; then
  reason="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].reason}')"
  echo "FAIL: TaskRun $TR has Succeeded=${status:-none} (reason: ${reason:-none})."
  exit 1
fi

steps="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{range .status.steps[*]}{.name}={.terminated.exitCode} {end}')"
if [ "$steps" != "build=0 push=0 report=0 " ]; then
  echo "FAIL: every step of $TR must end with exit code 0 (found '$steps'). A step with onError: continue can fail while the run succeeds."
  exit 1
fi
build_status="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="BUILD_STATUS")].value}')"
url="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="IMAGE_URL")].value}')"
if [ "$build_status" != "built and pushed" ] || [ "$url" != "$IMAGE" ]; then
  echo "FAIL: TaskRun $TR has BUILD_STATUS='${build_status}' and IMAGE_URL='${url}', expected 'built and pushed' and '$IMAGE'."
  exit 1
fi

echo "PASS: TaskRun $TR succeeded with build, push and report at exit code 0, and BUILD_STATUS='built and pushed'."
exit 0
