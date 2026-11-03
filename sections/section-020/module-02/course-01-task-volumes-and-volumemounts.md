# Task Volumes And volumeMounts

Steps of one Task are separate containers, and each has its own file system. A file that one step writes to `/tmp` is gone when the next step starts. To pass files between steps, the steps must share a volume. This part shows which folder Tekton already shares, and how a Task declares and mounts its own volumes.

## The folder every step shares

Tekton mounts one volume at `/workspace` in every step of a Task. It is an `emptyDir` volume: an empty folder that lives as long as the pod. A file that a step writes under `/workspace` is there for the steps after it. A file in `/tmp` is not, because `/tmp` belongs to the container of that step.

<!-- astrona:playground:renew -->

Save this as `task-tmp-or-workspace.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: tmp-or-workspace
  namespace: starfleet
spec:
  steps:
    - name: write
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        set -eu
        echo "in tmp" > /tmp/note.txt
        echo "in workspace" > /workspace/note.txt
    - name: read
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        ls /tmp/note.txt || echo "/tmp/note.txt is not here"
        cat /workspace/note.txt
```

Apply it and run it:

```sh
kubectl apply -f task-tmp-or-workspace.yaml
tkn task start tmp-or-workspace -n starfleet --showlog
```

The step `read` prints that `/tmp/note.txt` is missing, because the step runs in a new container. It prints `in workspace`, because `/workspace` is shared. A Task that fails because a file is "not found" in its second step is very often a Task that wrote to a folder that is not shared.

## Declare a volume

For anything other than the default folder, the Task declares `volumes` at the top level of its spec, in the same format as a Kubernetes pod. Each step then lists the volume in `volumeMounts` with a `name` and a `mountPath`. The volume can be an `emptyDir`, a `configMap`, a `secret` or another volume type the cluster allows.

Save this as `task-scratch-volume.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: scratch-volume
  namespace: starfleet
spec:
  volumes:
    - name: scratch
      emptyDir: {}
  steps:
    - name: produce
      image: busybox:1.37.0
      volumeMounts:
        - name: scratch
          mountPath: /scratch
      script: |
        #!/bin/sh
        set -eu
        seq 1 5 > /scratch/numbers.txt
    - name: consume
      image: busybox:1.37.0
      volumeMounts:
        - name: scratch
          mountPath: /scratch
      script: |
        #!/bin/sh
        set -eu
        echo "lines: $(wc -l < /scratch/numbers.txt)"
```

Apply it and run it:

```sh
kubectl apply -f task-scratch-volume.yaml
tkn task start scratch-volume -n starfleet --showlog
```

The step `consume` prints `lines: 5`. Both steps mount the same `emptyDir`, so the file survives from one container to the other. Each step must list the mount. A volume that is declared but not mounted in a step is not visible in that step.

## A ConfigMap as a volume

A Task can also mount a ConfigMap that holds fixed settings. The ConfigMap must exist in the namespace of the `TaskRun`, and each key becomes a file.

Create the ConfigMap and the Task:

```sh
kubectl create configmap ship-settings -n starfleet --from-literal=speed=warp5
kubectl apply -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: read-settings
  namespace: starfleet
spec:
  volumes:
    - name: settings
      configMap:
        name: ship-settings
  steps:
    - name: show
      image: busybox:1.37.0
      volumeMounts:
        - name: settings
          mountPath: /etc/ship
          readOnly: true
      script: |
        #!/bin/sh
        cat /etc/ship/speed
YAML
tkn task start read-settings -n starfleet --showlog
```

The log shows `warp5`. A ConfigMap volume is read-only in practice, and the ConfigMap name is fixed in the Task. If a TaskRun must choose the ConfigMap, a workspace is the better tool.

You can now share files between steps with `/workspace` and with your own volumes. The open question is when a Task should declare a volume and when it should declare a workspace.

## Common pitfalls

> [!WARNING]
> - **Writing to `/tmp` and reading in the next step.** `/tmp` is private to each step container. Use `/workspace` or a volume.
> - **Declaring a volume and forgetting `volumeMounts`.** The volume exists in the pod, but the step does not see it.
> - **Mounting a volume at a path the image uses.** The mount hides the files of the image under that path.
> - **A missing ConfigMap.** The step container cannot start, and the `TaskRun` fails with `CreateContainerConfigError`.
