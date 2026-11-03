# Debugging Patterns

Most failures in a Task come from a short list of causes. Knowing the list saves time, because you can test each cause in order instead of reading every log. This part covers the three most common: files that are not shared between steps, steps that end before you can look inside, and runs whose pod is gone.

## Which folders are shared between steps

Each step is its own container, with its own file system. Files that a step writes outside a mounted volume are lost when the step ends. Tekton mounts one folder in every step of the pod: `/workspace`, which is an `emptyDir` volume that lives as long as the pod. Tekton also mounts `/tekton/results` for results and the folder `/tekton/home` as the home folder. Everything else, including `/tmp`, belongs to one step only.

<!-- astrona:playground:renew -->

Save this as `task-share-test.yaml`. The first step writes to two places, and the second step reads both:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: share-test
  namespace: starfleet
spec:
  steps:
    - name: write
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        echo "in tmp" > /tmp/note.txt
        echo "in workspace" > /workspace/note.txt
    - name: read
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        ls -l /workspace/note.txt
        ls -l /tmp/note.txt || echo "no note in /tmp"
```

```sh
kubectl apply -f task-share-test.yaml
tkn task start share-test -n starfleet --showlog
```

The step `read` finds the file in `/workspace` and reports that `/tmp/note.txt` does not exist. When a step cannot find a file that an earlier step made, the file is most likely in a folder that is not shared. Move it to `/workspace`, or to a declared workspace or volume.

## Look inside a failing step

A step that fails ends its container, so you cannot open a shell in it. Two ways help. First, add a debug step before the failing one that prints what you need: the environment, a listing, the file the next step will read. Second, replace the failing command with `sleep 600` in a copy of the Task and run it; while the step sleeps, open a shell in its container:

```sh
kubectl exec -it POD_NAME -n starfleet -c step-NAME -- sh
```

Replace `POD_NAME` and `NAME` with the pod and the step. Use the copy only for debugging, and delete it after.

## Keep the pod to read it later

A finished pod stays in the namespace until its `TaskRun` is deleted, so you can read the logs of a failed run after the fact with `tkn taskrun logs` or `kubectl logs`. Two things remove it earlier: a timeout or a cancel, which delete the pod, and a cleanup job that removes old runs. For runs that you need to debug after a timeout, add a step that copies what you need to a workspace or sends it to an external system.

You can now test the three usual causes in order: a folder that is not shared, a step you cannot inspect, a pod that is gone.

## Common pitfalls

> [!WARNING]
> - **Writing intermediate files to `/tmp`.** The next step does not see them. Use `/workspace` or a declared workspace.
> - **Leaving a `sleep` step in a Task.** It holds the pod for its full time. Remove it after debugging.
> - **Running `kubectl exec` on a finished step.** The container has ended. The pod is only a record then.
> - **Debugging on the shared Task.** Change a copy, so other runs are not affected.

## Your mission: Diagnose A Failing Archive Task

You can now read the status of a run, find the failed step and its exit code, and fix a file that is not shared between steps. The graded lab gives you a failed run of a Task, and asks you to record the diagnosis and fix the Task.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-125-playground-040-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-040/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-125-lab-040-02
astrona start ats-125-playground-040-02
```
