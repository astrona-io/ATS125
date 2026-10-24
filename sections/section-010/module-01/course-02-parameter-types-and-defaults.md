# Parameters: Types, Defaults And Safe Substitution

A `Task` that prints a fixed line is not much use. A build `Task` needs the image name, a test `Task` needs the list of tests, and a deploy `Task` needs the target. Parameters carry those values from the `TaskRun` into the `Task`. This part shows the three parameter types, how defaults work, where Tekton lets you use each type, and how to pass a value into a script without surprises.

## Declare, pass and use a parameter

A parameter is a named input value. The `Task` declares it under `spec.params`, with a `name`, an optional `type`, `description` and `default`. The `TaskRun` passes values under its own `spec.params`. A step uses the value as `$(params.<name>)`: the tekton-pipelines-controller replaces that text in the step before it creates the pod.

The `Task` below declares one parameter of each type. `crew` is a `string` without a default, so every `TaskRun` must pass it. `deck` is a `string` with a default. `checks` is an `array`, a list of strings.

<!-- astrona:playground:renew -->

Save this as `task-preflight.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: preflight
  namespace: starfleet
spec:
  params:
    - name: crew
      type: string
      description: The crew member who runs the checks
    - name: deck
      type: string
      description: The deck to check
      default: bridge
    - name: checks
      type: array
      description: The systems to check, one per item
      default: ["engines", "shields"]
  steps:
    - name: run-checks
      image: busybox:1.37.0
      env:
        - name: CREW
          value: $(params.crew)
        - name: DECK
          value: $(params.deck)
      args: ["$(params.checks[*])"]
      script: |
        #!/bin/sh
        set -eu
        echo "$CREW checks $# systems on $DECK"
        for check in "$@"; do
          echo "- $check"
        done
```

Apply it:

```sh
kubectl apply -f task-preflight.yaml
```

Now pass only the required value. With `tkn`, `-p` sets a parameter; an array takes its items separated by commas:

```sh
tkn task start preflight -n starfleet -p crew=scout --use-param-defaults --showlog
tkn task start preflight -n starfleet -p crew=pilot -p deck=engineering -p checks=engines,sensors,doors --showlog
```

The first run prints `scout checks 2 systems on bridge`: both defaults applied. The second prints `pilot checks 3 systems on engineering` and one line per check.

## Where each type may appear

A `string` parameter can go almost anywhere in a step: `image`, `env`, `workingDir`, `args`, `script`. An `array` parameter is stricter. Tekton expands `$(params.checks[*])` into several items of a list, so the reference must be a whole item of `command` or `args` on its own, like `["$(params.checks[*])"]` above. A `script` then reads the items as `$1`, `$2` and so on, and `$#` holds their number. The webhook rejects an array reference inside `script`, `env` or `image`.

The third type, `object`, groups named keys, for example the `url` and `revision` of a Git repository. It needs a `properties` list in the declaration, and a step reads one key as `$(params.<name>.<key>)`. You meet it less often than the other two.

Values that do not fit the declaration fail the run before a pod exists. Write a `TaskRun` that passes `checks` as one string.

Save this as `taskrun-preflight-string.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: preflight-string
  namespace: starfleet
spec:
  taskRef:
    name: preflight
  params:
    - name: crew
      value: probe
    - name: checks
      value: "engines sensors"
```

Apply it:

```sh
kubectl apply -f taskrun-preflight-string.yaml
```

Then check the result:

```sh
kubectl get taskrun preflight-string -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{.status.conditions[0].message}{"\n"}'
```

The reason is `TaskRunValidationFailed`, and the message says that the parameter types do not match, naming `checks`. In YAML, the right value is a list:

```yaml
    - name: checks
      value:
        - engines
        - sensors
```

A missing value for a parameter without a default fails the same way, with a message that names the missing parameter. Parameter names may hold letters, digits, `-`, `_` and `.`, must start with a letter or `_`, and Tekton compares them without regard to upper or lower case.

## Substitution is plain text

Tekton replaces `$(params.crew)` with the value as plain text. It does not quote or escape anything. Inside a `script`, a value with a space, a quote or a `;` becomes part of the shell code. Compare two ways of printing the same value:

```sh
tkn task start preflight -n starfleet -p crew='scout; echo injected' --use-param-defaults --showlog
```

The step prints `scout; echo injected checks 2 systems on bridge`, because the value reached the script through the environment variable `CREW`, and the shell treats a variable as data. Had the script used `echo "$(params.crew) checks ..."`, Tekton would have pasted the text into the code, and the shell would see the quote marks and the `;` as code. Passing parameters through `env` or `args` keeps them data.

You can now declare `string`, `array` and `object` parameters, give them defaults, pass them with `tkn` or YAML, and read the failure when a value does not match. The open question is the other direction: how a step hands a value back to the `TaskRun`.

## Common pitfalls

> [!WARNING]
> - **An array inside `script`.** The webhook rejects it. Pass the array as its own item of `args` and read `"$@"`.
> - **A string where the `Task` wants an array.** Tekton does not split it. The run fails with `TaskRunValidationFailed` before a pod exists.
> - **Pasting parameters into shell code.** `$(params.x)` is replaced as text. Pass values through `env` and quote the variable.
> - **Two parameters that differ only in case.** `Crew` and `crew` are the same name to Tekton; the webhook rejects the `Task`.
> - **Changing a default and expecting old runs to change.** A `TaskRun` keeps the `Task` it started with in `status.taskSpec`.
