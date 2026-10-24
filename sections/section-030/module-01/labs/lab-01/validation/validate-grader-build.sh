#!/usr/bin/env bash
# PASS when a grader TaskRun of image-build with its own tag succeeds and the
# registry serves that tag with the digest the run reports. A Task that types
# the image name or the digest into its scripts fails here.
set -uo pipefail

NS="starfleet"
REGISTRY_URL="http://registry.registry.svc.cluster.local:5000"
TAG="grader-$(date +%s)"
IMAGE="registry.registry.svc.cluster.local:5000/starfleet/grader-app:$TAG"

registry_digest() {
  # registry_digest REPOSITORY TAG: the Docker-Content-Digest of a manifest.
  kubectl -n registry exec deploy/client -- curl -s -I \
    -H 'Accept: application/vnd.oci.image.manifest.v1+json' \
    -H 'Accept: application/vnd.oci.image.index.v1+json' \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
    "$REGISTRY_URL/v2/$1/manifests/$2" 2>/dev/null \
    | tr -d '\r' | awk -F': ' 'tolower($1)=="docker-content-digest" {print $2}'
}

manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT
cat > "$manifest" <<YAML
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: image-build-grader-
  namespace: starfleet
  labels:
    astrona.io/grader: "true"
spec:
  taskRef:
    name: image-build
  params:
    - name: IMAGE
      value: $IMAGE
    - name: CONTEXT
      value: bridge-app
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
for _ in $(seq 1 100); do
  status="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.conditions[?(@.type=="Succeeded")].status}' 2>/dev/null)"
  [ "$status" = "True" ] || [ "$status" = "False" ] && break
  sleep 3
done
url="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="IMAGE_URL")].value}' 2>/dev/null)"
digest="$(kubectl -n "$NS" get taskrun "$name" -o jsonpath='{.status.results[?(@.name=="IMAGE_DIGEST")].value}' 2>/dev/null)"
kubectl -n "$NS" delete taskrun "$name" --wait=false >/dev/null 2>&1 || true

if [ "$status" != "True" ]; then
  echo "FAIL: a grader TaskRun of image-build with IMAGE=$IMAGE did not succeed (Succeeded=${status:-none})."
  exit 1
fi
if [ "$url" != "$IMAGE" ]; then
  echo "FAIL: a grader TaskRun reported IMAGE_URL='${url}', expected '$IMAGE'."
  exit 1
fi
pushed="$(registry_digest starfleet/grader-app "$TAG")"
if [ -z "$pushed" ] || [ "$pushed" != "$digest" ]; then
  echo "FAIL: the registry serves $IMAGE with digest '${pushed}', but the grader run reported IMAGE_DIGEST='${digest}'."
  exit 1
fi

echo "PASS: a grader run pushed $IMAGE, and the registry digest matches IMAGE_DIGEST."
exit 0
