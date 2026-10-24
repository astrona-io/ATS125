# Prerequisites

Before starting this capstone you should be able to:

- Bind the workspaces of a `TaskRun` to a PersistentVolumeClaim, a ConfigMap and an `emptyDir`, with a `subPath` where needed.
- Explain `readOnly` on a workspace declaration, and why a `TaskRun` binds only one PersistentVolumeClaim by default.
- Read a file from a PersistentVolumeClaim with a small TaskRun of your own.

## What the environment gives you

The capstone environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and the `tkn` command-line tool, version **0.46.2**.
- In the namespace `starfleet`: the PersistentVolumeClaims `report-data` (with `reports/history.txt`) and `report-cache`, the ConfigMap `report-config`, the Task `deck-report` and the failed TaskRun `deck-report-run`.

## Working rules

- Everything is graded on the **final cluster state**. Leave the Task, the TaskRun and the data in place.
- Each fix shows the next fault. Expect to create the TaskRun more than once.
