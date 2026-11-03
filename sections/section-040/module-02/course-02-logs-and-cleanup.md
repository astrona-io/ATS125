# Logs And Cleanup

A step prints to its container log. Tekton keeps one container per step in the pod of the run, so the log of a run is the logs of several containers put together. This part reads the log of a whole run, of one step, and of a step that failed, and then deletes runs that are no longer needed.

## Read logs

<!-- astrona:playground:renew -->

Save this as `task-two-steps.yaml`. The second step fails:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: two-steps
  namespace: starfleet
spec:
  steps:
    - name: first
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        echo "first step done"
    - name: second
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        echo "second step starting"
        exit 4
```

Apply it and start it:

```sh
kubectl apply -f task-two-steps.yaml
tkn task start two-steps -n starfleet --showlog
```

The log shows the lines of both steps, each prefixed with the name of the step, and the tool reports that the run failed. To read the log again later, use the name of the run, or `--last`:

```sh
tkn taskrun logs --last -n starfleet
```

The same data comes from the containers of the pod. The container for a step is called `step-` followed by the step name:

```sh
POD=$(kubectl get pods -n starfleet -l tekton.dev/task=two-steps -o jsonpath='{.items[0].metadata.name}')
kubectl logs "$POD" -n starfleet -c step-second
```

This prints only the log of the step `second`. When a Task has many steps, reading one container is faster than reading the whole run.

## Delete runs

Every run leaves a `TaskRun` object and a pod. They stay until you delete them, and they count against the limits of the namespace. The pod has an owner reference to the `TaskRun`, so deleting the `TaskRun` deletes the pod and its logs.

```sh
tkn taskrun delete --last -n starfleet -f
```

The flag `-f` skips the confirmation question. To keep the newest few runs and delete the rest, use `--keep`:

```sh
tkn taskrun delete --task two-steps --keep 2 -n starfleet -f
```

The flag `--task` limits the delete to runs of one Task. Run the command only after you have read what you need, because the logs go with the pod.

You can now read logs for a run and for one step, and clean up. The open question is how to learn why a run failed without reading every log.

## Common pitfalls

> [!WARNING]
> - **Deleting the run before reading its log.** The pod and its logs are removed together with the `TaskRun`.
> - **Using `--keep` without `--task`.** It keeps the newest runs of all Tasks together, not of each Task.
> - **Reading the log of the wrong container.** The container for a step is `step-<name>`, and a sidecar is `sidecar-<name>`.
> - **Skipping `-f` in a script.** The delete asks a question and waits.
