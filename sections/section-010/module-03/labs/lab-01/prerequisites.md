# Prerequisites

Before starting this lab you should be able to:

- Declare an object parameter with `properties` and read a key with `$(params.<name>.<key>)`.
- Write a string result and an array result as text and JSON.
- Use `$(context.taskRun.name)` in a step.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** in the namespaces `tekton-pipelines` and `tekton-pipelines-resolvers`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- An empty namespace `starfleet`.

## Working rules

- Everything is graded on the **final cluster state**. Leave the Task and the TaskRun in place.
- The grader runs the Task once more with its own ship, so the Task must work for any values.
