# Context Variables And Array Indexing

A Task sometimes needs facts about its own run: the name of the `TaskRun`, the namespace, a unique id for a file name. Tekton provides them as `context` variables. A Task also often needs one item of a list rather than the whole list. This part uses the `context` variables, then indexes an array parameter, and explains where each kind of variable may appear.

## Context variables

The tekton-pipelines-controller replaces these variables before the pod starts:

| Variable | Value |
| --- | --- |
| `$(context.taskRun.name)` | The name of the `TaskRun` |
| `$(context.taskRun.namespace)` | The namespace of the `TaskRun` |
| `$(context.taskRun.uid)` | The unique id of the `TaskRun` object |
| `$(context.task.name)` | The name of the Task |
| `$(context.taskRun.retry-count)` | How many times the `TaskRun` has been retried, starting at 0 |

<!-- astrona:playground:renew -->

Save this as `task-who-am-i.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: who-am-i
  namespace: starfleet
spec:
  results:
    - name: identity
  steps:
    - name: show
      image: busybox:1.37.0
      env:
        - name: RUN_NAME
          value: $(context.taskRun.name)
        - name: RUN_NAMESPACE
          value: $(context.taskRun.namespace)
        - name: TASK_NAME
          value: $(context.task.name)
      script: |
        #!/bin/sh
        set -eu
        printf '%s/%s/%s' "$RUN_NAMESPACE" "$TASK_NAME" "$RUN_NAME" | tee "$(results.identity.path)"
```

Apply it and run it twice. Each run gets its own generated name:

```sh
kubectl apply -f task-who-am-i.yaml
tkn task start who-am-i -n starfleet --showlog
tkn task start who-am-i -n starfleet --showlog
```

Each log shows `starfleet/who-am-i/` followed by the name that `tkn` generated for that run. The same Task gives different values in different runs, because the variable belongs to the run, not to the Task.

## Index an array parameter

An array parameter can be used as a whole, or one item at a time. `$(params.files[*])` is the whole array and works only as an item of `args` or `command`. `$(params.files[0])` is the first item, counting from zero, and works in places where a string is allowed, such as `env`.

Save this as `task-first-and-all.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: first-and-all
  namespace: starfleet
spec:
  params:
    - name: files
      type: array
      default: ["alpha.txt", "beta.txt"]
  steps:
    - name: show
      image: busybox:1.37.0
      env:
        - name: FIRST
          value: $(params.files[0])
      args: ["$(params.files[*])"]
      script: |
        #!/bin/sh
        set -eu
        echo "first=$FIRST count=$#"
        for item in "$@"; do echo "item: $item"; done
```

Apply it and run it:

```sh
kubectl apply -f task-first-and-all.yaml
tkn task start first-and-all -n starfleet --use-param-defaults --showlog
```

The log shows `first=alpha.txt count=2` and one `item:` line for each file. The step receives the whole array as its arguments and the first item in the environment.

## Keep indexes inside the array

An index that is larger than the last item of the array is an error. Index 1 of a list with one item does not exist, and the step cannot use it. Give an array parameter a default that is long enough for every index the Task reads, or check the number of items with `$#` in the script before it reads an item by position.

The same care applies to object keys: a key that the object does not declare cannot be read, and the run stops before it starts.

You now have the variables that tie a Task to its run and to its parameters. The open question is what happens when a value is missing altogether, and how to start a Task from the command line with the right values.

## Common pitfalls

> [!WARNING]
> - **`$(params.files[*])` in `env` or `script`.** The whole array only works as an item of `args` or `command`.
> - **Counting from 1.** The first item is index 0.
> - **`$(context.taskRun.name)` in a Task that never runs as a `TaskRun`.** The variable is filled when a run starts.
> - **Using the run name as a stable id.** It changes with every run. Use it for logs and file names.
