# Workspaces Compared With Volumes

A volume and a workspace both put files into a step. The difference is who decides what the files live on. A volume is fixed inside the Task. A workspace is a name in the Task that the `TaskRun` fills with a volume of its choice. This part compares the two, and reads the workspace variables that let a Task check how it was run.

## Who decides

A Task with `volumes` carries its storage with it: the ConfigMap name or the `emptyDir` is written in the Task, and every run uses it. Anyone who runs the Task gets the same storage, and no one can change it without changing the Task.

A Task with `workspaces` only says "I need a folder with this name". The `TaskRun` binds the name to an `emptyDir`, a ConfigMap, a Secret, a PersistentVolumeClaim or a `volumeClaimTemplate`. The same Task can then run against a temporary folder in a test and a persistent volume in production.

| Question | Task `volumes` | Task `workspaces` |
| --- | --- | --- |
| Where is the storage chosen? | In the Task | In the `TaskRun` |
| Can the `TaskRun` change it? | No | Yes |
| Can the folder be optional? | No | Yes, with `optional: true` |
| Where is it mounted? | At the `mountPath` of each step | At `/workspace/<name>`, or at the `mountPath` of the workspace |

Use a workspace for anything a caller may need to supply or collect: source code, build output, credentials. Use a volume for a fixed scratch folder or for a fixed configuration.

## The workspace variables

A Task reads facts about a workspace with variables. `$(workspaces.<name>.path)` is the folder where the workspace is mounted. `$(workspaces.<name>.bound)` is `true` if the `TaskRun` bound the workspace, and `false` if it did not. `$(workspaces.<name>.claim)` is the name of the PersistentVolumeClaim, and it is empty when the workspace is not backed by one. `$(workspaces.<name>.volume)` is the name of the volume in the pod.

<!-- astrona:playground:renew -->

Save this as `task-bound-or-not.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: bound-or-not
  namespace: starfleet
spec:
  workspaces:
    - name: output
      description: Where the report goes
    - name: extras
      description: Extra files, if the caller has any
      optional: true
  steps:
    - name: report
      image: busybox:1.37.0
      env:
        - name: OUTPUT_PATH
          value: $(workspaces.output.path)
        - name: EXTRAS_BOUND
          value: $(workspaces.extras.bound)
        - name: EXTRAS_PATH
          value: $(workspaces.extras.path)
      script: |
        #!/bin/sh
        set -eu
        echo "output at $OUTPUT_PATH"
        echo "extras bound: $EXTRAS_BOUND"
        if [ "$EXTRAS_BOUND" = "true" ]; then
          ls "$EXTRAS_PATH"
        fi
```

Apply it and run it without the optional workspace:

```sh
kubectl apply -f task-bound-or-not.yaml
tkn task start bound-or-not -n starfleet -w name=output,emptyDir= --showlog
```

The log shows `output at /workspace/output` and `extras bound: false`. The step does not touch `extras`, because the script checks the variable first. The option `-w name=output,emptyDir=` of `tkn` binds the workspace `output` to an empty temporary folder.

Run it again and bind the optional workspace too, to a ConfigMap that has one key:

```sh
kubectl create configmap extra-files -n starfleet --from-literal=hello.txt=hi
tkn task start bound-or-not -n starfleet -w name=output,emptyDir= -w name=extras,config=extra-files --showlog
```

This time `extras bound: true` appears, followed by the file name `hello.txt`. The same Task works with and without the extra files, because the script reads `bound` before it uses the path.

## Mix them

A Task may declare both. A common pattern is a workspace for the source and a volume for a cache folder that the Task keeps to itself. Nothing stops you from mounting a volume under a workspace folder, but the result is hard to read, so keep the two apart.

You now know how to choose between a volume and a workspace and how a Task reads how it was bound. The open question is how a Task runs a helper process next to its steps, which is the job of a sidecar.

## Common pitfalls

> [!WARNING]
> - **Reading an optional workspace without checking `bound`.** The path exists as text, but the folder does not.
> - **Hard-coding a ConfigMap in a Task that others run.** Callers cannot change it. Use a workspace.
> - **Expecting `claim` to be set for every workspace.** It is empty unless a PersistentVolumeClaim backs the workspace.
> - **Mounting two things at the same path.** The later mount hides the earlier one.
