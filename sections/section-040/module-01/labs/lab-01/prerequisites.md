# Prerequisites

Before starting this lab you should be able to:

- Write a TaskRun that refers to a Task.
- Read the `Succeeded` condition and the logs of a pod.
- Set `timeout` and `retries` on a TaskRun and read `status.retriesStatus`.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** in the namespaces `tekton-pipelines` and `tekton-pipelines-resolvers`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- The namespace `starfleet` with the Task `flaky-sync` and the failed TaskRun `flaky-sync-failed`. The image `busybox:1.37.0` is on the node.

## Working rules

- Everything is graded on the **final cluster state**. Leave the TaskRun in place.
