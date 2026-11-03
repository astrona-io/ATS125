# Control How A TaskRun Runs

A Task describes what to do. A `TaskRun` decides how the run behaves: how long it may take, how often it is tried again, whether it can be stopped, which account and which pod settings it uses. A Task that works in a test can hang for an hour in production, or fail once because of a slow network, unless the `TaskRun` sets these limits. This module teaches the fields of a `TaskRun` that control a run.

A `TaskRun` is one execution of a Task. Its `spec` names the Task, passes parameters and binds workspaces, and it also holds `timeout`, `retries`, `status`, `serviceAccountName`, `podTemplate`, `stepSpecs` and `sidecarSpecs`. Most of these fields cannot change after the run starts. The one exception is `status`, which starts, pauses or cancels a run.

The module has four parts. **Timeouts For A TaskRun And For A Step** limits the time of a run and of one step. **Retries And The Retry Count** runs a failed run again and records each attempt. **Cancel And Pending Runs** stops a run, and holds one back until you are ready. **Resources, Service Account And Pod Settings** sets limits per step and the settings of the pod. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Set `timeout` on a `TaskRun` and on a step, and read the reason `TaskRunTimeout`.
- Name the default timeout and explain what `0` means.
- Set `retries`, read `status.retriesStatus` and use `$(context.taskRun.retry-count)`.
- Cancel a run with `spec.status: TaskRunCancelled` and with `tkn`, and start a run from `TaskRunPending`.
- Set `stepSpecs`, `sidecarSpecs`, `serviceAccountName` and `podTemplate`.

## Before you start

You need to write a Task and a `TaskRun`, read the `Succeeded` condition and know that a `TaskRun` gets one pod.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1: the controller, the webhook and the events controller |
| Namespace `tekton-pipelines-resolvers` | The remote resolvers |
| Namespace `starfleet` | Empty. Your Tasks and TaskRuns go here |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
