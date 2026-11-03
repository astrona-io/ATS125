# Summary

Debugging a Tekton run is reading its status in a fixed order: the condition of the run, then the state of each step, then the log of the step that failed.

## What you learned

The command `tkn task start` creates a `TaskRun` from a Task. The flag `-p` sets a parameter, `--use-param-defaults` avoids questions, `--showlog` follows the log and `--dry-run --output yaml` prints the `TaskRun` without creating it. The commands `tkn taskrun list`, `describe` and `logs` show runs, with `--last` for the newest one.

The log of a run is the log of one container per step, named `step-<name>`. A sidecar container is named `sidecar-<name>`. Deleting a `TaskRun` with `tkn taskrun delete` removes its pod and its logs, and `--keep` with `--task` keeps the newest runs of one Task.

The condition of a failed run has the reason `Failed` and a message that names the step and the exit code. `status.steps` holds the reason and exit code of each step: `Completed` with 0, `Error` with the exit code of the script, or `OOMKilled` with 137. Other reasons you can meet are `TaskRunTimeout`, `TaskRunCancelled` and `TaskRunImagePullFailed`.

Only `/workspace`, the declared workspaces and volumes, `/tekton/results` and `/tekton/home` are shared between steps. A file in `/tmp` belongs to one step. The key facts to remember are these:

- Read the condition message first; it names the failed step.
- A log without the status hides steps that never ran.
- Deleting a run deletes its pod and its logs.
- Share files between steps through `/workspace`, not `/tmp`.

<!-- astrona:playground:destroy -->
