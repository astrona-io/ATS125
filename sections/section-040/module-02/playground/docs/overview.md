# Playground: Run And Debug Tasks With tkn

A clean `kind` cluster with Tekton Pipelines v1.17.1, the `tkn` CLI 0.46.2 and an empty namespace `starfleet`. Nothing is graded.

## What to try

- Start a Task with `tkn task start NAME -p key=value --showlog`, and preview it with `--dry-run --output yaml`.
- List runs with `tkn taskrun list` and describe the newest with `tkn taskrun describe --last`.
- Make a step exit with a non-zero code and find the exit code in `status.steps`.
- Write a file to `/tmp` in one step and read it in the next. Then use `/workspace`.
- Delete runs with `tkn taskrun delete --task NAME --keep 2 -f`.

Clean up with `kubectl delete taskruns --all -n starfleet`.
