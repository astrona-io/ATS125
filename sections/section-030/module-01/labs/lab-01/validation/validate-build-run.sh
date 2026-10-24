#!/usr/bin/env bash
# PASS when the TaskRun image-build-run used the Task image-build with the
# PersistentVolumeClaim bridge-source, succeeded, reports IMAGE_URL equal to
# its IMAGE parameter, and the registry holds starfleet/bridge-app:1.0 with
# the same manifest digest as the result IMAGE_DIGEST.
set -uo pipefail

NS="starfleet"
TR="image-build-run"
IMAGE="registry.registry.svc.cluster.local:5000/starfleet/bridge-app:1.0"
REGISTRY_URL="http://registry.registry.svc.cluster.local:5000"

registry_digest() {
  # registry_digest REPOSITORY TAG: the Docker-Content-Digest of a manifest,
  # read from inside the cluster through the client pod.
  kubectl -n registry exec deploy/client -- curl -s -I \
    -H 'Accept: application/vnd.oci.image.manifest.v1+json' \
    -H 'Accept: application/vnd.oci.image.index.v1+json' \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
    "$REGISTRY_URL/v2/$1/manifests/$2" 2>/dev/null \
    | tr -d '\r' | awk -F': ' 'tolower($1)=="docker-content-digest" {print $2}'
}

if ! kubectl -n "$NS" get taskrun "$TR" >/dev/null 2>&1; then
  echo "FAIL: TaskRun $TR does not exist in $NS."
  exit 1
fi
task_ref="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.taskRef.name}')"
image_param="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.params[?(@.name=="IMAGE")].value}')"
claim="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.spec.workspaces[?(@.name=="source")].persistentVolumeClaim.claimName}')"
if [ "$task_ref" != "image-build" ] || [ "$image_param" != "$IMAGE" ] || [ "$claim" != "bridge-source" ]; then
  echo "FAIL: TaskRun $TR must use taskRef image-build, IMAGE=$IMAGE and the PVC bridge-source (found '$task_ref', '$image_param', '$claim')."
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

url="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="IMAGE_URL")].value}')"
digest="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="IMAGE_DIGEST")].value}')"
if [ "$url" != "$IMAGE" ]; then
  echo "FAIL: TaskRun $TR has IMAGE_URL='${url}', expected '$IMAGE'."
  exit 1
fi
case "$digest" in
  sha256:????????????????????????????????????????????????????????????????) ;;
  *) echo "FAIL: TaskRun $TR has IMAGE_DIGEST='${digest}', expected sha256: followed by 64 characters."; exit 1 ;;
esac

tags="$(kubectl -n registry exec deploy/client -- curl -s "$REGISTRY_URL/v2/starfleet/bridge-app/tags/list" 2>/dev/null)"
case "$tags" in
  *'"1.0"'*) ;;
  *) echo "FAIL: the registry has no tag 1.0 for starfleet/bridge-app (tags/list: '${tags}')."; exit 1 ;;
esac
pushed="$(registry_digest starfleet/bridge-app 1.0)"
if [ "$pushed" != "$digest" ]; then
  echo "FAIL: the registry serves starfleet/bridge-app:1.0 with digest '${pushed}', but IMAGE_DIGEST is '${digest}'."
  exit 1
fi

echo "PASS: TaskRun $TR pushed $IMAGE; the registry digest $digest matches IMAGE_DIGEST."
exit 0
