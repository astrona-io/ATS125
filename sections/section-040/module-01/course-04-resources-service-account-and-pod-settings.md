# Resources, Service Account And Pod Settings

The same Task can run in different places: a developer cluster with little memory, a production cluster with strict security rules, a namespace where pulling images needs credentials. The Task should not change for each place. The `TaskRun` holds the settings that belong to the place: resources, the service account, and the settings of the pod. This part sets each of them.

## Resources for steps and sidecars

A Task step can set `computeResources`, but a `TaskRun` can override them by name with `stepSpecs`, and for sidecars with `sidecarSpecs`. Each entry has a `name` and `computeResources`. This lets the person who runs the Task fit it to the cluster. Tekton merges requests and limits separately, so an override of the memory limit leaves the CPU request alone.

<!-- astrona:playground:renew -->

Save this as `task-limits-demo.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: limits-demo
  namespace: starfleet
spec:
  steps:
    - name: work
      image: busybox:1.37.0
      computeResources:
        requests:
          cpu: 50m
      script: |
        #!/bin/sh
        echo "id: $(id -u)"
```

Save this as `taskrun-limits-demo-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: limits-demo-run
  namespace: starfleet
spec:
  taskRef:
    name: limits-demo
  stepSpecs:
    - name: work
      computeResources:
        limits:
          memory: 64Mi
```

Apply both and read the resources of the container:

```sh
kubectl apply -f task-limits-demo.yaml
kubectl apply -f taskrun-limits-demo-run.yaml
kubectl wait --for=condition=Succeeded taskrun/limits-demo-run -n starfleet --timeout=120s
kubectl get pod limits-demo-run-pod -n starfleet -o jsonpath='{.spec.containers[?(@.name=="step-work")].resources}{"\n"}'
```

The container has the CPU request of `50m` from the Task and the memory limit of `64Mi` from the `TaskRun`. In `stepSpecs`, only the resources can be overridden, and `name` must match a step of the Task.

The field `spec.computeResources` of a `TaskRun` is different: it sets the resources of the Task as a whole, and Tekton splits them among the steps.

## The service account

Every `TaskRun` runs as a Kubernetes service account: an identity for the pod. The service account decides which Secrets the pod can use to pull images and which permissions the steps have in the Kubernetes API. If `serviceAccountName` is not set, Tekton uses the default from `config-defaults`, and if that is empty, the service account named `default` in the namespace of the run.

```yaml
spec:
  serviceAccountName: build-bot
```

If the named service account does not exist, the run cannot create its pod, and the condition of the `TaskRun` reports it. Create the service account first.

## The pod template

The field `podTemplate` sets pod-level fields for the pod that Tekton creates. The common ones are `securityContext`, `nodeSelector`, `tolerations`, `imagePullSecrets`, `schedulerName` and extra `volumes`. Save this as `taskrun-pod-template.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: pod-template-run
  namespace: starfleet
spec:
  podTemplate:
    securityContext:
      runAsNonRoot: true
      runAsUser: 1001
  taskRef:
    name: limits-demo
```

Apply it and read the log:

```sh
kubectl apply -f taskrun-pod-template.yaml
kubectl wait --for=condition=Succeeded taskrun/pod-template-run -n starfleet --timeout=120s
tkn taskrun logs pod-template-run -n starfleet
```

The step prints `id: 1001`. The `securityContext` in the pod template applies to every step and every sidecar, unless a container sets its own. A Task that needs root fails here, which is the point: the cluster owner sets the rule in the `TaskRun`, and the Task must follow it.

You can now fit a Task to a cluster with resources, an identity and pod settings, without editing the Task.

## Common pitfalls

> [!WARNING]
> - **A `stepSpecs` name that matches no step.** The webhook rejects the run. Use the step name from the Task.
> - **Changing `spec.podTemplate` of a started run.** The spec is fixed after the start. Create a new run.
> - **Setting a memory limit that is too small.** The kernel stops the container, and the run fails with a step out-of-memory reason.
> - **Relying on the `default` service account.** It may lack the image pull Secret. Name the service account on purpose.

## Your mission: Fix A Failing TaskRun With Timeout And Retries

You can now set a timeout and retries on a `TaskRun`, read the record of attempts and recreate a run. The graded lab gives you a `TaskRun` that failed, and asks you to make it succeed with the right settings.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-125-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-040/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-125-lab-040-01
astrona start ats-125-playground-040-01
```
