# Summary

A `StepAction` moves one step into its own object so that many Tasks run the same code. A Task keeps control of the values, the limits and the failure behaviour, and the `StepAction` keeps control of what runs.

## What you learned

A `StepAction` has an image and a script or a command, and optional parameters and results. A Task step uses it with `ref.name` and has no `image` or `script` of its own. The tekton-pipelines-controller finds the `StepAction` in the namespace of the `TaskRun` when the run starts, so a wrong name fails the run, not the apply of the Task. A started run keeps the step it resolved.

Parameters work as in a Task: a type, an optional default, and a value passed by the step. A value that the step passes beats the default. The safe way to give a parameter to a script is an environment variable declared in the `StepAction`. A parameter without a default and without a value stops the run before it starts.

A `StepAction` returns values by writing `$(step.results.<name>.path)`. A later step reads them with `$(steps.<step>.results.<name>)` in `env`, `command` or `args`, and a Task result takes the value with `value`. Results keep every character, so they are written with `printf '%s'`.

A step with `ref` can set `params`, `timeout`, `onError`, `computeResources` and a few more container fields. It cannot set `image`, `command`, `args`, `script`, `env` or `volumeMounts`, and the webhook rejects a Task that does. A resolver can fetch a `StepAction` from Git or another source instead of the namespace. The key facts to remember are these:

- A `StepAction` is a definition, as a Task is; a `TaskRun` runs it.
- `ref` and `image` exclude each other in one step.
- Pass values through parameters and `env`, never into the script text.
- A step result is available to the steps after it.

<!-- astrona:playground:destroy -->
