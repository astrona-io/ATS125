#!/usr/bin/env bash
# PASS when the registry lists the tag 1.1 for starfleet/bridge-app and serves
# it with the same manifest digest as the result IMAGE_DIGEST of
# image-build-run.
set -uo pipefail

NS="starfleet"
TR="image-build-run"
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

digest="$(kubectl -n "$NS" get taskrun "$TR" -o jsonpath='{.status.results[?(@.name=="IMAGE_DIGEST")].value}' 2>/dev/null)"
case "$digest" in
  sha256:????????????????????????????????????????????????????????????????) ;;
  *) echo "FAIL: TaskRun $TR has IMAGE_DIGEST='${digest}', expected sha256: followed by 64 characters."; exit 1 ;;
esac

tags="$(kubectl -n registry exec deploy/client -- curl -s "$REGISTRY_URL/v2/starfleet/bridge-app/tags/list" 2>/dev/null)"
case "$tags" in
  *'"1.1"'*) ;;
  *) echo "FAIL: the registry has no tag 1.1 for starfleet/bridge-app (tags/list: '${tags}')."; exit 1 ;;
esac
pushed="$(registry_digest starfleet/bridge-app 1.1)"
if [ "$pushed" != "$digest" ]; then
  echo "FAIL: the registry serves starfleet/bridge-app:1.1 with digest '${pushed}', but IMAGE_DIGEST is '${digest}'."
  exit 1
fi

echo "PASS: the registry serves starfleet/bridge-app:1.1 with digest $digest, the same as IMAGE_DIGEST."
exit 0
