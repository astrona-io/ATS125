# Solution: Repair A Task Built From Steps, Parameters And Results

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: `crew-manifest-run` uses the Task with the right parameters, ran its three steps and succeeded; its results are `crew-count` = `3` and `summary` = `engineering: 3 crew members`; and the Secret is unchanged while a grader run with other values gives the right results.

## Step 1: Read the first failure

Start with the TaskRun:

```sh
kubectl get taskrun crew-manifest-run -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{.status.conditions[0].message}{"\n"}'
```

The reason is `CreateContainerConfigError`, and the message says that the pod could not be created because of a configuration error. This time a pod exists, but one of its containers never started. The kubelet, the Kubernetes agent on the node, writes the cause into the state of that container:

```sh
kubectl get pod crew-manifest-run-pod -n starfleet -o jsonpath='{range .status.containerStatuses[*]}{.name}{": "}{.state.waiting.reason}{" "}{.state.waiting.message}{"\n"}{end}'
```

The container `step-report` waits with `CreateContainerConfigError`, and its message says that the key `token` was not found in the Secret `starfleet/report-token`. Look at the keys the Secret really has:

```sh
kubectl get secret report-token -n starfleet -o jsonpath='{.data}{"\n"}'
```

The only key is `api-token`. The step `report` reads `REPORT_TOKEN` with `secretKeyRef` key `token`. The constraint says the Secret stays as it is, so the fix is in the Task: use the key `api-token`.

## Step 2: Read the second failure

Fix only that line for now, apply the Task and run it again. Edit the Task in place:

```sh
kubectl edit task crew-manifest -n starfleet
```

Change `key: token` to `key: api-token` under the step `report` and save. A started TaskRun cannot run again, so delete it:

```sh
kubectl delete taskrun crew-manifest-run -n starfleet
```

Save this as `taskrun-crew-manifest-run.yaml`, the same TaskRun as before:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: crew-manifest-run
  namespace: starfleet
spec:
  taskRef:
    name: crew-manifest
  params:
    - name: crew
      value:
        - bridge
        - scout
        - shuttle
    - name: deck
      value: engineering
```

Apply it:

```sh
kubectl apply -f taskrun-crew-manifest-run.yaml
```

Then check the result after a few seconds:

```sh
kubectl get taskrun crew-manifest-run -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{range .status.steps[*]}{.name}{" exit "}{.terminated.exitCode}{" "}{.terminationReason}{"\n"}{end}'
kubectl logs crew-manifest-run-pod -n starfleet -c step-collect
```

The reason is now `StepFailed`. `collect` ended with a non-zero exit code, and `measure` and `report` show the termination reason `Skipped`: the entrypoint binary did not start them, because the step before them failed. The log of `step-collect` comes from `env`, which says that it cannot execute `bash`. The script starts with `#!/usr/bin/env bash`, and the image `busybox:1.37.0` has no `bash`. The script uses nothing that needs `bash`, so `#!/bin/sh` works.

## Step 3: Read the third fault

Change the shebang the same way, delete the TaskRun and apply the file again:

```sh
kubectl edit task crew-manifest -n starfleet
kubectl delete taskrun crew-manifest-run -n starfleet
kubectl apply -f taskrun-crew-manifest-run.yaml
kubectl wait --for=condition=Succeeded taskrun/crew-manifest-run -n starfleet --timeout=120s
```

Then check the results:

```sh
kubectl get taskrun crew-manifest-run -n starfleet -o jsonpath='{range .status.results[*]}{.name}{"="}{.value}{"\n"}{end}'
```

The run succeeds, and `crew-count` is `3`, but `summary` is `bridge: 3 crew members` instead of `engineering: 3 crew members`. The step `report` prints `$DECK`, and the `stepTemplate` sets `DECK` to the fixed value `bridge`. The parameter `deck` never reaches it. Tekton replaces `$(params.deck)` in the `stepTemplate` too, so the value of `DECK` should be `$(params.deck)`.

