# Summary

Tekton variables carry more than strings. Objects group related inputs, arrays and objects return structured outputs, and context variables tie a Task to the run that executes it.

## What you learned

An object parameter has the type `object` and a list of `properties`, and every key is a string. A default may fill some keys. Inside the Task, `$(params.<name>.<key>)` is one key, and the safe way to use it in a script is an environment variable. A key without a value fails the run before a pod exists.

A Task result can be a `string`, an `array` or an `object`. The step writes valid JSON into the result file, and the `TaskRun` reports the value with its type in `status.results`. An object result must contain every declared key, a result that is not valid JSON fails the run even when the step exits with 0, and `[]` counts as unset. All results of a pod still share about 4096 bytes.

The `context` variables are filled by the tekton-pipelines-controller for each run. They give the name, namespace and uid of the `TaskRun`, the name of the Task and the retry count. An array parameter is used as a whole with `[*]` in `args` or `command`, and by position with `[0]` where a string is allowed. Positions start at zero.

A parameter without a default is required, and a run without it fails early with the name of the parameter. `tkn task describe` shows what a Task needs, and `tkn task start` creates the run with `-p`, `--use-param-defaults`, `--showlog` and `--dry-run`. The key facts to remember are these:

- Object keys are strings, and the list of keys is declared in `properties`.
- Array and object results are JSON text in the result file.
- `$(context.taskRun.name)` changes with every run.
- A missing required parameter fails the run before any pod exists.

<!-- astrona:playground:destroy -->
