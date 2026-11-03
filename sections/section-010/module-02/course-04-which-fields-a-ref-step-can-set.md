# Which Fields A ref Step Can Set

A Task that uses a `StepAction` hands over the control of what runs. The image, the script and the environment belong to the `StepAction`, so every Task that uses it runs the same code. The Task still needs some control: how long the step may run, how much memory it gets, what happens when it fails. This part lists what a step with `ref` can and cannot set, and shows how a Task gets a `StepAction` from Git instead of from the cluster.

## What the Task can set

A step with `ref` can set these fields:

- `params`, to pass values to the `StepAction`.
- `timeout`, the longest time the step may run.
- `onError`, which is `continue` or `stopAndFail`, to decide if a failure stops the Task.
- `computeResources`, the requests and limits of the step container.
- `envFrom`, `securityContext`, `imagePullPolicy`, `workspaces`, `volumeDevices`, `stdoutConfig` and `stderrConfig`.

<!-- astrona:playground:renew -->

The Task below limits one step. It needs a `StepAction`, so first save this as `stepaction-compose-line.yaml`. It declares two parameters and one step result named `line`:

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

Then save this as `task-limits.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: limits
  namespace: starfleet
spec:
  steps:
    - name: compose
      ref:
        name: compose-line
      params:
        - name: message
          value: limited
      timeout: 2m
      onError: continue
      computeResources:
        requests:
          cpu: 50m
          memory: 32Mi
        limits:
          memory: 64Mi
```

Apply it and run it:

```sh
kubectl apply -f task-limits.yaml
tkn task start limits -n starfleet --showlog
```

The step prints `log: limited`. Look at the container of the pod to see that the limits arrived:

```sh
kubectl get pods -n starfleet -l tekton.dev/task=limits -o jsonpath='{.items[0].spec.containers[?(@.name=="step-compose")].resources}{"\n"}'
```

The memory limit of `64Mi` and the request of `32Mi` are on the container, although the `StepAction` does not mention them.

## What the Task cannot set

A step with `ref` cannot set `image`, `command`, `args`, `script`, `env` or `volumeMounts`. These fields define what the step runs, and the `StepAction` owns them. The webhook rejects a Task that sets any of them. Try it with a server-side dry run, which asks the webhook without storing the Task:

```sh
kubectl apply --dry-run=server -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: too-much
  namespace: starfleet
spec:
  steps:
    - name: compose
      ref:
        name: compose-line
      image: busybox:1.37.0
YAML
```

The command fails with an error that names the field `image`. If a Task needs different code, it writes its own step, or it uses a different `StepAction`. The Task also cannot change the environment of the `StepAction`. A value that must differ goes in as a parameter, which the `StepAction` puts into its own `env`.

## Get a StepAction from outside the cluster

So far `ref.name` names a `StepAction` in the same namespace. A step can also name a resolver. A resolver is a Tekton component that fetches a definition from a source other than the namespace. The Git resolver reads a file from a Git repository, and its parameters are `url`, `revision` and `pathInRepo`:

```yaml
steps:
  - name: clone
    ref:
      resolver: git
      params:
        - name: url
          value: https://github.com/example/steps.git
        - name: revision
          value: main
        - name: pathInRepo
          value: stepactions/clone.yaml
```

The resolvers run in the namespace `tekton-pipelines-resolvers`. The set of available resolver types depends on the cluster. A `TaskRun` that uses a resolver needs network access to the source, and a wrong path makes the run fail before the pod starts, as a wrong `ref.name` does.

You can now decide what a Task controls in a step that uses a `StepAction`, and what stays fixed. With that you can write a Task that is made of reusable steps.

## Common pitfalls

> [!WARNING]
> - **Setting `script` or `env` next to `ref`.** The webhook rejects the step. Pass a parameter instead.
> - **Expecting the `stepTemplate` to apply.** Fixed fields of the `StepAction` stay as they are, so keep settings for the step in the step itself.
> - **A branch name in `revision` for a Git `StepAction`.** The content changes when the branch moves. Use a tag or a commit for steps that must not change.
> - **`onError: continue` hiding a failure.** The `TaskRun` can end as succeeded while the step failed. Read the exit code of the step in `status.steps`.

## Your mission: Write A Task From A StepAction

You can now write a `StepAction`, pass it parameters and read its results. The graded lab gives you a `StepAction` that is already in the cluster, and asks you to write the Task that uses it, expose its result and run it.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-125-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-125-lab-010-02
astrona start ats-125-playground-010-02
```
