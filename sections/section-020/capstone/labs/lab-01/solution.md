# Solution: Repair The Workspaces Of A Report Task

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: `deck-report-run` binds `report-data` with the `subPath` `reports` as its only PersistentVolumeClaim (PVC) and succeeded; `reports/history.txt` keeps the old lines, has the new one and matches the result `entries`; and the Task declares `output` writable and still works with empty volumes.

## Step 1: Read the first failure

Start with the TaskRun:

```sh
kubectl get taskrun deck-report-run -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{.status.conditions[0].message}{"\n"}'
kubectl get pods -n starfleet -l tekton.dev/taskRun=deck-report-run
```

The reason is `TaskRunValidationFailed`, and the message says that more than one PersistentVolumeClaim is bound. There is no pod. The feature flag `coschedule` is `workspaces` by default, and in that mode the tekton-pipelines-controller accepts only one PVC per TaskRun. The TaskRun binds `output` to `report-data` and `cache` to `report-cache`.

Nothing in `cache` needs to persist, so an `emptyDir` is the right volume for it. An `emptyDir` lives as long as the pod and is shared by all its steps.

## Step 2: Read the second failure

A started TaskRun cannot be edited, so delete it. Keep the wrong `subPath` for now, to see one fault at a time:

```sh
kubectl delete taskrun deck-report-run -n starfleet
```

Save this as `taskrun-deck-report-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: deck-report-run
  namespace: starfleet
spec:
  taskRef:
    name: deck-report
  params:
    - name: run-date
      value: "2026-10-15"
  workspaces:
    - name: output
      persistentVolumeClaim:
        claimName: report-data
      subPath: report
    - name: config
      configMap:
        name: report-config
    - name: cache
      emptyDir: {}
```

Apply it:

```sh
kubectl apply -f taskrun-deck-report-run.yaml
```

Then check the result after a few seconds:

```sh
kubectl get taskrun deck-report-run -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{range .status.steps[*]}{.name}{" exit "}{.terminated.exitCode}{"\n"}{end}'
kubectl logs deck-report-run-pod -n starfleet -c step-append
```

The reason is now `StepFailed`. `render` ended with exit code `0`, and `append` failed. Its log says that `history.txt` is on a read-only file system. Look at the workspace declarations of the Task:

```sh
kubectl get task deck-report -n starfleet -o jsonpath='{range .spec.workspaces[*]}{.name}{" readOnly="}{.readOnly}{"\n"}{end}'
```

`output` is declared `readOnly: true`, so Tekton mounts its volume read-only in every step. The Task writes to `output`, so the declaration is wrong. `config` holds settings only and stays read-only.

## Step 3: Make output writable

Save this as `task-deck-report.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: deck-report
  namespace: starfleet
spec:
  description: Adds one report line for a deck to history.txt and counts the lines.
  params:
    - name: run-date
      type: string
      description: The date of the report, for example 2026-10-15
  workspaces:
    - name: output
      description: Holds history.txt, which keeps every report line
    - name: config
      description: Report settings from a ConfigMap. The key deck names the deck.
      readOnly: true
    - name: cache
      description: Scratch space between the steps. Nothing in it needs to persist.
  results:
    - name: entries
      description: The number of lines in history.txt after this run
  steps:
    - name: render
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        set -eu
        deck="$(cat "$(workspaces.config.path)/deck")"
        echo "$(params.run-date) $deck: ok" > "$(workspaces.cache.path)/line.txt"
        cat "$(workspaces.cache.path)/line.txt"
    - name: append
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        set -eu
        cat "$(workspaces.cache.path)/line.txt" >> "$(workspaces.output.path)/history.txt"
        printf '%s' "$(grep -c . "$(workspaces.output.path)/history.txt")" > "$(results.entries.path)"
```

Apply it, and run the same TaskRun again:

```sh
kubectl apply -f task-deck-report.yaml
kubectl delete taskrun deck-report-run -n starfleet
kubectl apply -f taskrun-deck-report-run.yaml
kubectl wait --for=condition=Succeeded taskrun/deck-report-run -n starfleet --timeout=120s
```

Then check the result:

```sh
kubectl get taskrun deck-report-run -n starfleet -o jsonpath='{.status.results[?(@.name=="entries")].value}{"\n"}'
```

The run succeeds, but `entries` is `1`, not `3`. This is the fault that does not fail the run.

## Step 4: Find the third fault

The `subPath` of `output` is `report`, but the history lives in `reports`. The kubelet creates a missing `subPath` folder on the volume, so the Task wrote a new `history.txt` with one line into a new folder `report`. Read the PVC with a small TaskRun of your own to see both folders.

Save this as `taskrun-list-report-data.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: list-report-data-
  namespace: starfleet
spec:
  workspaces:
    - name: data
      persistentVolumeClaim:
        claimName: report-data
  taskSpec:
    workspaces:
      - name: data
        readOnly: true
    steps:
      - name: list
        image: busybox:1.37.0
        script: |
          #!/bin/sh
          ls -lR "$(workspaces.data.path)"
          tail -n +1 "$(workspaces.data.path)"/*/history.txt
```

Create it (`kubectl apply` does not accept `generateName`):

```sh
kubectl create -f taskrun-list-report-data.yaml
```

The command prints the generated name; read its log with it in place of `<NAME>`:

```sh
kubectl logs <NAME>-pod -n starfleet -c step-list
```

The log shows `reports/history.txt` with the two old lines and `report/history.txt` with the one new line.

## Step 5: Run it with the right subPath

In `taskrun-deck-report-run.yaml`, change `subPath: report` to `subPath: reports`, then create the TaskRun again:

```sh
kubectl delete taskrun deck-report-run -n starfleet
kubectl apply -f taskrun-deck-report-run.yaml
kubectl wait --for=condition=Succeeded taskrun/deck-report-run -n starfleet --timeout=120s
kubectl get taskrun deck-report-run -n starfleet -o jsonpath='{.status.results[?(@.name=="entries")].value}{"\n"}'
```

It prints `3`. Create the listing TaskRun once more if you want to see the new line at the end of `reports/history.txt`. The stray folder `report` does no harm.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set the feature flag `coschedule` to `disabled` | The run starts, but the constraint forbids changing feature flags; the cache does not need a PVC at all |
| Bind `cache` with a `volumeClaimTemplate` | Tekton still counts it as a second PVC, and the grader forbids new PVCs |
| Remove `readOnly` from `config` too | The grader requires `config` to stay read-only |
| Copy the line into `reports/history.txt` by hand | The constraint forbids it, and `entries` of the TaskRun would not match the file |
| Run the TaskRun many times | Every run adds a line; that is fine, as long as `entries` matches the file |

## Common mistakes

- Looking for a pod when the reason is `TaskRunValidationFailed`. The controller refused the run before it created one.
- Trusting a green run. A wrong `subPath` gives a valid, empty folder, and the run succeeds with the wrong data.
- Binding `subPath` in the Task. It belongs to the TaskRun binding.

## Practice on your own

- Bind both `output` and `cache` to `report-data` with two different `subPath` values, and check that the controller accepts it.
- Bind `cache` with a `volumeClaimTemplate` while `output` uses an `emptyDir`, and watch the PVC that Tekton creates disappear when you delete the TaskRun.
- Make the step `append` print `$(workspaces.output.claim)` and `$(workspaces.cache.claim)`.
