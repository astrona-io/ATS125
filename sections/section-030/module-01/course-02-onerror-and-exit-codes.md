# Handle Step Failures With onError And Exit Codes

By default, the first failing step ends a `TaskRun`: the steps after it are skipped. That is often right, and sometimes it is not. A test step may fail while you still want its report uploaded, and a build may fail while you still want a clear status written for the people who wait for it. Tekton has no separate "exit handler" for a `Task`. Instead it has `onError` on each step, and a file with the exit code of each step that later steps can read. This part builds a final step that always runs and decides the outcome itself.

## onError: continue

`onError` is a field of a step with two values. `stopAndFail` is the default behaviour: a non-zero exit code fails the step, skips the rest and fails the run. `continue` tells the entrypoint binary to record the real exit code and let the next step start as if the step had passed. The step then shows the termination reason `Continued`, and its `terminated.exitCode` in `status.steps` still holds the real code.

The `Task` below runs a test that fails, with `onError: continue`, and a step after it.

<!-- astrona:playground:renew -->

Save this as `task-systems-test.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: systems-test
  namespace: starfleet
spec:
  params:
    - name: result
      type: string
      description: The exit code the test step should end with
      default: "1"
  results:
    - name: verdict
  steps:
    - name: test
      image: busybox:1.37.0
      onError: continue
      script: |
        #!/bin/sh
        echo "running the systems test"
        exit "$(params.result)"
    - name: upload
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        echo "uploading the test report"
```

Apply it, and run it:

```sh
kubectl apply -f task-systems-test.yaml
tkn task start systems-test -n starfleet --use-param-defaults --showlog
```

Read the status with the name `tkn` printed in place of `<NAME>`:

```sh
kubectl get taskrun <NAME> -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{range .status.steps[*]}{.name}{" exit "}{.terminated.exitCode}{" "}{.terminationReason}{"\n"}{end}'
```

The reason is `Succeeded`. `test` shows exit code `1` and `Continued`, and `upload` ran and shows `Completed`. The run is green although the test failed. That is the danger of `onError: continue` used alone: the failure is recorded in `status.steps`, but the `Succeeded` condition no longer shows it.

## Read the exit code of an earlier step

The entrypoint binary writes the exit code of each step that ended normally or with `onError: continue` to a file under `/tekton/steps`. A later step reads it through the variable `$(steps.step-<step-name>.exitCode.path)`. Note the `step-` in front of the step name: the variable uses the name of the step container. A step without a name is `step-unnamed-<index>`.

With that file, the last step of a `Task` can act as its exit handler: it always runs, because every step before it has `onError: continue`, it writes a status that people can read, and it ends with a non-zero exit code when an earlier step failed. Because it is the step that fails, the `TaskRun` ends with `False` and the reason `StepFailed`, and the earlier steps keep their `Continued` record.

Save this as `task-systems-test.yaml`, replacing the earlier version:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: systems-test
  namespace: starfleet
spec:
  params:
    - name: result
      type: string
      description: The exit code the test step should end with
      default: "1"
  results:
    - name: verdict
  steps:
    - name: test
      image: busybox:1.37.0
      onError: continue
      script: |
        #!/bin/sh
        echo "running the systems test"
        exit "$(params.result)"
    - name: upload
      image: busybox:1.37.0
      onError: continue
      script: |
        #!/bin/sh
        echo "uploading the test report"
    - name: verdict
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        set -u
        test_code="$(cat "$(steps.step-test.exitCode.path)")"
        upload_code="$(cat "$(steps.step-upload.exitCode.path)")"
        if [ "$test_code" = "0" ] && [ "$upload_code" = "0" ]; then
          printf 'passed' | tee "$(results.verdict.path)"
          exit 0
        fi
        printf 'failed: test exit %s, upload exit %s' "$test_code" "$upload_code" | tee "$(results.verdict.path)"
        exit 1
```

Apply it, and run it with a failing and with a passing test:

```sh
kubectl apply -f task-systems-test.yaml
tkn task start systems-test -n starfleet --use-param-defaults --showlog
tkn task start systems-test -n starfleet -p result=0 --showlog
```

Read both runs with the command above. The first ends with `StepFailed`: `test` shows `Continued` with exit code `1`, `upload` shows `Completed`, and `verdict` shows exit code `1`. Its log and the result `verdict` say `failed: test exit 1, upload exit 0`, so the run is red and explains why. The second run ends with `Succeeded`, and `verdict` is `passed`.

## Where this pattern stops

This pattern works inside one `Task`, with three limits. The exit code file exists only for steps that ended normally or with `onError: continue`; a step that failed without it has no file, and every later step is skipped anyway. A step that ran past its own `timeout` fails the run even when it has `onError: continue`. And if the pod disappears, through a run timeout or a cancel, no step runs at all. When a clean-up must run whatever happens to a whole `Task`, it belongs in the `finally` section of a `Pipeline`, which runs Tasks after the others end.

A result written before a step fails is kept too. If a step with `onError: continue` writes a result and then exits with a non-zero code, the `TaskRun` still reports that result.

You can now let steps fail without ending the run, read their exit codes in a later step, and use a final step to write a status and decide the outcome. The open question is a real job for this pattern: building and pushing an image, where you want to know exactly which part failed.

## Common pitfalls

> [!WARNING]
> - **`onError: continue` without a final check.** The run shows `Succeeded` while a step failed. Read `status.steps`, or make the last step fail the run.
> - **`$(steps.test.exitCode.path)`.** The variable needs the container name: `$(steps.step-test.exitCode.path)`.
> - **Expecting the exit handler step after a failed step without `onError`.** That step is `Skipped`. Every step before the handler needs `onError: continue`.
> - **Using `set -e` in the handler and reading a missing file.** The handler stops before it writes its status. Read the codes first, then decide.
