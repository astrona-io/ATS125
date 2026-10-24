# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Image build

## Scenario

The `starfleet` team builds `bridge-app` with the Task `image-build`. Its steps `build` and `push` run Buildah and are allowed to fail, so that the last step `report` always runs and writes the result `BUILD_STATUS`. The TaskRun `image-build-run` for version `1.1` shows `Succeeded`, yet nobody can pull `starfleet/bridge-app:1.1` from the registry.

## Your task

1. Find out what really happened in `image-build-run` in the namespace `starfleet`. Read `status.steps` and the step logs, not only the `Succeeded` condition.
2. Fix every fault in the Task. There are three: two stop the image from being built or pushed, and one hides those failures.
3. Leave a TaskRun named `image-build-run` that pushes `registry.registry.svc.cluster.local:5000/starfleet/bridge-app:1.1`.

## Constraints

- Keep the steps `build`, `push` and `report`, in that order. `build` and `push` keep `onError: continue`, so that `report` always runs.
- When `build` or `push` fails, `report` must still write `BUILD_STATUS`, and the TaskRun must end with `Succeeded` = `False`.
- Do not run the step containers as privileged and do not add Linux capabilities. Switch off TLS verification only for the push to this lab registry.
- The TaskRun keeps `taskRef` name `image-build`, the parameters `IMAGE` and `CONTEXT` = `bridge-app`, and the workspace `source` bound to `bridge-source`.

## Done when

- `image-build-run` succeeded, its steps `build`, `push` and `report` all ended with exit code `0`, `BUILD_STATUS` is `built and pushed`, and `IMAGE_URL` is `registry.registry.svc.cluster.local:5000/starfleet/bridge-app:1.1`.
- The registry lists the tag `1.1` for `starfleet/bridge-app` and serves it with the same digest as `IMAGE_DIGEST`.
- A new TaskRun of `image-build` whose `DOCKERFILE` does not exist ends with `Succeeded` = `False` and the reason `StepFailed`: `build` ends with the termination reason `Continued`, and `report` runs and ends with a non-zero exit code.
