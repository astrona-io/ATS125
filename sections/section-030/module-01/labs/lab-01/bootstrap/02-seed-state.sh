#!/usr/bin/env bash
# Creates the starting state for ats-125-lab-030-01.
#
# 1. Applies the ConfigMap bridge-app-files, the PersistentVolumeClaim
#    bridge-source and a seed pod that copies the Dockerfile and message.txt
#    into the folder bridge-app of the claim.
# 2. Waits until the seed pod has finished, then deletes it.
#
# The registry and the client pod come from lab-start.yaml; the install
# script already waited for them. Writing the build Task is the task.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

kubectl apply -f "$MANIFESTS/bridge-source.yaml"
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Succeeded pod/seed-bridge-source --timeout=300s
kubectl -n starfleet logs seed-bridge-source
kubectl -n starfleet delete pod seed-bridge-source --wait=true

echo "[lab] Starting state ready."
kubectl -n starfleet get pvc,configmaps
kubectl -n registry get deployments,services
echo "[lab] Write the Task image-build and the TaskRun image-build-run."
