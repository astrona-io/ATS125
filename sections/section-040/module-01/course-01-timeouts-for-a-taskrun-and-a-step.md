# Timeouts For A TaskRun And For A Step

A step that waits for a server that never answers does not fail. It waits. Without a limit, the run holds a pod, a node and often a person's attention for as long as Tekton allows. A timeout turns a hang into a failure that someone can see. This part sets a timeout on a `TaskRun`, sets a timeout on one step, and reads how each ends.

## The timeout of a TaskRun

The field `spec.timeout` of a `TaskRun` is the longest time the whole run may take. It is a Go duration such as `30s`, `5m` or `1h30m`. The value `0` means no limit. If the field is left out, Tekton uses the value of `default-timeout-minutes` in the ConfigMap `config-defaults` of the namespace `tekton-pipelines`, which is 60 minutes.

<!-- astrona:playground:renew -->

Read the default in your cluster:

```sh
kubectl get configmap config-defaults -n tekton-pipelines -o jsonpath='{.data.default-timeout-minutes}{"\n"}'
```

Now save this as `task-sleeper.yaml`. The step sleeps for 60 seconds:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: sleeper
  namespace: starfleet
spec:
  steps:
    - name: wait
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        echo "sleeping"
        sleep 60
        echo "awake"
```

Apply it, then run it with a timeout of 15 seconds. Save this as `taskrun-sleeper-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: sleeper-run
  namespace: starfleet
spec:
  taskRef:
    name: sleeper
  timeout: 15s
```

```sh
kubectl apply -f task-sleeper.yaml
kubectl apply -f taskrun-sleeper-run.yaml
kubectl wait --for=condition=Succeeded=False taskrun/sleeper-run -n starfleet --timeout=120s
kubectl get taskrun sleeper-run -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{.status.conditions[0].message}{"\n"}'
```

The reason is `TaskRunTimeout`, and the message says that the run exceeded its timeout of 15 seconds. The timer starts when the controller picks up the `TaskRun`, so the time spent to create the pod and pull the image counts. Keep that in mind when you choose small values.

When a run times out, the controller deletes the pod. The step logs go with it, so `tkn taskrun logs` can show nothing for a timed-out run. If you need the logs, send them to an external system while the run is alive.

## The timeout of a step

A step has its own `timeout` field, in the Task. When the step runs longer, Tekton ends the step, skips the steps after it and fails the run. The failure comes from the step, so the pod stays and the logs of the earlier steps remain.

Save this as `task-step-timeout.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: step-timeout
  namespace: starfleet
spec:
  steps:
    - name: quick
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        echo "this step finishes"
    - name: slow
      image: busybox:1.37.0
      timeout: 5s
      script: |
        #!/bin/sh
        sleep 60
    - name: never
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        echo "this step does not run"
```

Apply it and run it:

```sh
kubectl apply -f task-step-timeout.yaml
tkn task start step-timeout -n starfleet --showlog
kubectl get taskrun -n starfleet -l tekton.dev/task=step-timeout -o jsonpath='{range .items[0].status.steps[*]}{.name}{" "}{.terminated.reason}{" "}{.terminated.exitCode}{"\n"}{end}'
```

The step `quick` ends normally. The step `slow` is stopped after five seconds, and its termination reason is not `Completed`. The step `never` has no termination state, because it did not start. A step timeout is the right tool to bound one risky command, while the `TaskRun` timeout bounds the whole run.

You can now bound a run and a step, and tell the two failures apart. The open question is what to do when a failure is temporary, which is the job of retries.

## Common pitfalls

> [!WARNING]
> - **Leaving the default of 60 minutes.** A hung run holds a pod for an hour. Set a timeout that fits the work.
> - **A timeout that is too short.** The time to start the pod and pull images counts against the run.
> - **Looking for logs after `TaskRunTimeout`.** The pod is deleted, and the logs go with it.
> - **Using a step timeout as the run limit.** Three slow steps can still exceed the run you meant to bound.
