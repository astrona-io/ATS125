# Task Volumes And Sidecars

A workspace is the usual way to give a Task files, but it is not the only one. A Task can declare its own volumes, and it can run helper containers next to its steps. This module teaches Task-level volumes, how they differ from workspaces, and sidecars: containers that run in the same pod as the steps and that a step reaches over `localhost`.

A volume in a Task is a Kubernetes volume that the Task defines itself and mounts into its steps with `volumeMounts`. A sidecar is a container in the pod of the `TaskRun` that starts before the steps and that Tekton stops after the last step ends. A sidecar can serve a test database, a mock API or a Docker daemon to the steps.

The module has four parts. **Task Volumes And volumeMounts** defines a volume and shares it between steps. **Workspaces Compared With Volumes** explains who controls each, and uses the workspace variables. **Sidecars In A Task** runs a small web server next to the steps. **Sidecar Lifecycle And Readiness** covers how Tekton starts and stops a sidecar, what the status shows and why a step must wait for it. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Declare `volumes` in a Task and mount them with `volumeMounts`.
- Explain what `/workspace` is and why files in `/tmp` do not reach the next step.
- Choose between a Task volume and a workspace.
- Use `$(workspaces.<name>.bound)`, `.path` and `.claim` in a Task.
- Write a sidecar and reach it from a step over `localhost`.
- Explain how Tekton stops a sidecar, and how a step waits until the sidecar answers.

## Before you start

You need to write a Task with steps and workspaces and to read the status of a `TaskRun`. You should know that all steps and sidecars of a `TaskRun` are containers in one pod, so they share the network of the pod.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1: the controller, the webhook and the events controller |
| Namespace `tekton-pipelines-resolvers` | The remote resolvers |
| Namespace `starfleet` | Empty. Your Tasks and TaskRuns go here |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
