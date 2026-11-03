# Solution: Write A Task From A StepAction

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the Task `launch-log` uses the `StepAction` with `ref` and exposes `entry`; the TaskRun `launch-log-run` succeeded with the exact result; and a grader run with another message reports the matching line.

## Step 1: Read the StepAction

```sh
kubectl get stepaction compose-line -n starfleet -o jsonpath='{range .spec.params[*]}{.name}{" default="}{.default}{"\n"}{end}{.spec.results[*].name}{"\n"}'
```

It has the parameters `prefix` (default `log`) and `message` (no default), and the result `line`.

## Step 2: Write the Task

The step passes `prefix` and `message`. The Task result `entry` takes the value of the step result with `value`.

Save this as `task-launch-log.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: launch-log
  namespace: starfleet
spec:
  params:
    - name: message
      type: string
  results:
    - name: entry
      description: The line the step composed
      value: $(steps.compose.results.line)
  steps:
    - name: compose
      ref:
        name: compose-line
      params:
        - name: prefix
          value: launch
        - name: message
          value: $(params.message)
```

Apply it:

```sh
kubectl apply -f task-launch-log.yaml
```

## Step 3: Run it

Save this as `taskrun-launch-log-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: launch-log-run
  namespace: starfleet
spec:
  taskRef:
    name: launch-log
  params:
    - name: message
      value: engines online
```

Apply it and wait for the end:

```sh
kubectl apply -f taskrun-launch-log-run.yaml
kubectl wait --for=condition=Succeeded taskrun/launch-log-run -n starfleet --timeout=120s
kubectl get taskrun launch-log-run -n starfleet -o jsonpath='{range .status.results[*]}{.name}{"=["}{.value}{"]"}{"\n"}{end}'
```

It prints `entry=[launch: engines online]`.

## Step 4: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Copy the script of the `StepAction` into the Task | The grader requires `ref` and no `script` in the step |
| Type `engines online` into the step | The grader run with another message reports the wrong line |
| Add `image` next to `ref` | The webhook rejects the Task |
| Skip the `prefix` parameter | The line starts with `log`, not `launch` |

## Common mistakes

- Reading `$(steps.compose.results.line)` inside a `script`. Use `env`, or `value` in a Task result.
- Writing the Task result with the name of the step result. The names can differ; `value` connects them.

## Practice on your own

- Add a second step that prints the line, passed through `env`.
- Give the step a `timeout` and `computeResources`.
