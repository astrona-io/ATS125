# Reuse Steps With StepActions

Many Tasks repeat the same step: clone a repository, print a banner, compose a log line, check a file. If every Task copies that step, every copy must be fixed when the step changes. Tekton solves this with a `StepAction`: an object that holds one step and that any Task can use by name. This module teaches how to write a `StepAction`, how a Task uses it, and what a Task may still change.

A `StepAction` is a namespaced object (`kind: StepAction`) with an image and a `script` or a `command`, plus optional parameters and results. A step in a Task that has a `ref` field instead of an `image` uses it. When a `TaskRun` starts, the tekton-pipelines-controller finds the `StepAction`, builds the step from it and runs it as one container, like any other step.

The module has four parts. **Write A StepAction And Use It With ref** creates the first `StepAction` and runs it from a Task. **Pass Parameters To A StepAction** declares parameters, passes values from the Task, and explains which value wins. **Return Results From A StepAction** writes step results and connects them to Task results. **Which Fields A ref Step Can Set** lists the fields a step with `ref` may and may not set, and shows how a Task fetches a `StepAction` from Git. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Write a `StepAction` with an image, a script, parameters and results.
- Use it from a Task with `ref`, and explain when Tekton resolves the reference.
- Pass parameters to it and name the order of precedence of their values.
- Return a value from a `StepAction` and expose it as a Task result.
- Name the fields a step with `ref` can set (`params`, `onError`, `timeout`, `computeResources`) and the fields it cannot (`image`, `command`, `args`, `script`, `env`, `volumeMounts`).

## Before you start

You need to read a `Task`: steps, `script`, `env`, parameters and results. You should know that a `TaskRun` runs the steps of a Task as containers of one pod, in order.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1: the controller, the webhook and the events controller |
| Namespace `tekton-pipelines-resolvers` | The remote resolvers, which fetch Tasks and StepActions from outside the cluster |
| Namespace `starfleet` | Empty. Your StepActions, Tasks and TaskRuns go here |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
