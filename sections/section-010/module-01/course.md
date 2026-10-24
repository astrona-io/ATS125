# Write A Task From Steps, Parameters And Results

A `Task` that someone else wrote fails in your cluster. Is the image wrong, does the script use a shell the image does not have, does a parameter arrive as the wrong type, or does a result carry a stray newline? To answer, you must read a `Task` the way Tekton reads it: field by field, step by step. This module teaches the parts of a `Task` and what Tekton does with each of them.

A `Task` is a list of steps with inputs and outputs. A step is one container: an image, a command or a script, an environment and a working directory. Parameters bring values in, and results bring short values out. A `TaskRun` is one execution of a `Task`; the tekton-pipelines-controller turns it into one pod, with one container per step.

The module has three parts. **Steps: Image, Command, Script And Environment** takes a step apart: `command` and `args` against `script`, the entrypoint binary that wraps both, `env` and `envFrom`, `workingDir`, `computeResources` and the `stepTemplate`. **Parameters: Types, Defaults And Safe Substitution** covers `string`, `array` and `object` parameters, defaults, where each type may appear, and why values should reach a script through the environment. **Results From Tasks And From Steps** writes Task results and step results and explains their limits. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Name the fields of a step and explain what the container runs for `command` and `args` and for `script`.
- Explain the default shebang of a `script`, and why every step needs a `command` or a `script`.
- Set environment variables with `env`, `valueFrom` and `envFrom`, and share step settings with `stepTemplate`.
- Declare `string`, `array` and `object` parameters with defaults, and pass them from a `TaskRun` or with `tkn`.
- Use an array parameter through `args`, and pass parameters to a script through `env`.
- Write Task results without stray characters, and pass step results from one step to a later one.

## Before you start

You need Kubernetes basics: pods, containers, ConfigMaps, Secrets, environment variables and the commands `kubectl get`, `kubectl apply` and `kubectl logs`. You should know that a `TaskRun` gets one pod and that its steps run in order.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1: the controller, the webhook and the events controller |
| Namespace `tekton-pipelines-resolvers` | The remote resolvers, which fetch Tasks from outside the cluster |
| Namespace `starfleet` | Empty. Your Tasks and TaskRuns go here |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
