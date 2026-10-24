# Prerequisites

Before starting this lab you should be able to:

- Read the `workspaces` of a `Task`: `readOnly`, `optional`, `mountPath`, and a workspace used by one step only.
- Write the `workspaces` of a `TaskRun` with `persistentVolumeClaim`, `subPath`, `configMap` and `secret`.
- Read the `Succeeded` condition and `status.results` of a `TaskRun`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it. Its default StorageClass `standard` creates volumes on the node.
- **Tekton Pipelines v1.17.1** and the `tkn` command-line tool, version **0.46.2**.
- In the namespace `starfleet`: the Task `crew-roster`, the PersistentVolumeClaim `roster-data` with the folders `bridge` and `scout`, the ConfigMap `roster-settings` and the Secret `roster-token`.

## Working rules

- Everything is graded on the **final cluster state**. Leave the TaskRun in place.
- Do not change the Task, the ConfigMap or the Secret. The task is the TaskRun.
