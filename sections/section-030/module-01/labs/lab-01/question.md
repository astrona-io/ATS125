# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Image build

## Scenario

The `starfleet` team keeps the source of `bridge-app` in the folder `bridge-app` of the PersistentVolumeClaim `bridge-source`: a `Dockerfile` and one file it copies. The team wants a reusable Task that builds the image with Buildah and pushes it to the lab registry, and that reports what it pushed so that later tools can use the digest.

## Your task

1. In the namespace `starfleet`, write a Task named `image-build` with this interface:
   - Parameters: `IMAGE` (string, no default), `CONTEXT` (string, default `.`) and `DOCKERFILE` (string, default `Dockerfile`, relative to `CONTEXT`).
   - One workspace, `source`, that holds the build context.
   - Results: `IMAGE_DIGEST` (the digest of the pushed manifest, `sha256:` and 64 hexadecimal characters) and `IMAGE_URL` (the value of `IMAGE`).
   - Steps that use the image `quay.io/buildah/stable:v1.43.5` to build the image and push it.
2. Create a TaskRun named `image-build-run` that builds `bridge-app` from `bridge-source` and pushes it as `registry.registry.svc.cluster.local:5000/starfleet/bridge-app:1.0`.

## Constraints

- Do not run the step containers as privileged and do not add Linux capabilities.
- The registry speaks plain HTTP. Switch off TLS verification for the push only; this is acceptable for a lab registry and nowhere else.
- Refer to the Task with `taskRef`; do not embed it with `taskSpec`. Do not change the PersistentVolumeClaim or the registry.

## Done when

- The Task `image-build` has the parameters, the workspace and the results above, and its steps use `quay.io/buildah/stable:v1.43.5`.
- `image-build-run` uses the Task with `bridge-source`, its `Succeeded` condition is `True`, and its `IMAGE_URL` is `registry.registry.svc.cluster.local:5000/starfleet/bridge-app:1.0`.
- The registry lists the tag `1.0` for `starfleet/bridge-app`, and serves it with the same digest as the result `IMAGE_DIGEST`.
- A new TaskRun of `image-build` with another tag succeeds, and the registry serves that tag with the digest the run reports.
