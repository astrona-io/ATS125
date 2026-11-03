# Pass Parameters To A StepAction

A `StepAction` that always prints the same text is not useful. A reusable step must accept input: the message to print, the folder to work in, the list of files to check. A `StepAction` takes input through parameters, in the same way a Task does, and the step that uses it passes the values. This part declares parameters in a `StepAction`, passes them from a Task and explains which value wins when there are several.

## Declare parameters and use them through env

A `StepAction` declares `params` with a `name`, a `type` (`string`, `array` or `object`) and an optional `default`. Inside the `StepAction`, `$(params.<name>)` is replaced with the value. As in a Task, Tekton replaces parameters as plain text, so the safe way to give a value to a script is through an environment variable. The script then reads `$MESSAGE`, and a value with quotes or a dollar sign cannot change the script.

<!-- astrona:playground:renew -->

Save this as `stepaction-print-line.yaml`. It replaces any earlier object with this name:

```yaml
apiVersion: tekton.dev/v1beta1
kind: StepAction
metadata:
  name: print-line
  namespace: starfleet
spec:
  params:
    - name: prefix
      type: string
      default: "log"
    - name: message
      type: string
  env:
    - name: PREFIX
      value: $(params.prefix)
    - name: MESSAGE
      value: $(params.message)
  image: busybox:1.37.0
  script: |
    #!/bin/sh
    set -eu
    echo "$PREFIX: $MESSAGE"
```

Apply it:

```sh
kubectl apply -f stepaction-print-line.yaml
```

The parameter `prefix` has a default. The parameter `message` has none, so every step that uses the `StepAction` must pass it.

## Pass values from the Task

The step that uses the `StepAction` passes values with `params`. The values can be fixed text, or they can come from the parameters of the Task, so that the `TaskRun` controls them.

Save this as `task-announce.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: announce
  namespace: starfleet
spec:
  params:
    - name: text
      type: string
      default: "all systems nominal"
  steps:
    - name: with-default-prefix
      ref:
        name: print-line
      params:
        - name: message
          value: $(params.text)
    - name: with-own-prefix
      ref:
        name: print-line
      params:
        - name: prefix
          value: bridge
        - name: message
          value: $(params.text)
```

Apply it and run it with a value from the command line:

```sh
kubectl apply -f task-announce.yaml
tkn task start announce -n starfleet -p text="warp drive ready" --showlog
```

The first step prints `log: warp drive ready`, because `prefix` kept its default. The second prints `bridge: warp drive ready`. The `-p` option of `tkn` sets the parameter `text` of the Task, and the Task hands it to the `StepAction`.

## Which value wins

A parameter of a `StepAction` can get a value from several places. From strongest to weakest, Tekton uses these:

1. A value that the `TaskRun` passes for a parameter of the Task, when the step passes `$(params.<name>)` through.
2. A value that the step sets in its own `params`.
3. A default of the `StepAction` that refers to another parameter.
4. A plain default of the `StepAction`.

For most work the rule is short: a value that a step passes beats the default of the `StepAction`. A parameter without a default and without a value stops the run. Tekton reports the missing parameter in the condition of the `TaskRun`, before any container starts.

Array parameters follow the Task rule. An array can only be a whole item of `args` or `command` in the `StepAction`, as in `args: ["$(params.files[*])"]`. It cannot sit inside a `script`.

You can now make a `StepAction` flexible, pass values from a Task and predict which value applies. The open question is how a `StepAction` hands a value back to the Task.

## Common pitfalls

> [!WARNING]
> - **Writing `$(params.message)` directly in the script.** The value becomes part of the shell code. Pass it through `env`.
> - **A parameter without a default that no step passes.** The run fails before it starts. Add a default, or pass the value.
> - **Passing the wrong parameter name.** A name the `StepAction` does not declare is an error. Compare the names in both objects.
> - **Putting an array in `script`.** An array only works as a whole item of `args` or `command`.
