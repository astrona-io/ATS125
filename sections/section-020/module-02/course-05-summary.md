# Summary

A Task can carry its own volumes and its own helper containers. Volumes move files between steps, workspaces let the caller decide the storage, and sidecars give the steps a process to talk to.

## What you learned

Every step runs in its own container with its own file system, so a file in `/tmp` does not reach the next step. Tekton shares one `emptyDir` at `/workspace` between all steps. A Task can also declare `volumes` and mount them in each step with `volumeMounts`, using an `emptyDir`, a ConfigMap, a Secret or another volume type. A mount hides the image files at the same path.

A volume is fixed in the Task, and a workspace is a name that the `TaskRun` binds. A workspace can be optional. The variables `$(workspaces.<name>.path)`, `.bound`, `.claim` and `.volume` tell the Task how it was run, and a script checks `bound` before it uses an optional workspace.

A sidecar is a container of the pod that starts with the pod and runs beside the steps. Steps reach it at `localhost` and its port, and they can share a volume with it. Tekton names the containers `step-<name>` and `sidecar-<name>`. When the last step ends, the controller replaces the sidecar image with the `nop` image so that the container ends. The status of the `TaskRun` lists sidecars, and a failing sidecar can end the run with `SidecarFailed` or `SidecarOOM`.

Steps do not wait for sidecars by default. A retry loop in the calling step is the portable answer. The setting `enable-kubernetes-sidecar` is off by default and enables native sidecars with startup probes. The key facts to remember are these:

- `/workspace` is shared between steps; `/tmp` is not.
- A volume belongs to the Task, a workspace to the `TaskRun`.
- A step reaches a sidecar at `localhost`.
- A step must retry until the sidecar answers.

<!-- astrona:playground:destroy -->
