# Section 030: Step Lifecycle And A Container Build Task

A `Task` is only useful if you can tell how it ended. This section follows a `TaskRun` through its life, shows every way a step can end, and teaches the tools Tekton gives a `Task` to handle a failed step: `onError` and the exit code of each step. It ends with the job most CI/CD pipelines (continuous integration and delivery) end with: building a container image from source code in a workspace and pushing it to a registry.

You first read the `Succeeded` condition and `status.steps` of runs that succeed, fail, skip and time out. Then you let steps fail with `onError: continue` and write a last step that reports and decides the outcome. Last, you build an image with Buildah from a PersistentVolumeClaim, push it to a registry inside the cluster, report its digest as a result, and check that digest against the registry API.

**Topic covered:** Step lifecycle and image builds

## What you will learn

- The reasons of the `Succeeded` condition, and which component sets them.
- Step termination reasons: `Completed`, `Error`, `Skipped`, `Continued`, `TimeoutExceeded`, `Cancelled`.
- Step timeouts against run timeouts, cancelling, pending runs and retries.
- `onError: continue` and `stopAndFail`, and `$(steps.step-<name>.exitCode.path)`.
- A last step that acts as the exit handler of a `Task`.
- Building with Buildah in a normal pod: the `vfs` storage driver, shared storage, pushing over HTTP to a lab registry.
- The results `IMAGE_DIGEST` and `IMAGE_URL`, checked against the registry API.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Control Step Failures And Build An Image

The module starts at its landing page, which also launches the playground. The playground runs Tekton Pipelines v1.17.1, the `tkn` command-line tool, an OCI registry with a client pod, and a PersistentVolumeClaim with the source of a small app.

1. The TaskRun Lifecycle And Step Termination States
2. Handle Step Failures With onError And Exit Codes
3. Build And Push An Image From A Workspace, followed by the lab **Write A Build Task That Pushes To A Registry**
4. Summary

## Section capstone: Repair A Failing Image Build

The capstone is one graded scenario that combines the whole module. The `image-build` Task of the `starfleet` team reports success, yet the registry has no image: Buildah uses a storage driver the pod cannot run, the push asks the HTTP registry for HTTPS, and the last step writes the failure down but never fails the run. Find each fault from `status.steps` and the step logs, fix the Task, and prove both the success path and the failure path. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-125-capstone-030
```
