# Solution: Write A Task With An Object Parameter And Array Results

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the Task declares the object parameter and the three results; the TaskRun `ship-card-run` succeeded with the exact results; and a grader run with another ship reports its own values.

## Step 1: Write the Task

The object keys reach the script through `env`. The array result is JSON. The run name comes from `$(context.taskRun.name)`.

Save this as `task-ship-card.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: ship-card
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
  results:
    - name: card
      type: string
    - name: tags
      type: array
    - name: run-name
      type: string
  steps:
    - name: build
      image: busybox:1.37.0
      env:
        - name: SHIP_NAME
          value: $(params.ship.name)
        - name: SHIP_CLASS
          value: $(params.ship.class)
        - name: RUN_NAME
          value: $(context.taskRun.name)
      script: |
        #!/bin/sh
        set -eu
        printf '%s/%s' "$SHIP_NAME" "$SHIP_CLASS" > "$(results.card.path)"
        printf '["%s","%s"]' "$SHIP_NAME" "$SHIP_CLASS" > "$(results.tags.path)"
        printf '%s' "$RUN_NAME" > "$(results.run-name.path)"
```

Apply it:

```sh
kubectl apply -f task-ship-card.yaml
```

## Step 2: Run it

Save this as `taskrun-ship-card-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: ship-card-run
  namespace: starfleet
spec:
  taskRef:
    name: ship-card
  params:
    - name: ship
      value:
        name: bridge
        class: flagship
```

Apply it, wait, and read the results:

```sh
kubectl apply -f taskrun-ship-card-run.yaml
kubectl wait --for=condition=Succeeded taskrun/ship-card-run -n starfleet --timeout=120s
kubectl get taskrun ship-card-run -n starfleet -o jsonpath='{range .status.results[*]}{.name}{"=["}{.value}{"]"}{"\n"}{end}'
```

The line for `card` holds `bridge/flagship`, the line for `tags` holds the JSON list with the items `bridge` and `flagship`, and the line for `run-name` holds `ship-card-run`. Each value sits between the brackets with no newline.

## Step 3: Submit

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Type `ship-card-run` as the run name | The grader run has another name and reports the wrong `run-name` |
| Type `bridge/flagship` into the script | The grader run with another ship reports the wrong card |
| Declare `tags` as a string | The grader requires the type `array` |
| Write the tags with `echo` and no JSON | The run fails, because an array result must be JSON |

## Common mistakes

- Declaring the object without `properties`. The webhook rejects it.
- Using `$(params.ship)` as a whole in the script.
- Leaving a result file empty. An empty array `[]` counts as unset.

## Practice on your own

- Add a third key `crew` and a result that counts the characters of its value.
- Add an object result with the keys `name` and `class`.
