# Retries And The Retry Count

Some failures go away when the work is tried again: a registry that is briefly unreachable, a node that is full, a package mirror that returns an error once. Running the whole `TaskRun` again by hand costs time. The field `retries` tells Tekton to do it for you. This part sets `retries`, reads the record of the failed attempts and lets a Task see which attempt it is.

## Set retries

The field `spec.retries` of a `TaskRun` is the number of extra attempts after the first failure. With `retries: 2`, Tekton makes at most three attempts. Each attempt gets the full `timeout`, so the timeout is a limit per attempt, not for all attempts together. A cancelled run is never retried.

A Task can find out which attempt it is with `$(context.taskRun.retry-count)`, which is `0` in the first attempt, `1` in the second, and so on. The Task below fails in the first attempt and succeeds in the second, which makes the record easy to read.

<!-- astrona:playground:renew -->

Save this as `task-flaky.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: flaky
  namespace: starfleet
spec:
  results:
    - name: attempt
  steps:
    - name: try
      image: busybox:1.37.0
      env:
        - name: ATTEMPT
          value: $(context.taskRun.retry-count)
      script: |
        #!/bin/sh
        set -eu
        echo "attempt number $ATTEMPT"
        if [ "$ATTEMPT" = "0" ]; then
          echo "failing on purpose"
          exit 1
        fi
        printf '%s' "$ATTEMPT" > "$(results.attempt.path)"
```

Apply it, then save this as `taskrun-flaky-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: flaky-run
  namespace: starfleet
spec:
  taskRef:
    name: flaky
  retries: 1
```

Apply it and wait for the end:

```sh
kubectl apply -f task-flaky.yaml
kubectl apply -f taskrun-flaky-run.yaml
kubectl wait --for=condition=Succeeded taskrun/flaky-run -n starfleet --timeout=180s
```

The run ends as succeeded, although its first attempt failed.

## Read the record of the attempts

The status keeps each failed attempt in `status.retriesStatus`. Each entry is a copy of the status of one attempt, with its own conditions and steps. The list is empty when no retry was needed.

```sh
kubectl get taskrun flaky-run -n starfleet -o jsonpath='{range .status.retriesStatus[*]}{.conditions[0].reason}{"\n"}{end}'
kubectl get taskrun flaky-run -n starfleet -o jsonpath='{.status.podName}{"\n"}{.status.results[0].value}{"\n"}'
```

The first command prints one line with the reason `Failed` of the first attempt. The second prints the name of the pod of the last attempt, which ends in `-pod-retry1`, and the result `1`. The first attempt used the pod `flaky-run-pod`. Both pods stay in the namespace, so you can read the log of the failed attempt:

```sh
kubectl logs flaky-run-pod -n starfleet -c step-try
```

While a retry waits to start, the condition of the run is `Unknown` with the reason `ToBeRetried`. Tekton clears `startTime`, `podName` and `results` at that moment and keeps the old values in `retriesStatus`.

You can now run a task again on failure and read what happened in each attempt. The open question is how to stop a run on purpose, and how to hold one back.

## Common pitfalls

> [!WARNING]
> - **Using retries to hide a real bug.** A Task that fails every time still fails; it only takes longer. Fix the cause.
> - **Retrying work that is not safe to repeat.** A step that sends an email or charges a card does it again in the next attempt. Write such steps so that a second run does no harm.
> - **Reading `status.results` for an attempt that failed.** Results are cleared for a retry. Read `retriesStatus` instead.
> - **Counting the timeout as a total.** Each attempt gets its own full timeout.