## Step 4: Apply the whole fixed Task

Save this as `task-crew-manifest.yaml`. It holds all three fixes:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: crew-manifest
  namespace: starfleet
spec:
  description: Writes a crew manifest, counts it and reports the result.
  params:
    - name: crew
      type: array
      description: The crew members, one per item
    - name: deck
      type: string
      description: The deck the crew works on
      default: bridge
  results:
    - name: crew-count
      description: How many crew members are on the manifest
      value: $(steps.measure.results.lines)
    - name: summary
      description: One line about the deck and its crew
  stepTemplate:
    env:
      - name: DECK
        value: $(params.deck)
  steps:
    - name: collect
      image: busybox:1.37.0
      args: ["$(params.crew[*])"]
      script: |
        #!/bin/sh
        set -eu
        for member in "$@"; do
          echo "$member" >> /workspace/manifest.txt
        done
        echo "Collected $# crew members for $DECK"
    - name: measure
      image: busybox:1.37.0
      results:
        - name: lines
          type: string
          description: The number of lines in the manifest
      script: |
        #!/bin/sh
        set -eu
        printf '%s' "$(grep -c . /workspace/manifest.txt)" > "$(step.results.lines.path)"
    - name: report
      image: busybox:1.37.0
      env:
        - name: COUNT
          value: $(steps.measure.results.lines)
        - name: REPORT_TOKEN
          valueFrom:
            secretKeyRef:
              name: report-token
              key: api-token
      script: |
        #!/bin/sh
        set -eu
        if [ -z "$REPORT_TOKEN" ]; then
          echo "REPORT_TOKEN is empty" >&2
          exit 1
        fi
        printf '%s: %s crew members' "$DECK" "$COUNT" | tee "$(results.summary.path)"
```

Apply it:

```sh
kubectl apply -f task-crew-manifest.yaml
```

## Step 5: Run it once more

Create the TaskRun again so it runs the fixed Task:

```sh
kubectl delete taskrun crew-manifest-run -n starfleet
kubectl apply -f taskrun-crew-manifest-run.yaml
kubectl wait --for=condition=Succeeded taskrun/crew-manifest-run -n starfleet --timeout=120s
```

Then check the results:

```sh
kubectl get taskrun crew-manifest-run -n starfleet -o jsonpath='{range .status.results[*]}{.name}{"="}{.value}{"\n"}{end}'
```

It prints `crew-count=3` and `summary=engineering: 3 crew members`.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add the key `token` to the Secret | The run starts, but the grader requires the Secret to keep only `api-token` |
| Use an image with `bash` for `collect` | It works, but the grader requires `busybox:1.37.0`; `#!/bin/sh` is enough for this script |
| Set `DECK` to `engineering` in the `stepTemplate` | The result is right for this run, but the grader's run with `deck` = `hangar` reports the wrong deck |
| Write `crew-count` to `$(results.crew-count.path)` in `measure` | The grader requires the result to keep its `value` from the step result `lines` |
| Use `$(steps.measure.results.lines)` inside the script of `report` | The webhook rejects the Task: step results can only be used in `env`, `command` and `args` |

## Common mistakes

- Looking for a step log when the reason is `CreateContainerConfigError`. The container never started, so its state message holds the cause.
- Reading a `Skipped` step as a failed step. Only the first failed step has the real error; the steps after it never ran.
- Forgetting that the old TaskRun keeps the old Task in `status.taskSpec`. Create the TaskRun again after each change.

## Practice on your own

- Make `report` read the token with `envFrom` and a `secretRef` instead of `valueFrom`, and print the names of its environment variables.
- Add a fourth step that reads `$(steps.measure.results.lines)` through `args` and prints it.
- Mark the Secret key as optional with `optional: true` under `secretKeyRef`, break the key name again, and see how the run behaves now.
