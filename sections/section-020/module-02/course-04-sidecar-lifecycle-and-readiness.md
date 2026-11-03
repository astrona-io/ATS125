# Sidecar Lifecycle And Readiness

A step that finishes ends. A sidecar that listens on a port never ends by itself. If Tekton did nothing, the pod would run forever and the `TaskRun` would never complete. This part explains how Tekton stops sidecars, what the status of the `TaskRun` shows about them, how a failing sidecar affects the run, and how to wait for a sidecar to be ready.

## Tekton stops the sidecars

When the last step has finished, the tekton-pipelines-controller stops the sidecar containers. It does this by updating the pod and replacing the image of each sidecar with a Tekton image named `nop`. The `nop` image does nothing and exits at once. Kubernetes restarts the container with the new image, and the container ends. After that the pod is complete and the `TaskRun` can report its result.

<!-- astrona:playground:renew -->

You can see the effect after a run. Save this small Task as `task-sidecar-demo.yaml`. Its sidecar serves a folder over HTTP, and its single step only waits one second:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: sidecar-demo
  namespace: starfleet
spec:
  sidecars:
    - name: server
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        mkdir -p /tmp/www
        exec httpd -f -p 8080 -h /tmp/www
  steps:
    - name: wait
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        sleep 1
        echo "step done"
```

Apply it, run it, and read the image of the sidecar container in the finished pod:

```sh
kubectl apply -f task-sidecar-demo.yaml
tkn task start sidecar-demo -n starfleet --showlog
kubectl get pods -n starfleet -l tekton.dev/task=sidecar-demo -o jsonpath='{.items[0].spec.containers[?(@.name=="sidecar-server")].image}{"\n"}'
```

The image name contains `nop`, not `busybox`. This works for any image, but it has a known limit: a sidecar whose command is the same as the command of the `nop` image would keep running. For normal servers it is not a problem.

The status of the `TaskRun` lists sidecars next to steps. Read their names and states:

```sh
kubectl get taskrun -n starfleet -l tekton.dev/task=sidecar-demo -o jsonpath='{range .items[0].status.sidecars[*]}{.name}{" "}{.container}{" "}{.terminated.reason}{"\n"}{end}'
```

The line shows the sidecar `server`, its container `sidecar-server` and the reason it ended. A run whose steps are finished but whose sidecar still shows as running has not completed yet.

## A failing sidecar

A sidecar can fail on its own. A sidecar that exits with an error does not stop the steps, but it can stop the work they do: the step calls the port and gets no answer. When the pod reports that a sidecar was killed for memory, the `TaskRun` ends with the reason `SidecarOOM`, and a sidecar that failed gives the reason `SidecarFailed`. Read the sidecar log first, with `kubectl logs -c sidecar-<name>`.

A sidecar also takes resources. The `TaskRun` can set requests and limits for a sidecar by name, in the same way it does for a step:

```yaml
spec:
  sidecarSpecs:
    - name: server
      computeResources:
        requests:
          cpu: 100m
        limits:
          memory: 128Mi
```

The `sidecarSpecs` field of a `TaskRun` can only set resources, and `name` must match a sidecar of the Task.

## Wait until the sidecar is ready

By default, Tekton does not make a step wait for a sidecar. Two ways exist to handle this. The first is the one you used: a retry loop in the step that calls the sidecar. It works on every cluster and in every setting.

The second uses Kubernetes. The setting `enable-kubernetes-sidecar` in the ConfigMap `feature-flags` makes Tekton run sidecars as Kubernetes native sidecars, which start before the steps and can have a `startupProbe`. With the flag on, a sidecar with a startup probe is ready before the first step starts. The flag is off by default in Tekton Pipelines v1.17.1, and it needs a Kubernetes version that supports native sidecars. Read the current value in your cluster:

```sh
kubectl get configmap feature-flags -n tekton-pipelines -o jsonpath='{.data.enable-kubernetes-sidecar}{"\n"}'
```

The output is `false`. Because a Task may run in a cluster where the flag is off, the retry loop is the safe habit.

You can now explain how a sidecar starts, how Tekton ends it, how to find its logs and status, and how a step waits for it. With volumes and sidecars you can build Tasks that need files and helper processes.

## Common pitfalls

> [!WARNING]
> - **Relying on a startup probe without the flag.** With `enable-kubernetes-sidecar` off, the steps do not wait for the probe. Retry in the step.
> - **Reading the steps for a sidecar failure.** A sidecar writes to its own container log. Use `kubectl logs -c sidecar-<name>`.
> - **A sidecar that never ends and cannot be replaced.** If its command matches the `nop` command, the run times out.
> - **Forgetting the resources of a sidecar.** A sidecar without limits can use the memory of the whole node.

## Your mission: Write A Task With A Sidecar And A Shared Volume

You can now declare a volume, mount it in a step and a sidecar, and reach the sidecar from a step over `localhost`. The graded lab asks you to write a Task that publishes a page through a sidecar and reads it back as a result.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-125-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-125-lab-020-02
astrona start ats-125-playground-020-02
```
