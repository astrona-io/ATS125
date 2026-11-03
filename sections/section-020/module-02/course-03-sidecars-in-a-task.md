# Sidecars In A Task

Some work needs a helper process while the steps run: a database for integration tests, a mock HTTP service, a Docker daemon for builds. The steps of a Task run one after the other, so they cannot be the helper. A sidecar is a container that starts with the pod and runs next to the steps. This part writes a Task with a small web server as a sidecar and reaches it from a step.

## Declare a sidecar

A Task lists sidecars under `sidecars`, in the same format as steps: a `name`, an `image` and a `script` or a `command`. A sidecar has no turn in the order. Kubernetes starts its container with the pod, and it keeps running while the steps run.

All containers of a pod share one network namespace. A step reaches a sidecar at `localhost` and the port the sidecar listens on. No Kubernetes Service is needed.

<!-- astrona:playground:renew -->

Save this as `task-page-reader.yaml`. The sidecar serves the folder `/www` with the `httpd` applet of `busybox`, and the first step writes a page into that folder through a shared volume:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: page-reader
  namespace: starfleet
spec:
  params:
    - name: message
      type: string
      default: all systems nominal
  results:
    - name: body
  volumes:
    - name: www
      emptyDir: {}
  sidecars:
    - name: server
      image: busybox:1.37.0
      volumeMounts:
        - name: www
          mountPath: /www
      script: |
        #!/bin/sh
        exec httpd -f -p 8080 -h /www
  steps:
    - name: publish
      image: busybox:1.37.0
      env:
        - name: MESSAGE
          value: $(params.message)
      volumeMounts:
        - name: www
          mountPath: /www
      script: |
        #!/bin/sh
        set -eu
        printf '%s' "$MESSAGE" > /www/status.txt
    - name: fetch
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        set -eu
        for attempt in 1 2 3 4 5 6 7 8 9 10; do
          if wget -q -O "$(results.body.path)" http://127.0.0.1:8080/status.txt; then
            exit 0
          fi
          echo "server not ready (attempt $attempt)"
          sleep 2
        done
        exit 1
```

Apply it and run it:

```sh
kubectl apply -f task-page-reader.yaml
tkn task start page-reader -n starfleet --showlog
```

The step `publish` writes the page. The step `fetch` downloads it from `http://127.0.0.1:8080/status.txt` and writes the answer into the result. Read the result:

```sh
kubectl get taskrun -n starfleet -l tekton.dev/task=page-reader -o jsonpath='{.items[0].status.results[0].name}{"=["}{.items[0].status.results[0].value}{"]"}{"\n"}'
```

The value is `all systems nominal`, with no newline. The sidecar and the steps share the volume `www`, and the steps reach the web server on the pod's own address.

## What the pod looks like

List the containers of the pod:

```sh
kubectl get pods -n starfleet -l tekton.dev/task=page-reader -o jsonpath='{range .items[0].spec.containers[*]}{.name}{"\n"}{end}'
```

The list shows `step-publish`, `step-fetch` and `sidecar-server`. Tekton prefixes step containers with `step-` and sidecar containers with `sidecar-`. In the log, `tkn` shows the sidecar log too, and `kubectl logs` can read it with the container name:

```sh
kubectl logs -n starfleet -l tekton.dev/task=page-reader -c sidecar-server
```

A sidecar that writes to its standard output shows up there, which makes it the place to look when a helper does not behave.

## Why the loop in the step

The step `fetch` tries the request up to ten times. Kubernetes starts all containers of the pod at about the same time, and the Tekton entrypoint only orders the steps. Nothing makes a step wait for the sidecar. If the first request comes before `httpd` listens, the request fails. The loop covers that gap. The next part explains what Tekton does and does not guarantee here.

You can now write a sidecar and reach it from a step. The open question is how a sidecar ends, and how to be sure that it is ready.

## Common pitfalls

> [!WARNING]
> - **A step that calls the sidecar once.** The sidecar may not listen yet. Retry with a short sleep.
> - **A sidecar script that does not stay in the foreground.** The container ends, and the steps find nothing at the port. Use the foreground mode of the server.
> - **Two containers with the same port.** All containers of a pod share the network. Give each sidecar its own port.
> - **Expecting the sidecar to see `/workspace`.** Mount the volume or workspace in the sidecar too.
