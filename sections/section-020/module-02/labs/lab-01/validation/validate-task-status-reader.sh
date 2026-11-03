#!/usr/bin/env bash
# PASS when the Task status-reader has a sidecar named server, an emptyDir
# volume mounted both in the sidecar and in the step publish, the steps
# publish and fetch in that order, and a result named body.
set -uo pipefail
NS="starfleet"
if ! kubectl -n "$NS" get task status-reader >/dev/null 2>&1; then
  echo "FAIL: Task status-reader does not exist in $NS."; exit 1
fi
sidecars="$(kubectl -n "$NS" get task status-reader -o jsonpath='{.spec.sidecars[*].name}')"
if [ "$sidecars" != "server" ]; then
  echo "FAIL: the Task must have one sidecar named server (found '${sidecars}')."; exit 1
fi
steps="$(kubectl -n "$NS" get task status-reader -o jsonpath='{.spec.steps[*].name}')"
if [ "$steps" != "publish fetch" ]; then
  echo "FAIL: the Task must have the steps 'publish fetch' in that order (found '${steps}')."; exit 1
fi
vol="$(kubectl -n "$NS" get task status-reader -o jsonpath='{.spec.volumes[*].name}')"
if [ -z "$vol" ]; then
  echo "FAIL: the Task must declare a volume."; exit 1
fi
empty="$(kubectl -n "$NS" get task status-reader -o jsonpath='{.spec.volumes[0].emptyDir}')"
if [ -z "$empty" ]; then
  echo "FAIL: the volume must be an emptyDir."; exit 1
fi
side_mount="$(kubectl -n "$NS" get task status-reader -o jsonpath='{.spec.sidecars[0].volumeMounts[*].name}')"
step_mount="$(kubectl -n "$NS" get task status-reader -o jsonpath='{.spec.steps[?(@.name=="publish")].volumeMounts[*].name}')"
first_vol="${vol%% *}"
case " $side_mount " in *" $first_vol "*) ;; *) echo "FAIL: the sidecar must mount the volume $first_vol."; exit 1 ;; esac
case " $step_mount " in *" $first_vol "*) ;; *) echo "FAIL: the step publish must mount the volume $first_vol."; exit 1 ;; esac
results="$(kubectl -n "$NS" get task status-reader -o jsonpath='{.spec.results[*].name}')"
if [ "$results" != "body" ]; then
  echo "FAIL: the Task must declare the result body (found '${results}')."; exit 1
fi
echo "PASS: Task status-reader has the sidecar server, a shared emptyDir and the steps publish and fetch."
exit 0
