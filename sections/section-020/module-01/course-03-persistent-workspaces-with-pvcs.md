# Persistent Workspaces With PersistentVolumeClaims

An `emptyDir` disappears with its pod, and a ConfigMap cannot be written. Source code that one run checks out and another run builds, a build cache, or a report history that grows week by week, all need storage that lives longer than one pod. In Kubernetes that storage is a PersistentVolumeClaim (PVC): a request for a volume that keeps its data until you delete it. This part binds an existing PVC to a workspace, limits it to one folder with `subPath`, lets Tekton create a PVC per run, and shows the one-PVC rule that surprises many people.

## Bind an existing PVC

A PVC asks the cluster for storage of a given size and access mode. In the playground, the default StorageClass `standard` creates the matching volume as a folder on the node the first time a pod uses the claim. The access mode `ReadWriteOnce` (RWO) lets pods on one node mount it for writing; the playground has one node, so every step pod can use it.

<!-- astrona:playground:renew -->

Save this as `pvc-logbook.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: logbook
  namespace: starfleet
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 64Mi
```

Apply it:

```sh
kubectl apply -f pvc-logbook.yaml
kubectl get pvc logbook -n starfleet
```

The claim shows `Pending`. The StorageClass waits for the first pod that uses the claim before it creates the volume, so that the volume lands on the same node as the pod.

The `Task` below appends one line to `log.txt` in its workspace and reports how many lines the file has. With an `emptyDir` the count would always be `1`.

Save this as `task-log-entry.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: log-entry
  namespace: starfleet
spec:
  params:
    - name: entry
      type: string
  workspaces:
    - name: logbook
      description: Holds log.txt, which keeps every entry
  results:
    - name: entries
  steps:
    - name: append
      image: busybox:1.37.0
      env:
        - name: ENTRY
          value: $(params.entry)
      script: |
        #!/bin/sh
        set -eu
        echo "$ENTRY" >> "$(workspaces.logbook.path)/log.txt"
        echo "claim: $(workspaces.logbook.claim)"
        printf '%s' "$(grep -c . "$(workspaces.logbook.path)/log.txt")" | tee "$(results.entries.path)"
```

Apply it, and run it twice against the PVC. `tkn` uses `claimName=` for a PVC binding, and `subPath=` to limit it to one folder:

```sh
kubectl apply -f task-log-entry.yaml
tkn task start log-entry -n starfleet -p entry="scout departed" -w name=logbook,claimName=logbook,subPath=scout --showlog
tkn task start log-entry -n starfleet -p entry="scout returned" -w name=logbook,claimName=logbook,subPath=scout --showlog
```

The first run prints `claim: logbook` and `1`, the second `2`: the file survived the first pod. `subPath: scout` mounts only the folder `scout` of the volume. The kubelet creates that folder if it does not exist yet, so a typing error in `subPath` gives a new, empty folder instead of an error. Run it once more with `subPath=shuttle` and the count starts again at `1`.

## A new PVC for each run

Sharing one PVC between runs is what you want for a logbook, and often what you do not want for a build. Two runs that write the same folder can mix their files, and a run triggered by an untrusted change can read what a trusted run left behind. A `volumeClaimTemplate` binding asks Tekton to create a fresh PVC for each `TaskRun`.

Save this as `taskrun-log-entry-fresh.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: log-entry-fresh
  namespace: starfleet
spec:
  taskRef:
    name: log-entry
  params:
    - name: entry
      value: probe launched
  workspaces:
    - name: logbook
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 64Mi
```

Apply it:

```sh
kubectl apply -f taskrun-log-entry-fresh.yaml
```

Then check the result:

```sh
kubectl wait --for=condition=Succeeded taskrun/log-entry-fresh -n starfleet --timeout=120s
kubectl get pvc -n starfleet -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,OWNER:.metadata.ownerReferences[0].name
```

The result `entries` is `1`. Next to `logbook` there is a new claim named `pvc-` and a short hash, owned by the `TaskRun` `log-entry-fresh`. The tekton-pipelines-controller created it from the template. Because the `TaskRun` owns it, Kubernetes deletes the claim when you delete the `TaskRun`:

```sh
kubectl delete taskrun log-entry-fresh -n starfleet
kubectl get pvc -n starfleet
```

Only `logbook` is left.

## One PVC per TaskRun

Tekton has a feature called the Affinity Assistant, controlled by the key `coschedule` in the ConfigMap `feature-flags`. Its default value is `workspaces`. In that mode, the tekton-pipelines-controller refuses a `TaskRun` that binds two different PVCs, because it cannot promise that both volumes can be mounted on the same node. The run fails with `TaskRunValidationFailed`, and the message says that more than one PersistentVolumeClaim is bound. A `volumeClaimTemplate` counts as a PVC too.

There are two clean ways around it. Bind both workspaces to the same claim with different `subPath` values, or bind the workspace that does not need to persist to an `emptyDir`. Changing `coschedule` is a cluster-wide decision for an administrator, not a fix for one `Task`.

You can now keep files between runs with a PVC, limit a workspace to one folder with `subPath`, isolate runs with a `volumeClaimTemplate`, and stay inside the one-PVC rule. With `emptyDir`, ConfigMap, Secret and PVC bindings, you can give any `Task` the files it needs.

## Common pitfalls

> [!WARNING]
> - **A wrong `subPath`.** The kubelet creates the missing folder, and the run succeeds on an empty folder. Check the path when results look too small.
> - **Two different PVCs in one `TaskRun`.** With the default `coschedule: workspaces`, the run fails with `TaskRunValidationFailed`. Use one claim with two `subPath` values, or an `emptyDir`.
> - **`readOnly` on a workspace the `Task` writes to.** Tekton mounts the volume read-only, and the write fails with a read-only file system error.
> - **Expecting a `volumeClaimTemplate` PVC to stay.** It belongs to the `TaskRun` and goes away with it.
> - **Sharing one PVC between trusted and untrusted runs.** Every run that mounts it can read and change its files.

## Your mission: Bind Workspaces To A TaskRun

You can now bind a PVC with a `subPath`, a ConfigMap and a Secret to the workspaces of a `Task`, and you know which of them are read-only, optional or isolated. The graded lab gives you a `Task` with three workspaces and the data for them, and asks you to write the `TaskRun` that binds them so that the roster lands in the right folder of the PVC.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-125-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-125-lab-020-01
astrona start ats-125-playground-020-01
```
