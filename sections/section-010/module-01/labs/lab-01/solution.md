# Solution: Repair A Task's Parameters, Environment And Results

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the TaskRun `image-tag-run` uses the Task `image-tag`, passes `labels` as an array and succeeded; its two results have exactly the expected values; and the Task takes `REGISTRY` from its `stepTemplate` and gives the right results for a grader run with three labels.

## Step 1: Read the Succeeded condition

Start with the TaskRun itself:

```sh
kubectl get taskrun image-tag-run -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{.status.conditions[0].message}{"\n"}'
kubectl get pods -n starfleet -l tekton.dev/taskRun=image-tag-run
```

The reason is `TaskRunValidationFailed`, and the message says that the parameter types do not match and names `labels`. There is no pod: the tekton-pipelines-controller compared the TaskRun with the Task before it created one. Compare the declared type with the value the TaskRun passes:

```sh
kubectl get task image-tag -n starfleet -o jsonpath='{range .spec.params[*]}{.name}{"="}{.type}{"\n"}{end}'
kubectl get taskrun image-tag-run -n starfleet -o jsonpath='{.spec.params[?(@.name=="labels")].value}{"\n"}'
```

The Task declares `labels` with the type `array`. The TaskRun passes one string, `team=bridge tier=web`. Tekton does not split a string into an array; the value must be a YAML list.

## Step 2: Create the TaskRun again with an array

A started TaskRun cannot be edited, so delete it:

```sh
kubectl delete taskrun image-tag-run -n starfleet
```

Save this as `taskrun-image-tag-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: image-tag-run
  namespace: starfleet
spec:
  taskRef:
    name: image-tag
  params:
    - name: app
      value: bridge
    - name: version
      value: "2.1"
    - name: labels
      value:
        - team=bridge
        - tier=web
```

Apply it:

```sh
kubectl apply -f taskrun-image-tag-run.yaml
```

Then check the result after a few seconds:

```sh
kubectl wait --for=condition=Succeeded taskrun/image-tag-run -n starfleet --timeout=120s
kubectl get taskrun image-tag-run -n starfleet -o jsonpath='{range .status.results[*]}{.name}{"=["}{.value}{"]"}{"\n"}{end}'
```

The run now succeeds, but both results are wrong. The square brackets show where each value ends. `image-ref` starts with `localhost:5000` instead of the registry address, and the closing bracket of `label-count` sits on the next line, so the value is `2` followed by a newline.

## Step 3: Let the stepTemplate set REGISTRY

Read the environment of the step `compose`:

```sh
kubectl get task image-tag -n starfleet -o jsonpath='{.spec.stepTemplate.env}{"\n"}{.spec.steps[0].env}{"\n"}'
```

The `stepTemplate` sets `REGISTRY` to `registry.registry.svc.cluster.local:5000`. The step `compose` also sets `REGISTRY`, to `localhost:5000`. Tekton merges the `stepTemplate` into each step by variable name, and the value in the step wins. Remove `REGISTRY` from the step so that the template value applies.

## Step 4: Write the result without a newline

The step `count-labels` writes its result with `echo "$#"`. `echo` adds a newline, and Tekton keeps a result exactly as the step wrote it. `printf '%s'` writes the number without a newline.

Save this as `task-image-tag.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: image-tag
  namespace: starfleet
spec:
  description: Works out the image reference of an app and counts its labels.
  params:
    - name: app
      type: string
      description: The name of the app
    - name: version
      type: string
      description: The version of the app
      default: "1.0"
    - name: labels
      type: array
      description: Labels for the image, one key=value per item
  results:
    - name: image-ref
      description: The full image reference
    - name: label-count
      description: How many labels the image gets
  stepTemplate:
    env:
      - name: REGISTRY
        value: registry.registry.svc.cluster.local:5000
  steps:
    - name: compose
      image: busybox:1.37.0
      env:
        - name: APP
          value: $(params.app)
        - name: VERSION
          value: $(params.version)
      script: |
        #!/bin/sh
        set -eu
        printf '%s/starfleet/%s:%s' "$REGISTRY" "$APP" "$VERSION" | tee "$(results.image-ref.path)"
    - name: count-labels
      image: busybox:1.37.0
      args: ["$(params.labels[*])"]
      script: |
        #!/bin/sh
        set -eu
        for label in "$@"; do
          echo "label: $label"
        done
        printf '%s' "$#" > "$(results.label-count.path)"
```

Apply it:

```sh
kubectl apply -f task-image-tag.yaml
```

## Step 5: Run it once more

The TaskRun kept a copy of the old Task in `status.taskSpec`, so it does not pick up the change. Delete it and create it again from the same file:

```sh
kubectl delete taskrun image-tag-run -n starfleet
kubectl apply -f taskrun-image-tag-run.yaml
kubectl wait --for=condition=Succeeded taskrun/image-tag-run -n starfleet --timeout=120s
```

Then check the results:

```sh
kubectl get taskrun image-tag-run -n starfleet -o jsonpath='{range .status.results[*]}{.name}{"=["}{.value}{"]"}{"\n"}{end}'
```

It prints `image-ref=[registry.registry.svc.cluster.local:5000/starfleet/bridge:2.1]` and `label-count=[2]`, each on one line.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Change `labels` to `type: string` in the Task | The run starts, but the grader requires the array, and `$#` then counts one argument |
| Set `REGISTRY` in `compose` to the right address | The result looks right, but the address now lives in two places; the grader requires the `stepTemplate` only |
| Print `2` in `count-labels` | The result is right for `bridge`, but the grader's run with three labels reports the wrong count |
| Strip the newline with `tr` after reading the result | The value in `status.results` still has the newline; fix the step that writes it |
| Embed the fixed steps with `taskSpec` | The Task `image-tag` stays broken; the grader requires `taskRef` |

## Common mistakes

- Using `$(params.labels[*])` inside `script`. The webhook rejects it: an array can only be used as a whole item of `args` or `command`.
- Expecting `kubectl get ... jsonpath` to show a trailing newline. Put brackets around the value, as above, to see where it ends.
- Changing the Task and expecting the old TaskRun to rerun. A TaskRun never runs twice.

## Practice on your own

- Run the Task with an empty list of labels (`value: []`) and read `label-count`.
- Add a third environment variable to the `stepTemplate` and print it from both steps.
- Set `version` to a value with a space in it and look at what `image-ref` shows.
