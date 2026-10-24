# Prerequisites

Before starting this capstone you should be able to:

- Read the `Succeeded` condition, `status.steps` and `status.results` of a `TaskRun`, and the state of the containers in its pod.
- Explain how `stepTemplate`, `env` with `valueFrom`, `script` shebangs and array parameters work in a step.
- Explain step results: `$(step.results.<name>.path)`, `$(steps.<step>.results.<name>)` and a Task result with `value`.

## What the environment gives you

The capstone environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and the `tkn` command-line tool, version **0.46.2**.
- In the namespace `starfleet`: the Secret `report-token`, the Task `crew-manifest` and the failed TaskRun `crew-manifest-run`.

## Working rules

- Everything is graded on the **final cluster state**. Leave the Secret, the Task and the TaskRun in place.
- Each fix shows the next fault. Expect to create the TaskRun more than once.
