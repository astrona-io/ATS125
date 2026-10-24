# Summary

A `TaskRun` tells you how it ended in two places: its `Succeeded` condition and the record of each step. Read together, they show which step failed, how, and whether the run was allowed to go on. With that, a build `Task` can fail loudly and clearly instead of quietly.

## What you learned

The tekton-pipelines-controller moves a `TaskRun` through the reasons `Started`, `Pending` and `Running` while the `Succeeded` condition is `Unknown`. It ends with `True` and `Succeeded`, or with `False` and a reason such as `StepFailed`, `TaskRunValidationFailed`, `TaskRunTimeout` or `TaskRunCancelled`. Each step leaves `terminated.exitCode` and a `terminationReason` in `status.steps`: `Completed`, `Error`, `Skipped` for steps after a failure, `Continued`, `TimeoutExceeded` or `Cancelled`. A step `timeout` is enforced inside the container and keeps the pod; the run timeout and a cancel make the controller delete the pod.

`onError: continue` lets a step fail without ending the run; the step shows `Continued` and keeps its real exit code. The entrypoint binary writes the exit code of each step to a file that a later step reads through `$(steps.step-<name>.exitCode.path)`. A last step can act as the exit handler of a `Task`: it writes a status and exits with a non-zero code when an earlier step failed, so the run ends with `StepFailed`. For clean-up across whole Tasks, Pipelines have `finally`.

Buildah builds images in a normal pod with `--storage-driver=vfs`, and two steps share its storage through a Task volume at `/var/lib/containers`. A push to the lab registry needs `--tls-verify=false`, which belongs in a lab only. `--digestfile` gives the digest for `IMAGE_DIGEST`, and the registry API proves it: `/v2/<repository>/tags/list` and the `Docker-Content-Digest` header of a manifest request with an `Accept` header. The key facts to remember are these:

- Find the first step with `Error` or `TimeoutExceeded`; `Skipped` steps never ran.
- `onError: continue` alone can turn a failed build green.
- The exit code variable uses the container name: `step-<name>`.
- Trust the digest in the registry, not the tag.

<!-- astrona:playground:destroy -->
