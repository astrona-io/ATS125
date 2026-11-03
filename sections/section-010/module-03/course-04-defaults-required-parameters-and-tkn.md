# Defaults, Required Parameters And Starting A Task With tkn

A Task is only useful if the people who start it know what it needs. A parameter with a default is optional. A parameter without a default is required, and a run without a value fails. This part reads what a Task asks for, starts it with the `tkn` command-line tool, and shows how defaults and required parameters behave at the start of a run.

## Read what a Task needs

The command `tkn task describe` prints the parameters of a Task with their types, defaults and descriptions. A `description` on a parameter makes that output useful, so write one for every parameter.

<!-- astrona:playground:renew -->

Save this as `task-deploy-note.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: deploy-note
  namespace: starfleet
spec:
  description: Writes a one-line deploy note.
  params:
    - name: app
      type: string
      description: The app that was deployed. Required.
    - name: environment
      type: string
      description: Where the app was deployed.
      default: staging
  results:
    - name: note
  steps:
    - name: write
      image: busybox:1.37.0
      env:
        - name: APP
          value: $(params.app)
        - name: ENVIRONMENT
          value: $(params.environment)
      script: |
        #!/bin/sh
        set -eu
        printf '%s deployed to %s' "$APP" "$ENVIRONMENT" | tee "$(results.note.path)"
```

Apply it and describe it:

```sh
kubectl apply -f task-deploy-note.yaml
tkn task describe deploy-note -n starfleet
```

The output lists `app` as a string parameter with no default and `environment` with the default `staging`.

## Start a Task with tkn

`tkn task start` creates a `TaskRun` from a Task. The option `-p name=value` sets a string parameter. The option `--use-param-defaults` tells `tkn` not to ask for parameters that have a default. The option `--showlog` follows the log until the run ends.

```sh
tkn task start deploy-note -n starfleet -p app=bridge --use-param-defaults --showlog
tkn task start deploy-note -n starfleet -p app=probe -p environment=production --showlog
```

The first run writes `bridge deployed to staging`, using the default. The second writes `probe deployed to production`, because the value from the command line beats the default. Without `--use-param-defaults`, `tkn` asks for the value of each parameter that has a default and waits for input.

## A required parameter without a value

Create a `TaskRun` that leaves out `app`:

```sh
kubectl apply -f - <<'YAML'
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: deploy-note-missing
  namespace: starfleet
spec:
  taskRef:
    name: deploy-note
YAML
kubectl get taskrun deploy-note-missing -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{.status.conditions[0].message}{"\n"}'
```

The run fails before a pod exists, and the message names the parameter `app` as a parameter without a default. This is the cheapest place to find the mistake: no pod, no image pull, no log.

To see what `tkn` would create without running it, add the option `--dry-run`. It prints the `TaskRun` that `tkn` would apply, which is a good way to learn the shape of a `TaskRun` for a Task you did not write.

```sh
tkn task start deploy-note -n starfleet -p app=bridge --dry-run
```

You can now read the contract of a Task, start it with the right values and recognise the failure of a missing parameter at the start. With objects, structured results, context variables and indexes you can write Tasks that take and return real data.

## Common pitfalls

> [!WARNING]
> - **No `description` on parameters.** `tkn task describe` and the dashboard then show a bare name.
> - **A default for a value that must be chosen.** A default hides the need to decide. Leave it out when the caller must supply the value.
> - **Waiting at a `tkn` prompt in a script.** Add `--use-param-defaults` and pass every required parameter with `-p`.
> - **Editing a started `TaskRun` to add a parameter.** The spec of a started run cannot change. Delete it and create a new one.

## Your mission: Write A Task With An Object Parameter And Array Results

You can now declare an object parameter, return array results and use the run name in a result. The graded lab asks you to write one Task that does all three and to run it.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-125-playground-010-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-010/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-125-lab-010-03
astrona start ats-125-playground-010-03
```
