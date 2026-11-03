# Start And Describe With tkn

Writing a `TaskRun` file for every test is slow. The command `tkn task start` creates the `TaskRun` for you, passes parameters and can follow the log. This part starts a Task with parameters, previews the `TaskRun` that `tkn` would create, and lists and describes the runs.

## Start a Task

<!-- astrona:playground:renew -->

Save this as `task-greet.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: greet
  namespace: starfleet
spec:
  params:
    - name: name
      type: string
      default: crew
  steps:
    - name: say
      image: busybox:1.37.0
      env:
        - name: NAME
          value: $(params.name)
      script: |
        #!/bin/sh
        echo "hello $NAME"
```

Apply it and start it with a parameter. The flag `-p` sets a parameter, and `--showlog` follows the log until the run ends:

```sh
kubectl apply -f task-greet.yaml
tkn task start greet -n starfleet -p name=captain --showlog
```

The tool creates a `TaskRun` with a generated name that starts with `greet-run-`, prints the name and the commands to follow it, and then streams the log. To start a Task and use only the defaults of its parameters, add `--use-param-defaults`. Without it, `tkn` asks for each parameter that has no value on the command line, which stops a script.

## Preview before you run

The flag `--dry-run` with `--output yaml` prints the `TaskRun` and creates nothing. This is a quick way to write a `TaskRun` file, or to check what a flag does:

```sh
tkn task start greet -n starfleet -p name=captain --dry-run --output yaml
```

## List and describe

The command `tkn taskrun list` shows the runs of a namespace, newest first, with the age, the duration and the status. Add `--limit` to show fewer and `-o name` to print only names:

```sh
tkn taskrun list -n starfleet
tkn taskrun list -n starfleet -o name
```

The command `tkn taskrun describe` shows one run: its Task, the parameters, the results, the status of each step and any message. Without a name it asks you to pick one; use `--last` to describe the newest run:

```sh
tkn taskrun describe --last -n starfleet
```

The command `tkn task describe greet -n starfleet` shows a Task: its parameters, its steps and its recent runs. All of this is read from the same objects that `kubectl get taskrun -o yaml` prints; `tkn` only formats them.

You can now start, preview, list and describe runs. The open question is how to read the output of a run, and how to clean up.

## Common pitfalls

> [!WARNING]
> - **Starting a Task with a missing parameter in a script.** `tkn` waits for input. Pass `-p` or `--use-param-defaults`.
> - **Forgetting `-n starfleet`.** The tool uses the namespace of the current context and reports no resources.
> - **Treating `--dry-run` as a test.** It creates nothing, so no step runs.
> - **Describing without a name in a script.** The tool asks you to choose. Use `--last` or give the name.
