# Reading Status And Termination Reasons

A log tells you what a step printed. The status tells you what happened to the step: whether it started, how it ended and with which exit code. When a run fails, the fastest path to the cause is to read the status in order: first the condition of the run, then the state of each step. This part reads both.

## The condition of the run

<!-- astrona:playground:renew -->

Save this as `task-exit-codes.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: exit-codes
  namespace: starfleet
spec:
  steps:
    - name: ok
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        echo "fine"
    - name: broken
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        echo "something is wrong"
        exit 7
    - name: skipped
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        echo "never runs"
```

Apply it, start it and read the condition:

```sh
kubectl apply -f task-exit-codes.yaml
tkn task start exit-codes -n starfleet --showlog
RUN=$(tkn taskrun list -n starfleet --limit 1 -o name | head -n 1 | cut -d/ -f2)
kubectl get taskrun "$RUN" -n starfleet -o jsonpath='{.status.conditions[0].status}{" "}{.status.conditions[0].reason}{"\n"}{.status.conditions[0].message}{"\n"}'
```

The status is `False` and the reason is `Failed`. The message names the step and the exit code, in the form `"step-broken" exited with code 7`, and gives the container name. For a failed step the condition is the first place to look, because the message already answers the question for most failures.

Other reasons you can meet are `TaskRunTimeout`, `TaskRunCancelled`, `TaskRunImagePullFailed` for an image that cannot be pulled, and `CreateContainerConfigError` for a container the cluster could not create, such as a missing Secret.

## The state of each step

The list `status.steps` has one entry per step, with a `terminated` or `waiting` state. Print the name, the reason and the exit code of each:

```sh
kubectl get taskrun "$RUN" -n starfleet -o jsonpath='{range .status.steps[*]}{.name}{" reason="}{.terminated.reason}{" exit="}{.terminated.exitCode}{"\n"}{end}'
```

The step `ok` has the reason `Completed` and the exit code 0. The step `broken` has the reason `Error` and the exit code 7. The step `skipped` did not run, because Tekton stops the later steps after a failure. Read its entry to see how your version marks it, and rely on the step with the first non-zero exit code. A step killed for using more memory than its limit shows the reason `OOMKilled` and the exit code 137.

The command `tkn taskrun describe` prints the same data as a table, with the status of each step. When you need to build a script around the failure, read it with `jsonpath` as above.

You can now find which step failed and why. The open question is what usually causes the failure.

## Common pitfalls

> [!WARNING]
> - **Reading only the last lines of the log.** A step that fails early hides behind steps that never ran. Read the condition message first.
> - **Trusting the exit code 0 of the Task.** A script without `set -e` can fail a command and still exit 0. Add `set -eu`.
> - **Treating `OOMKilled` as a bug in the script.** The limit is too low for the work. Raise it with `stepSpecs`.
> - **Ignoring the step order.** Steps run in order, and a failure stops the later steps.
