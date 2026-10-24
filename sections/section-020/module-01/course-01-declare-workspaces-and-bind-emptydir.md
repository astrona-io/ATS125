# Declare Workspaces And Bind An emptyDir

Steps of one `Task` already share the folder `/workspace`, but only inside one pod and only for as long as that pod lives. Real work needs more: source code that a `Task` reads, settings it must not change, credentials, and output that must outlive the run. A `Task` should not decide which storage that is; the person who runs it should. Workspaces split that decision in two, and this part shows how.

## The Task declares, the TaskRun binds

A workspace is a named folder that a `Task` needs at run time. The `Task` declares it under `spec.workspaces`, and the steps use its path. The `TaskRun` binds each declared workspace to a real volume under its own `spec.workspaces`. The same `Task` can then run with an `emptyDir` on a laptop and with a PersistentVolumeClaim in production, without a change.

A declaration has these fields:

| Field | What it does |
| --- | --- |
| `name` | The name the `TaskRun` binds and the steps refer to. Required |
| `description` | Free text for the reader |
| `mountPath` | Where the folder appears in the steps. Default: `/workspace/<name>` |
| `readOnly` | `true` mounts the volume read-only in every step. Default: `false` |
| `optional` | `true` lets a `TaskRun` leave the workspace out. Default: `false` |

Steps should not hard-code the path. Tekton offers variables for each workspace: `$(workspaces.<name>.path)` is the mount path, `$(workspaces.<name>.bound)` is `true` or `false`, `$(workspaces.<name>.claim)` is the name of the PersistentVolumeClaim behind it (empty for other volumes), and `$(workspaces.<name>.volume)` is the name of the pod volume.

## A first workspace

The `Task` below declares one workspace, `notes`. The first step writes a file into it, and the second reads the file back.

<!-- astrona:playground:renew -->

Save this as `task-share-notes.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: share-notes
  namespace: starfleet
spec:
  workspaces:
    - name: notes
      description: Where the steps keep their notes
  steps:
    - name: write
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        set -eu
        echo "engines ok" >> "$(workspaces.notes.path)/notes.txt"
        echo "Wrote to $(workspaces.notes.path), bound=$(workspaces.notes.bound)"
    - name: read
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        set -eu
        cat "$(workspaces.notes.path)/notes.txt"
```

Apply it:

```sh
kubectl apply -f task-share-notes.yaml
```

A `TaskRun` that does not bind `notes` fails at once. Save this as `taskrun-share-notes-unbound.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: share-notes-unbound
  namespace: starfleet
spec:
  taskRef:
    name: share-notes
```

Apply it:

```sh
kubectl apply -f taskrun-share-notes-unbound.yaml
```

Then check the result:

```sh
kubectl get taskrun share-notes-unbound -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{.status.conditions[0].message}{"\n"}'
```

The reason is `TaskRunValidationFailed`, and the message says that the declared workspace `notes` is required but has not been bound. The tekton-pipelines-controller checks the bindings before it creates a pod, the same way it checks parameters.

## Bind an emptyDir

The simplest binding is an `emptyDir`: an empty folder that Kubernetes creates with the pod and deletes with it. It is enough when only the steps of one `TaskRun` share the files.

Save this as `taskrun-share-notes-1.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: share-notes-1
  namespace: starfleet
spec:
  taskRef:
    name: share-notes
  workspaces:
    - name: notes
      emptyDir: {}
```

Apply it:

```sh
kubectl apply -f taskrun-share-notes-1.yaml
```

Then check the result:

```sh
tkn taskrun logs share-notes-1 -n starfleet -f
kubectl get pod share-notes-1-pod -n starfleet -o jsonpath='{range .spec.volumes[*]}{.name}{" "}{end}{"\n"}'
```

The log of `write` says it wrote to `/workspace/notes` with `bound=true`, and `read` prints `engines ok`. The list of pod volumes holds Tekton's own `tekton-internal-*` volumes and one more volume with a generated name, `ws-` followed by a short hash. That is the `emptyDir` behind `notes`, mounted at `/workspace/notes` in both step containers.

With `tkn`, the same binding is a flag:

```sh
tkn task start share-notes -n starfleet -w name=notes,emptyDir= --showlog
```

Each run starts with an empty folder, so `notes.txt` always holds one line. The data disappears with the pod.

## Workspaces and volumes

A `Task` can also declare plain Kubernetes `volumes` under `spec.volumes` and mount them in a step with `volumeMounts`, like a pod. The difference is who decides. With `volumes`, the `Task` author fixes the storage in the `Task`. With a workspace, the `TaskRun` picks it. Use `volumes` for scratch space that only the `Task` cares about, such as a shared cache folder for one tool, and workspaces for anything the caller provides or keeps.

You can now declare a workspace, use its path through variables, and bind it to an `emptyDir` with YAML or `tkn`. The open question is how to give a step data it must only read, such as settings and credentials.

## Common pitfalls

> [!WARNING]
> - **A required workspace left unbound.** The run fails with `TaskRunValidationFailed` before a pod exists. Bind every workspace that is not `optional`.
> - **A binding with a name the `Task` does not declare.** That fails the same way. The names must match exactly.
> - **Hard-coding `/workspace/<name>`.** A `mountPath` in the declaration moves the folder. Use `$(workspaces.<name>.path)`.
> - **Expecting an `emptyDir` to keep data.** It lives as long as the pod. Use a PersistentVolumeClaim to keep files between runs.
