# Return Results From A StepAction

A step often has to give a value to the rest of the Task: the name of a file it created, a version it found, a digest it computed. A `StepAction` returns values as step results. This part writes a step result in a `StepAction`, reads it in a later step, and copies it into a Task result so that the `TaskRun` reports it.

## Declare and write a step result

A `StepAction` lists its results under `results`, each with a `name` and an optional `description`. In the script, the file `$(step.results.<name>.path)` is where the step writes the value. Tekton reads the file when the step ends. As with Task results, a newline at the end of the file becomes part of the value, so write the value with `printf '%s'`.

<!-- astrona:playground:renew -->

Save this as `stepaction-compose-line.yaml`:

```yaml
apiVersion: tekton.dev/v1beta1
kind: StepAction
metadata:
  name: compose-line
  namespace: starfleet
spec:
  params:
    - name: prefix
      type: string
      default: "log"
    - name: message
      type: string
  results:
    - name: line
      description: The finished log line
  env:
    - name: PREFIX
      value: $(params.prefix)
    - name: MESSAGE
      value: $(params.message)
  image: busybox:1.37.0
  script: |
    #!/bin/sh
    set -eu
    printf '%s: %s' "$PREFIX" "$MESSAGE" | tee "$(step.results.line.path)"
```

Apply it:

```sh
kubectl apply -f stepaction-compose-line.yaml
```

The `tee` command prints the value to the log and writes it to the result file at the same time.

## Read the result in a later step and in the Task

A later step reads the result of an earlier step with `$(steps.<step name>.results.<result name>)`. The substitution works in `env`, `command` and `args`. It does not work inside a `script`, so a step passes it to the script through `env`. A Task result takes the same value with `value`, and then the `TaskRun` reports it in `status.results`.

Save this as `task-log-entry.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: log-entry
  namespace: starfleet
spec:
  params:
    - name: message
      type: string
  results:
    - name: entry
      description: The line the first step composed
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
    - name: check
      image: busybox:1.37.0
      env:
        - name: ENTRY
          value: $(steps.compose.results.line)
      script: |
        #!/bin/sh
        set -eu
        echo "The line has ${#ENTRY} characters"
```

Apply it and run it:

```sh
kubectl apply -f task-log-entry.yaml
tkn task start log-entry -n starfleet -p message="engines online" --showlog
```

The step `compose` prints `launch: engines online`. The step `check` prints the length of that line. Read the result that the `TaskRun` reports:

```sh
kubectl get taskrun -n starfleet -l tekton.dev/task=log-entry -o jsonpath='{.items[0].status.results[0].name}{"=["}{.items[0].status.results[0].value}{"]"}{"\n"}'
```

The brackets show that the value is `launch: engines online` and ends without a newline.

## Where the result is written

A step result from a `StepAction` lives in a file on the volume that Tekton shares between the steps, in the folder `/tekton/steps`. A Task result lives in `/tekton/results`. When the Task result uses `value: $(steps.compose.results.line)`, the controller copies the step result into the Task result after the pod ends. The step does not write the Task result file itself.

This also explains a limit. A step result is only available once its step has finished, so a step can use the results of the steps before it, not of steps after it.

You now know how a `StepAction` hands a value back and how a Task reports it. The open question is which parts of such a step the Task is still allowed to change.

## Common pitfalls

> [!WARNING]
> - **`echo` into the result file.** The newline becomes part of the value. Use `printf '%s'`.
> - **Reading `$(steps.compose.results.line)` inside a `script`.** The substitution is not allowed there. Use `env`.
> - **Reading a result from a later step.** A step only sees the results of the steps before it.
> - **Writing to `$(results.line.path)` in a `StepAction`.** That is the path of a Task result. A `StepAction` writes `$(step.results.line.path)`.
