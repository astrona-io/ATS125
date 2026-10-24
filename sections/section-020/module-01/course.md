# Share Files With Workspaces

A build `Task` needs source code, a deploy `Task` needs settings, an upload `Task` needs a token, and a report `Task` needs a file that grows from run to run. None of that fits into parameters and results, which carry only short values. Workspaces carry files. This module shows how a `Task` asks for folders and how a `TaskRun` fills them with real storage.

A workspace is a named folder that a `Task` declares and its steps use through `$(workspaces.<name>.path)`. The `TaskRun` binds each workspace to a volume: an `emptyDir`, a ConfigMap, a Secret, an existing PersistentVolumeClaim (PVC), or a new PVC made from a `volumeClaimTemplate`. The `Task` stays the same; only the binding changes.

The module has three parts. **Declare Workspaces And Bind An emptyDir** covers the declaration fields, the workspace variables, the first binding, and the difference from plain `volumes`. **ConfigMap And Secret Workspaces** mounts read-only settings and credentials, makes a workspace optional, and limits a Secret to one step. **Persistent Workspaces With PersistentVolumeClaims** keeps files between runs, uses `subPath` and `volumeClaimTemplate`, and explains why a `TaskRun` binds only one PVC by default. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Declare workspaces with `mountPath`, `readOnly` and `optional`, and use `$(workspaces.<name>.path)`, `.bound`, `.claim` and `.volume`.
- Bind a workspace to an `emptyDir`, a ConfigMap, a Secret, an existing PVC and a `volumeClaimTemplate`, in YAML and with `tkn -w`.
- Explain which bindings are read-only, and what `readOnly` in the declaration changes.
- Limit a workspace to one step, and to one folder of a volume with `subPath`.
- Explain the life of a PVC created from a `volumeClaimTemplate`, and the one-PVC rule of the default `coschedule` setting.
- Read the failure when a workspace is unbound, read-only or bound twice to different PVCs.

## Before you start

You need Kubernetes basics: pods, volumes, ConfigMaps, Secrets, PersistentVolumeClaims and StorageClasses. You should be able to write a `Task` with steps and results, and read the `Succeeded` condition of a `TaskRun`.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1: the controller, the webhook and the events controller |
| Namespace `tekton-pipelines-resolvers` | The remote resolvers, which fetch Tasks from outside the cluster |
| Namespace `starfleet` | Empty. Your Tasks, TaskRuns, ConfigMaps, Secrets and PVCs go here |
| StorageClass `standard` | kind's default; it creates a volume on the node for each new PVC |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
