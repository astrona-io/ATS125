# Summary

A `Task` is a list of steps with inputs and outputs, and each step is one container. Once you can read every field of a step, you can predict what its container runs, which values it sees and what it hands back.

## What you learned

A step has a name and an image, and it runs either `command` and `args` or a `script`, never both. The tekton-pipelines-controller replaces the command of every step container with the entrypoint binary, which starts your program in order and records its exit code. A `script` without a shebang gets `#!/bin/sh` and `set -e`, and its interpreter must exist in the image. A step without `command` or `script` makes the controller ask the registry for the image's entrypoint.

Steps take the usual container fields: `env` with values or `valueFrom`, `envFrom` for a whole ConfigMap or Secret, `workingDir`, `volumeMounts` and `computeResources`. The `stepTemplate` holds settings for every step, merged by name, and the value in a step wins over the template. A missing Secret or ConfigMap key stops the container from starting. A `StepAction` is a reusable step in its own object, used with `ref`.

Parameters have the types `string`, `array` and `object`. A parameter without a default must get a value from every `TaskRun`, and a value of the wrong type fails the run with `TaskRunValidationFailed` before a pod exists. An array can only appear as a whole item of `command` or `args`. Tekton replaces parameters as plain text, so values should reach a script through `env` or `args`.

Results leave a step through the file `$(results.<name>.path)`, the termination message and `status.results`. They keep every character, newlines included, and all results of a pod share about 4096 bytes. Step results pass a value to a later step: one step writes `$(step.results.<name>.path)`, and a later step reads `$(steps.<step>.results.<name>)` in `env`, `command` or `args`, or a Task result takes it with `value`. The key facts to remember are these:

- One step is one container; `script` and `command` exclude each other.
- The value in a step beats the value in the `stepTemplate`.
- Arrays go into `args`, never into `script`.
- Write results with `printf '%s'`, never with `echo`.

<!-- astrona:playground:destroy -->
