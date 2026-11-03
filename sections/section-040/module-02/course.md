# Run And Debug Tasks With tkn

Most Tekton problems are found with the same few commands: start a Task and watch it, list the runs, read the logs of the step that failed, and read the status to learn why it failed. This module teaches those commands, and how to read the status of a `TaskRun` down to the exit code of one step.

The `tkn` command-line tool is a thin layer over the Kubernetes API. Everything it shows can also be read with `kubectl`, and the module shows both, so you know where the data comes from. A `TaskRun` status holds the conditions of the run and, for every step, a container state with a reason and an exit code. A debugging session is mostly reading that status in the right order.

The module has four parts. **Start And Describe With tkn** starts a Task, previews the run and lists runs. **Logs And Cleanup** reads logs per step and deletes runs. **Reading Status And Termination Reasons** finds the failed step and its exit code. **Debugging Patterns** covers the usual causes of failure: folders that are not shared between steps, steps that end too fast to inspect, and pods that are gone. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Start a Task with `tkn task start` using parameters, and preview the run with `--dry-run`.
- List, describe and delete runs with `tkn taskrun`.
- Read logs for a whole run and for one step.
- Find the failed step, its exit code and its reason in `status.steps`.
- Explain why `/workspace` is shared between steps and `/tmp` is not.

## Before you start

You need to write a Task and a `TaskRun` and read the `Succeeded` condition.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1: the controller, the webhook and the events controller |
| Namespace `tekton-pipelines-resolvers` | The remote resolvers |
| Namespace `starfleet` | Empty. Your Tasks and TaskRuns go here |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
