# Write A StepAction And Use It With ref

A Task that clones a repository, one that builds an image and one that runs tests all start with the same few lines of shell. When the lines are copied into every Task, a fix must be made in every copy, and some copies are forgotten. A `StepAction` moves the step into one object that all Tasks share. This part writes the smallest `StepAction`, uses it from a Task and shows what Tekton does with the reference.

## One step in its own object

A `StepAction` is a Kubernetes object of the kind `StepAction`. In Tekton Pipelines v1.17.1 it is served as `tekton.dev/v1beta1`, and the feature is stable. Its `spec` looks like a step: it needs an `image`, and it has a `script` or a `command`. It has no `name` of its own inside the spec, because the object name is the name.

<!-- astrona:playground:renew -->

Save this as `stepaction-print-line.yaml`:

```yaml
apiVersion: tekton.dev/v1beta1
kind: StepAction
metadata:
  name: print-line
  namespace: starfleet
spec:
  image: busybox:1.37.0
  script: |
    #!/bin/sh
    set -eu
    echo "Hello from the StepAction print-line"
```

Apply it and list it:

```sh
kubectl apply -f stepaction-print-line.yaml
kubectl get stepaction -n starfleet
```

The list shows one object, `print-line`. Nothing runs yet. A `StepAction` is only a definition, as a `Task` is only a definition until a `TaskRun` starts.

## Use the StepAction from a Task

A Task uses a `StepAction` with the field `ref`. The step keeps its own `name`, and `ref.name` is the name of the `StepAction`. The step has no `image` and no `script`, because they come from the `StepAction`.

Save this as `task-use-print-line.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: use-print-line
  namespace: starfleet
spec:
  steps:
    - name: first
      ref:
        name: print-line
    - name: second
      ref:
        name: print-line
```

Apply it and start it with `tkn`, which creates a `TaskRun` and follows its logs:

```sh
kubectl apply -f task-use-print-line.yaml
tkn task start use-print-line -n starfleet --showlog
```

The log shows the greeting twice, once from the step `first` and once from the step `second`. Both steps run the same `StepAction`, in two containers of one pod.

## When the reference is resolved

The reference is not checked when you apply the Task. The tekton-pipelines-controller looks up the `StepAction` when a `TaskRun` starts, in the namespace of the `TaskRun`. You can prove it. Apply a Task that refers to a name that does not exist:

```sh
kubectl apply -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: missing-action
  namespace: starfleet
spec:
  steps:
    - name: lost
      ref:
        name: does-not-exist
YAML
```

The Task is accepted. Now start a run of it and read the condition of the `TaskRun`:

```sh
tkn task start missing-action -n starfleet
kubectl get taskrun -n starfleet -l tekton.dev/task=missing-action -o jsonpath='{.items[0].status.conditions[0].reason}{"\n"}{.items[0].status.conditions[0].message}{"\n"}'
```

The run fails before a pod exists, because the controller could not get the `StepAction`. The message names the object it could not find. A run that fails in this way never started a container, so there are no step logs to read.

The same rule gives you a useful property. A `TaskRun` copies the resolved step into its status when it starts. If you change the `StepAction` afterwards, runs that already started keep the old step, and new runs get the new one.

You can now write a `StepAction`, use it from a Task and read the failure that a wrong name causes. The open question is how one `StepAction` can behave differently for different Tasks, which needs parameters.

## Common pitfalls

> [!WARNING]
> - **`image` next to `ref` in a step.** The webhook rejects a step that has both. The image belongs to the `StepAction`.
> - **A `StepAction` in another namespace.** A plain `ref.name` looks in the namespace of the `TaskRun`. Apply the `StepAction` to the same namespace.
> - **Expecting an error when you apply the Task.** A wrong `ref.name` only fails when a `TaskRun` starts.
> - **Editing a `StepAction` and expecting old runs to change.** A started run keeps the step it resolved.
