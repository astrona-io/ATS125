# Object Parameters And Their Properties

A Task about a git repository needs a URL, a revision and a folder. A Task about a ship needs a name and a class. Passing each value as its own parameter works, but the Task gets long and the TaskRun must repeat every name. An object parameter groups related values under one name. This part declares an object parameter, passes it from a `TaskRun`, reads single keys and shows what happens when a key is missing.

## Declare the keys

An object parameter has the type `object` and a list of `properties`. Each property is a key with a type, and the only type available for a key is `string`. The list is the contract: Tekton knows which keys exist, and it can check them before the pod starts.

<!-- astrona:playground:renew -->

Save this as `task-ship-info.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: ship-info
  namespace: starfleet
spec:
  params:
    - name: ship
      type: object
      properties:
        name:
          type: string
        class:
          type: string
      default:
        class: scout
  steps:
    - name: show
      image: busybox:1.37.0
      env:
        - name: SHIP_NAME
          value: $(params.ship.name)
        - name: SHIP_CLASS
          value: $(params.ship.class)
      script: |
        #!/bin/sh
        set -eu
        echo "name=$SHIP_NAME class=$SHIP_CLASS"
```

Apply it:

```sh
kubectl apply -f task-ship-info.yaml
```

The default sets only the key `class`. A default may cover some keys of the object and leave the others to the `TaskRun`. Inside the Task, `$(params.ship.name)` is the value of the key `name`. As with other parameters, the values go to the script through `env`.

## Pass the object from a TaskRun

A `TaskRun` writes an object as a YAML map. Keys it leaves out take the value from the default of the Task, when there is one.

Save this as `taskrun-ship-info-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: ship-info-run
  namespace: starfleet
spec:
  taskRef:
    name: ship-info
  params:
    - name: ship
      value:
        name: shuttle
```

Apply it and read the log of the step:

```sh
kubectl apply -f taskrun-ship-info-run.yaml
kubectl wait --for=condition=Succeeded taskrun/ship-info-run -n starfleet --timeout=120s
tkn taskrun logs ship-info-run -n starfleet
```

The log shows `name=shuttle class=scout`. The `TaskRun` gave only `name`, and Tekton took `class` from the default.

## A missing key

Run the Task once more with an object that has a key the Task does not declare, and one that leaves out `name`, which has no default. Save this as `taskrun-ship-info-bad.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: ship-info-bad
  namespace: starfleet
spec:
  taskRef:
    name: ship-info
  params:
    - name: ship
      value:
        class: probe
```

Apply it and read the condition:

```sh
kubectl apply -f taskrun-ship-info-bad.yaml
kubectl get taskrun ship-info-bad -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{.status.conditions[0].message}{"\n"}'
```

The run fails before a pod exists. The tekton-pipelines-controller compared the object with the declared keys, found that `name` has no value, and reported a validation failure. The message names the parameter.

You now know how an object groups values, how a default fills the gaps and how a missing key fails the run early. The open question is how a Task returns more than one value, which needs array and object results.

## Common pitfalls

> [!WARNING]
> - **Not declaring `properties`.** An object parameter without a list of keys is rejected.
> - **A key that is not a string.** The type of every key is `string`. Numbers go in as text.
> - **Using `$(params.ship)` as a whole in a script.** Read single keys, and pass them through `env`.
> - **Expecting the default to fill every key.** A key without a value in the default and in the `TaskRun` stops the run.
