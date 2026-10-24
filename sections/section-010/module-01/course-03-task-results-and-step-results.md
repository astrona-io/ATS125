# Results From Tasks And From Steps

Parameters carry values into a `Task`; results carry short values out of it. A build `Task` reports the digest of the image it pushed, a clone `Task` reports the commit it checked out, and a later tool reads those values from the `TaskRun` instead of from a log. Tekton has two kinds of results: Task results, which end up in the status of the `TaskRun`, and step results, which pass a value from one step to a later step. This part shows both and the limits that come with them.

## A Task result

A result is a small named output. The `Task` declares it under `spec.results`. A step writes the value to the file `$(results.<name>.path)`, which is `/tekton/results/<name>` inside every step container. When the step ends, the entrypoint binary reads the file and puts the value into the container's termination message, a short text that Kubernetes keeps in the container status. The tekton-pipelines-controller copies it from there to `status.results` of the `TaskRun`.

The `Task` below writes two results. `image-ref` comes from parameters, and `tag-count` from an array parameter.

<!-- astrona:playground:renew -->

Save this as `task-tag-info.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: tag-info
  namespace: starfleet
spec:
  params:
    - name: app
      type: string
    - name: tags
      type: array
  results:
    - name: image-ref
      description: Where the first tag of the app lives
    - name: tag-count
      description: How many tags the app gets
  steps:
    - name: compose
      image: busybox:1.37.0
      env:
        - name: APP
          value: $(params.app)
      args: ["$(params.tags[*])"]
      script: |
        #!/bin/sh
        set -eu
        printf 'registry.example/starfleet/%s:%s' "$APP" "$1" > "$(results.image-ref.path)"
        echo "$#" > "$(results.tag-count.path)"
```

Apply it, and run it:

```sh
kubectl apply -f task-tag-info.yaml
tkn task start tag-info -n starfleet -p app=scout -p tags=1.0,latest --showlog
```

`tkn` prints the name of the new `TaskRun`. Read its results with brackets around each value, using that name in place of `<NAME>`:

```sh
kubectl get taskrun <NAME> -n starfleet -o jsonpath='{range .status.results[*]}{.name}{"=["}{.value}{"]"}{"\n"}{end}'
```

`image-ref` is `registry.example/starfleet/scout:1.0`, inside one pair of brackets. The closing bracket of `tag-count` sits on the next line: the value is `2` and a newline, because `echo` adds one. Tekton keeps a result exactly as the step wrote it, so write results with `printf '%s'`.

## Size and type limits

Results travel through termination messages, and Kubernetes keeps at most 4096 bytes of termination messages for one pod. All results of the pod share that space, and Tekton also uses part of it for its own data, so the more steps a `Task` has, the less room each one gets. A result is for a digest, a commit or a short status, never for a file. Files belong in a workspace.

A result can also have `type: array` or `type: object`. The step then writes JSON to the file, for example `["1.0","latest"]` for an array, and Tekton checks it. A result that a `Task` declares but never writes does not fail the `TaskRun` by itself.

## Step results

Sometimes one step only needs to hand a value to the next step, and the `TaskRun` does not need to show it. A step result does that. The step declares `results` itself and writes to `$(step.results.<name>.path)`, with `step` in the singular. A later step reads the value as `$(steps.<step-name>.results.<name>)`, with `steps` in the plural. A Task result can also take its value from a step result with `value:`, so that the `TaskRun` shows it after all.

Save this as `task-crew-count.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: crew-count
  namespace: starfleet
spec:
  params:
    - name: crew
      type: array
  results:
    - name: count
      description: How many crew members were given
      value: $(steps.measure.results.lines)
    - name: summary
      description: One line about the crew
  steps:
    - name: measure
      image: busybox:1.37.0
      args: ["$(params.crew[*])"]
      results:
        - name: lines
          type: string
      script: |
        #!/bin/sh
        set -eu
        printf '%s' "$#" > "$(step.results.lines.path)"
    - name: report
      image: busybox:1.37.0
      env:
        - name: COUNT
          value: $(steps.measure.results.lines)
      script: |
        #!/bin/sh
        set -eu
        printf '%s crew members are ready' "$COUNT" | tee "$(results.summary.path)"
```

Apply it, and run it:

```sh
kubectl apply -f task-crew-count.yaml
tkn task start crew-count -n starfleet -p crew=bridge,scout,shuttle --showlog
```

The log of `report` prints `3 crew members are ready`, and the `TaskRun` has the results `count` = `3` and `summary`. Note where the step result is used: in `env` of `report`. A later step may use a step result in `env`, `command` and `args` only. The webhook rejects `$(steps.measure.results.lines)` inside a `script`, so pass it through an environment variable, as above.

You can now return values from a `Task`, keep them free of stray newlines, stay inside the size limit, and pass a value from one step to the next. With steps, parameters and results you can read and repair most `Task` definitions. The open question is how a `Task` reads and writes real files, which needs workspaces.

## Common pitfalls

> [!WARNING]
> - **`echo` into a result file.** The newline becomes part of the value. Use `printf '%s'`.
> - **Large results.** All results of a pod share 4096 bytes of termination messages. Put files in a workspace.
> - **`step.results` and `steps.<name>.results` mixed up.** A step writes to `$(step.results.<name>.path)`; a later step reads `$(steps.<name>.results.<name>)`.
> - **A step result inside `script`.** The webhook rejects it. Use `env`, `args` or `command`.
> - **Reading results from the log.** The log and `status.results` are separate; only the result file counts.

## Your mission: Repair A Task's Parameters, Environment And Results

You can now read a step's environment and its `stepTemplate`, pass string and array parameters, and write results that hold exactly the value you mean. The graded lab gives you a `Task` and a `TaskRun` with three faults across those three topics, and asks you to repair them until the run reports two exact results.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-125-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-125-lab-010-01
astrona start ats-125-playground-010-01
```
