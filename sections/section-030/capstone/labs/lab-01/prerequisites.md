# Prerequisites

Before starting this capstone you should be able to:

- Read `status.steps` of a `TaskRun`: `terminated.exitCode` and `terminationReason` (`Completed`, `Continued`, `Skipped`).
- Explain `onError: continue` and `$(steps.step-<name>.exitCode.path)`, and how a last step can decide whether the TaskRun fails.
- Build and push an image with Buildah in a step, and check an image in a registry with its API.

## What the environment gives you

The capstone environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and the `tkn` command-line tool, version **0.46.2**.
- An OCI registry (`registry:3.1.2`, plain HTTP, lab only) at `registry.registry.svc.cluster.local:5000`, and a pod `client` with `curl` in the namespace `registry`.
- In `starfleet`: the PersistentVolumeClaim `bridge-source` with the folder `bridge-app`, the Task `image-build` and the TaskRun `image-build-run`.

## Working rules

- Everything is graded on the **final cluster state**. Leave the Task and the TaskRun in place.
- A build takes about a minute. Expect to create the TaskRun more than once.
