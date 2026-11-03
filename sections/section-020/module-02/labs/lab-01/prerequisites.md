# Prerequisites

Before starting this lab you should be able to:

- Declare `volumes` in a Task and mount them with `volumeMounts`.
- Write a sidecar and reach it from a step over `localhost`.
- Write a Task result from a step.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** in the namespaces `tekton-pipelines` and `tekton-pipelines-resolvers`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- An empty namespace `starfleet`. The image `busybox:1.37.0` is on the node.

## Working rules

- Everything is graded on the **final cluster state**. Leave the Task and the TaskRun in place.
- The grader runs the Task once more with its own message.
