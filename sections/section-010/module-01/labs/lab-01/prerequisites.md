# Prerequisites

Before starting this lab you should be able to:

- Read a `Task`: its `params`, `results`, `stepTemplate` and `steps`.
- Explain the difference between a `string` parameter and an `array` parameter, and how an array reaches a `script` through `args`.
- Read the `Succeeded` condition and `status.results` of a `TaskRun`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** in the namespaces `tekton-pipelines` and `tekton-pipelines-resolvers`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH. You can solve the lab with `kubectl` alone.
- The Task `image-tag` and the failed TaskRun `image-tag-run` in the namespace `starfleet`.

## Working rules

- Everything is graded on the **final cluster state**. Leave the Task and the TaskRun in place.
- The grader runs the Task once more with its own values, so the Task must work for any input, not only for `bridge`.
