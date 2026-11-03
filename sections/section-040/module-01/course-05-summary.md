# Summary

A `TaskRun` controls how a Task runs: how long, how often, whether it can be stopped, as whom, and with which pod settings. Almost all of these fields are fixed when the run starts.

## What you learned

The field `timeout` of a `TaskRun` bounds the whole run and applies to each attempt. Without it, the value of `default-timeout-minutes` applies, which is 60 minutes, and `0` means no limit. A run that exceeds the timeout fails with `TaskRunTimeout`, and the controller deletes its pod and its logs. A step has its own `timeout`, which fails the run from inside and leaves the pod and the earlier logs.

The field `retries` runs a failed `TaskRun` again. Each failed attempt is kept in `status.retriesStatus`, the pod of a retry has the suffix `-pod-retry<N>`, and a Task reads the attempt number with `$(context.taskRun.retry-count)`. While a retry waits, the condition is `Unknown` with the reason `ToBeRetried`.

The field `spec.status` is the only field of a started run that can change. `TaskRunCancelled` stops the run, deletes the pod and is never retried. `TaskRunPending` holds a new run without a pod and without a running timeout until the field is removed.

The `stepSpecs` and `sidecarSpecs` fields override resources by name. The `serviceAccountName` field sets the identity of the pod, and the `podTemplate` field sets pod settings such as `securityContext`, `nodeSelector` and `imagePullSecrets`. The key facts to remember are these:

- A timeout is per attempt; a timed-out run loses its logs.
- Retry only work that is safe to repeat.
- Only `spec.status` can change after the start.
- The `TaskRun` carries the settings of the place; the Task stays the same.

<!-- astrona:playground:destroy -->
