# Object Parameters, Array Results And Context Variables

Strings are enough for a small Task. Real Tasks take a group of related values, such as the name and the class of a ship, and return a list of values, such as the tags of an image. They also need to know which `TaskRun` they belong to. This module teaches the parts of the Tekton variable system that handle these cases: object parameters, array and object results, the `context` variables and array indexing.

A parameter is an input of a Task, and a result is an output. Both can be more than a string. An object parameter is a set of named string values with a fixed list of keys. An array result is a JSON list that the `TaskRun` reports in its status. The `context` variables are values that Tekton fills in about the run itself, such as the name of the `TaskRun`.

The module has four parts. **Object Parameters And Their Properties** declares an object, passes it and reads single keys. **Array And Object Results** writes JSON results and reads them from the status. **Context Variables And Array Indexing** uses `$(context.taskRun.name)` and `$(params.list[0])`. **Defaults, Required Parameters And Starting A Task With tkn** covers what happens when a value is missing and how `tkn` passes values. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Declare an object parameter with `properties`, and read one key with `$(params.<name>.<key>)`.
- Pass an object from a `TaskRun`, and explain what happens when a key is missing.
- Write an array result and an object result as JSON, and read them from `status.results`.
- Use `$(context.taskRun.name)`, `$(context.taskRun.namespace)`, `$(context.task.name)` and `$(context.taskRun.uid)`.
- Read one item of an array parameter with an index, and pass a whole array with `[*]`.
- Start a Task with `tkn` and use `--use-param-defaults`.

## Before you start

You need to read a `Task` with string and array parameters, and to know how a Task result is written. You should know that Tekton replaces parameters as plain text before the step runs.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1: the controller, the webhook and the events controller |
| Namespace `tekton-pipelines-resolvers` | The remote resolvers |
| Namespace `starfleet` | Empty. Your Tasks and TaskRuns go here |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
