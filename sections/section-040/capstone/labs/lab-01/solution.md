# Solution: Rescue A Night Of Report Runs

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the runaway and held runs; the new run with retries, a timeout and a memory limit; and the diagnosis ConfigMap.

## Step 1: Read the failed run

```sh
kubectl get taskrun nightly-report-timeout -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{.status.conditions[0].message}{"\n"}'
```

The reason is `TaskRunTimeout`: the run has a timeout of 10 seconds, and the step `collect` waits for 30. Record it:

```sh
kubectl create configmap nightly-diagnosis -n starfleet --from-literal=reason=TaskRunTimeout
```

## Step 2: Cancel the runaway run

```sh
kubectl patch taskrun nightly-report-runaway -n starfleet --type merge -p '{"spec":{"status":"TaskRunCancelled"}}'
kubectl wait --for=condition=Succeeded=False taskrun/nightly-report-runaway -n starfleet --timeout=60s
```

The command `tkn taskrun cancel nightly-report-runaway -n starfleet` does the same. Deleting the run would also stop it, but the task says to keep it.

## Step 3: Release the held run

```sh
kubectl patch taskrun nightly-report-held -n starfleet --type json -p '[{"op":"remove","path":"/spec/status"}]'
kubectl wait --for=condition=Succeeded taskrun/nightly-report-held -n starfleet --timeout=180s
```

## Step 4: Create the safe run

The first attempt fails when `flaky` is `true`, so one retry is enough. The timeout is per attempt, and the step `collect` sleeps for 5 seconds by default, so three minutes is plenty. Save this as `taskrun-nightly-report-retry.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: nightly-report-retry
  namespace: starfleet
spec:
  taskRef:
    name: nightly-report
  params:
    - name: flaky
      value: "true"
  retries: 1
  timeout: 3m
  stepSpecs:
    - name: publish
      computeResources:
        limits:
          memory: 64Mi
```

Apply it and read the result:

```sh
kubectl apply -f taskrun-nightly-report-retry.yaml
kubectl wait --for=condition=Succeeded taskrun/nightly-report-retry -n starfleet --timeout=300s
kubectl get taskrun nightly-report-retry -n starfleet -o jsonpath='{.status.results[0].value}{"\n"}'
```

## Step 5: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the runaway run | The grader needs the object with the reason `TaskRunCancelled` |
| Edit `nightly-report-timeout` | The spec of a started run cannot change; create a new run |
| `retries: 0` | The first attempt fails and the run ends |
| Put the memory limit in the Task | The task says to set it through the TaskRun |

## Common mistakes

- Setting `timeout: 0s`, which means no limit.
- Reading `status.results` of the held run before it has finished.

## Practice on your own

- Release the held run with `kubectl edit` instead of a patch.
- Add `serviceAccountName` and `podTemplate` to the retry run.
