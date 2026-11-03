# Solution: Write A Task With A Sidecar And A Shared Volume

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the shape of the Task (sidecar, shared volume, two steps); the TaskRun `status-reader-run` with the default message; and a grader run with another message.

## Step 1: Write the Task

The sidecar and the step `publish` mount the same `emptyDir`. The sidecar serves the folder and stays in the foreground with `httpd -f`. The step `fetch` retries.

Save this as `task-status-reader.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: status-reader
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

Apply it:

```sh
kubectl apply -f task-status-reader.yaml
```

## Step 2: Run it

Save this as `taskrun-status-reader-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: status-reader-run
  namespace: starfleet
spec:
  taskRef:
    name: status-reader
```

Apply it, wait and read the result:

```sh
kubectl apply -f taskrun-status-reader-run.yaml
kubectl wait --for=condition=Succeeded taskrun/status-reader-run -n starfleet --timeout=180s
kubectl get taskrun status-reader-run -n starfleet -o jsonpath='{.status.results[0].name}{"=["}{.status.results[0].value}{"]"}{"\n"}'
```

The value between the brackets is `all systems nominal`.

If the run does not finish, read the sidecar log and the step log:

```sh
kubectl logs -n starfleet -l tekton.dev/taskRun=status-reader-run -c sidecar-server
kubectl logs -n starfleet -l tekton.dev/taskRun=status-reader-run -c step-fetch
```

## Step 3: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Type the message into `fetch` | The grader run with another message reports the old text |
| Skip the retry loop | The first request can come before `httpd` listens, and the run fails now and then |
| Use `httpd` without `-f` | The server goes to the background, the container ends and the port is closed |
| Mount the volume only in the sidecar | The step `publish` writes to a folder that the server does not serve |

## Common mistakes

- Using `echo` in `publish`. The file then ends with a newline, and so does the result.
- Giving the sidecar a port that another container already uses.

## Practice on your own

- Add `sidecarSpecs` to the TaskRun with a memory limit.
- Make `fetch` print the HTTP status line with `wget -S`.
