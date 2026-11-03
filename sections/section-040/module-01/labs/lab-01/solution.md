# Solution: Fix A Failing TaskRun With Timeout And Retries

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: the TaskRun `flaky-sync-run` (reference, retries, success, two failed attempts); and its timeout and result.

## Step 1: Find the cause

```sh
kubectl get taskrun flaky-sync-failed -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{.status.conditions[0].message}{"\n"}'
tkn taskrun logs flaky-sync-failed -n starfleet
kubectl get task flaky-sync -n starfleet -o yaml
```

The run failed because the step exits with an error while `$(context.taskRun.retry-count)` is below 2. The first attempt is number 0, so the Task needs attempts 0 and 1 to fail and attempt 2 to succeed. That means two retries.

## Step 2: Create the run

Each attempt gets its own full timeout, so two minutes per attempt is enough for a step that ends at once.

Save this as `taskrun-flaky-sync-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: flaky-sync-run
  namespace: starfleet
spec:
  taskRef:
    name: flaky-sync
  retries: 2
  timeout: 2m
```

Apply it, wait and read the record:

```sh
kubectl apply -f taskrun-flaky-sync-run.yaml
kubectl wait --for=condition=Succeeded taskrun/flaky-sync-run -n starfleet --timeout=300s
kubectl get taskrun flaky-sync-run -n starfleet -o jsonpath='{range .status.retriesStatus[*]}{.conditions[0].reason}{"\n"}{end}'
kubectl get taskrun flaky-sync-run -n starfleet -o jsonpath='{.status.results[0].value}{"\n"}'
```

The first command lists the reason of each failed attempt, and the second prints the result `2`.

## Step 3: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `retries: 1` | The second attempt still fails, because attempt 1 is below 2 |
| `timeout: 0` | The run has no limit, and the grader rejects it |
| Editing the Task to remove the failure | The grader needs two recorded failed attempts |
| Deleting `flaky-sync-failed` | The task says to keep it |

## Common mistakes

- Counting attempts from 1. The retry count starts at 0.
- Reading `status.results` of a run that is still retrying. Wait for the end first.

## Practice on your own

- Add `stepSpecs` with a memory limit for the step `sync`.
- Create the same run with `spec.status: TaskRunPending`, then remove the field.
