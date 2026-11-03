# Cancel And Pending Runs

A run that was started by mistake, or that will clearly not finish, should stop at once. A run that is created before its inputs are ready should wait until they are. Tekton handles both with one field, `spec.status`, which is the only field of a started `TaskRun` that you can change. This part cancels a running `TaskRun` and holds one back in the pending state.

## Cancel a running TaskRun

Setting `spec.status` to `TaskRunCancelled` asks the controller to stop the run. The controller deletes the pod, sets the `Succeeded` condition to `False` with the reason `TaskRunCancelled`, and does not retry the run. Because the pod is deleted, the logs are gone, unless the setting `keep-pod-on-cancel` in the ConfigMap `feature-flags` is `"true"`.

<!-- astrona:playground:renew -->

Save this as `taskrun-cancel-me.yaml`. It embeds a step that sleeps for five minutes:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: cancel-me
  namespace: starfleet
spec:
  taskSpec:
    steps:
      - name: wait
        image: busybox:1.37.0
        script: |
          #!/bin/sh
          sleep 300
```

Apply it and patch its status:

```sh
kubectl apply -f taskrun-cancel-me.yaml
kubectl wait --for=condition=Ready pod/cancel-me-pod -n starfleet --timeout=120s || true
kubectl patch taskrun cancel-me -n starfleet --type merge -p '{"spec":{"status":"TaskRunCancelled"}}'
kubectl wait --for=condition=Succeeded=False taskrun/cancel-me -n starfleet --timeout=60s
kubectl get taskrun cancel-me -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}'
```

The reason is `TaskRunCancelled`. While the controller works, the condition can show `Unknown` with the same reason; it becomes `False` when the pod is gone. The `tkn` command-line tool does the same patch for you:

```sh
tkn taskrun cancel cancel-me -n starfleet
```

Run it on a `TaskRun` that is still running. On the one above, which already ended, it reports that the run has finished.

## Hold a run in the pending state

A `TaskRun` created with `spec.status: TaskRunPending` does not start. The controller creates no pod, sets no start time and does not run the timeout clock. The condition shows `Unknown` with the reason `TaskRunPending`. This is useful when the run is created by a tool before the data it needs is ready.

Save this as `taskrun-hold.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: hold
  namespace: starfleet
spec:
  status: TaskRunPending
  taskSpec:
    steps:
      - name: say
        image: busybox:1.37.0
        script: |
          #!/bin/sh
          echo "started after being held"
```

Apply it and look at it:

```sh
kubectl apply -f taskrun-hold.yaml
kubectl get taskrun hold -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}'
kubectl get pods -n starfleet -l tekton.dev/taskRun=hold
```

The reason is `TaskRunPending`, and no pod exists. To start the run, remove the field. A JSON patch removes it:

```sh
kubectl patch taskrun hold -n starfleet --type json -p '[{"op":"remove","path":"/spec/status"}]'
kubectl wait --for=condition=Succeeded taskrun/hold -n starfleet --timeout=120s
tkn taskrun logs hold -n starfleet
```

The run starts, and the log shows `started after being held`. You can set the pending state only before the run starts. A run that is already running cannot be moved back to pending.

You can now stop a run, hold a run and start it later. The open question is how to give a run the right resources and the right identity.

## Common pitfalls

> [!WARNING]
> - **Deleting a `TaskRun` instead of cancelling it.** Deleting removes the record. Cancelling keeps the object and its status.
> - **Cancelling and expecting logs.** The pod is deleted on cancel. Set `keep-pod-on-cancel` if you need them.
> - **Forgetting that a pending run never times out.** The clock starts only when you remove `TaskRunPending`.
> - **Editing other fields of a started run.** The webhook rejects every change to `spec` except `status`.
