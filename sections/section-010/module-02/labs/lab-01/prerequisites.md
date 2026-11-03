# Prerequisites

Before starting this lab you should be able to:

- Write a `Task` with parameters, results and steps.
- Use a `StepAction` from a step with `ref`, and pass it parameters.
- Expose a step result as a Task result with `value`.

## What the environment gives you

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** in the namespaces `tekton-pipelines` and `tekton-pipelines-resolvers`.
- The `tkn` command-line tool, version **0.46.2**, on your PATH.
- The `StepAction` `compose-line` in the namespace `starfleet`.

## Working rules

- Everything is graded on the **final cluster state**. Leave the Task and the TaskRun in place.
- The grader runs the Task once more with its own message.
