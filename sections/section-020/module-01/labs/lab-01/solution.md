# Solution: Bind Workspaces To A TaskRun

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: `crew-roster-run` binds the three workspaces as asked and succeeded; its results are `bridge: 3 crew members` and `signed` = `true`; and `roster.txt` and `roster.sig` are in the folder `bridge` of the PersistentVolumeClaim (PVC) `roster-data`.

## Step 1: Read what the Task needs

A `Task` declares its workspaces; a `TaskRun` binds each one to a real volume. List the declarations:

```sh
kubectl get task crew-roster -n starfleet -o jsonpath='{range .spec.workspaces[*]}{.name}{" readOnly="}{.readOnly}{" optional="}{.optional}{" mountPath="}{.mountPath}{"\n"}{end}'
kubectl get task crew-roster -n starfleet -o jsonpath='{range .spec.steps[*]}{.name}{" uses "}{.workspaces[*].name}{"\n"}{end}'
```

`source` is a normal, writable workspace. `settings` is read-only and mounted at `/etc/roster`. `token` is optional, and only the step `sign` mounts it. The step `build-roster` reads `crew.txt` straight from the top of `source`.

## Step 2: Look at the data

Check that the PVC, the ConfigMap and the Secret exist:

```sh
kubectl get pvc roster-data -n starfleet
kubectl get configmap roster-settings -n starfleet -o jsonpath='{.data}{"\n"}'
kubectl get secret roster-token -n starfleet -o jsonpath='{.data}{"\n"}'
```

The PVC is `Bound`. The ConfigMap has the key `deck` with the value `bridge`, and the Secret has the key `token`. Each key becomes a file in the mounted folder. The crew list of the `bridge` deck sits in the folder `bridge` of the PVC, so the binding needs `subPath: bridge`. Without it, the Task looks for `crew.txt` at the top of the volume and fails.

## Step 3: Write the TaskRun

Save this as `taskrun-crew-roster-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: crew-roster-run
  namespace: starfleet
spec:
  taskRef:
    name: crew-roster
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: roster-data
      subPath: bridge
    - name: settings
      configMap:
        name: roster-settings
    - name: token
      secret:
        secretName: roster-token
```

Apply it:

```sh
kubectl apply -f taskrun-crew-roster-run.yaml
```

Then check the result:

```sh
kubectl wait --for=condition=Succeeded taskrun/crew-roster-run -n starfleet --timeout=120s
kubectl get taskrun crew-roster-run -n starfleet -o jsonpath='{range .status.results[*]}{.name}{"="}{.value}{"\n"}{end}'
```

It prints `roster=bridge: 3 crew members` and `signed=true`.

## Step 4: Check which step saw which workspace

The pod of the TaskRun shows how Tekton mounted the volumes:

```sh
kubectl get pod crew-roster-run-pod -n starfleet -o jsonpath='{range .spec.containers[*]}{.name}{": "}{range .volumeMounts[*]}{.mountPath}{" "}{end}{"\n"}{end}'
```

Both step containers mount `/workspace/source` and `/etc/roster`. Only `step-sign` mounts `/workspace/token`, because the Task isolates that workspace to the step `sign`.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Bind `source` without `subPath` | `build-roster` cannot find `crew.txt` at the top of the volume, and the run fails |
| Leave out the `token` binding | The run succeeds because `token` is optional, but `signed` is `false` |
| Bind `source` to an `emptyDir` and copy the file in | `roster.txt` disappears with the pod; the grader looks for it in the PVC |
| Bind `settings` to the Secret | `deck` is missing, and the run fails |
| Remove `readOnly` from `settings` | The grader requires the Task to stay unchanged |

## Common mistakes

- Writing `secretName` under `configMap`, or `name` under `secret`. A ConfigMap binding uses `name`; a Secret binding uses `secretName`, as in a pod volume.
- Giving the `subPath` in the Task. `subPath` belongs to the binding in the TaskRun.
- Expecting `roster.txt` in the folder `scout`. The `subPath` limits the workspace to `bridge`.

## Practice on your own

- Create a second TaskRun with `subPath: scout` and compare its `roster` result.
- Create a TaskRun without the `token` binding and read `signed`.
- Bind `source` with a `volumeClaimTemplate` instead, run it, and list the PVCs in `starfleet` before and after you delete that TaskRun.
