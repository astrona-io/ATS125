# Playground: Control How A TaskRun Runs

A clean `kind` cluster with Tekton Pipelines v1.17.1, the `tkn` CLI 0.46.2 and an empty namespace `starfleet`. Nothing is graded.

## What to try

- Run a Task with `timeout: 15s` and a step that sleeps for 60 seconds. Read the reason of the `Succeeded` condition.
- Add `timeout` to one step and see that the pod and the earlier logs stay.
- Set `retries: 2` on a Task that fails on `$(context.taskRun.retry-count)` below 2. Read `status.retriesStatus`.
- Create a `TaskRun` with `spec.status: TaskRunPending`, then remove the field with a JSON patch.
- Cancel a running `TaskRun` with `tkn taskrun cancel`.
- Override a step memory limit with `stepSpecs`, and set a `podTemplate` security context.

Clean up with `kubectl delete taskruns --all -n starfleet`.
