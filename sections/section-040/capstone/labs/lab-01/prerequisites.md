# Prerequisites

Before starting this lab you should be able to:

- Read the `Succeeded` condition of a TaskRun.
- Cancel a running TaskRun and release a pending one.
- Set `retries`, `timeout` and `stepSpecs` on a TaskRun.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** in the namespaces `tekton-pipelines` and `tekton-pipelines-resolvers`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- The namespace `starfleet` with the Task `nightly-report` and the three TaskRuns. The image `busybox:1.37.0` is on the node.

## Working rules

- Everything is graded on the **final cluster state**. Leave the objects in place.
