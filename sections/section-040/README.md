# Section 040: Run And Debug Tasks

A Task describes the work. A `TaskRun` decides how that work runs, and `tkn` and the status of the run show what happened. A Task that works in a test can hang for an hour, fail once on a busy network, or fail in a way nobody can find without reading the status in the right order.

This section teaches the controls of a `TaskRun` and the tools to debug it. You first set timeouts and retries, cancel a run and hold one back in the pending state, and set resources, the service account and pod settings from the `TaskRun`. Then you start, list, describe and delete runs with `tkn`, read logs per step, and read the status and termination reasons down to the exit code of one step.

**Topic covered:** TaskRun settings and debugging

## What you will learn

- The `timeout` of a `TaskRun` and of a step, its default, and the reason `TaskRunTimeout`.
- `retries`, `status.retriesStatus` and `$(context.taskRun.retry-count)`.
- Cancelling a run with `spec.status` and `tkn taskrun cancel`, and the pending state.
- `stepSpecs`, `sidecarSpecs`, `serviceAccountName` and `podTemplate`.
- `tkn task start`, `tkn taskrun list`, `describe`, `logs` and `delete`.
- Step termination reasons and exit codes in `status.steps`.
- Why `/workspace` is shared between steps and `/tmp` is not.

## The learning path

The section has two modules. Each has a landing page, four short parts, a graded lab right after the last part, and a summary. Each module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Control How A TaskRun Runs

The playground runs Tekton Pipelines v1.17.1, the `tkn` command-line tool and an empty namespace `starfleet`.

1. Timeouts For A TaskRun And For A Step
2. Retries And The Retry Count
3. Cancel And Pending Runs
4. Resources, Service Account And Pod Settings, followed by the lab **Fix A Failing TaskRun With Timeout And Retries**
5. Summary

### 2. Run And Debug Tasks With tkn

The playground has the same tools and an empty namespace `starfleet`.

1. Start And Describe With tkn
2. Logs And Cleanup
3. Reading Status And Termination Reasons
4. Debugging Patterns, followed by the lab **Diagnose A Failing Archive Task**
5. Summary

## Section capstone: Rescue A Night Of Report Runs

The capstone is one graded scenario that combines both modules. The `nightly-report` Task of the `starfleet` team has three runs that need attention: one timed out, one was started with a delay of an hour and still runs, and one waits in the pending state. Read why the first failed, cancel the second, release the third, and create a safe run that survives a failed first attempt with retries, a timeout and a memory limit. Work it after the module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-125-capstone-040
```
