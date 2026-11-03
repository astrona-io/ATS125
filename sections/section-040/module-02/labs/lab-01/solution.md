# Solution: Diagnose A Failing Archive Task

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: the ConfigMap `archive-diagnosis` against the status of `archive-run`; and the Task `archive-fixed` with its run, while the Task `archive` stays as it was.

## Step 1: Read the status

```sh
kubectl get taskrun archive-run -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{.status.conditions[0].message}{"\n"}'
kubectl get taskrun archive-run -n starfleet -o jsonpath='{range .status.steps[*]}{.name}{" reason="}{.terminated.reason}{" exit="}{.terminated.exitCode}{"\n"}{end}'
tkn taskrun logs archive-run -n starfleet
```

The condition message names the step `pack` and its exit code 3. The log of `pack` says `report missing`.

## Step 2: Record the diagnosis

```sh
kubectl create configmap archive-diagnosis -n starfleet --from-literal=failedStep=pack --from-literal=exitCode=3
```

## Step 3: Find the cause and fix it

The step `collect` writes the report to `/tmp/report.txt`. The folder `/tmp` belongs to the container of that step, so the step `pack` does not see the file. The fix is to use `/workspace`, which every step shares. The new Task also writes the size of the file to a result.

Save this as `task-archive-fixed.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: archive-fixed
  namespace: starfleet
spec:
  results:
    - name: size
  steps:
    - name: collect
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        printf 'orbit report' > /workspace/report.txt
        echo "report collected"
    - name: pack
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        set -eu
        if [ ! -f /workspace/report.txt ]; then
          echo "report missing"
          exit 3
        fi
        wc -c < /workspace/report.txt | tr -d ' \n' > "$(results.size.path)"
        echo "report packed"
```

Save this as `taskrun-archive-fixed-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: archive-fixed-run
  namespace: starfleet
spec:
  taskRef:
    name: archive-fixed
```

Apply both and read the result:

```sh
kubectl apply -f task-archive-fixed.yaml
kubectl apply -f taskrun-archive-fixed-run.yaml
kubectl wait --for=condition=Succeeded taskrun/archive-fixed-run -n starfleet --timeout=180s
kubectl get taskrun archive-fixed-run -n starfleet -o jsonpath='{.status.results[0].value}{"\n"}'
```

The result is `12`, the number of characters in `orbit report`.

## Step 4: Submit

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Edit the Task `archive` | The grader requires it to stay unchanged |
| Guess the failed step | The ConfigMap is compared with the real status |
| Use `echo` for the result | The result gets a newline and the size is 13 |
| Keep `/tmp` | The step `pack` still cannot see the file |

## Common mistakes

- Writing the exit code with a prefix, such as `exit 3`. Use only the number.
- Using `wc -c file`, which prints the file name after the number.

## Practice on your own

- Declare a workspace in the Task and use it instead of `/workspace`.
- Add a debug step that lists `/workspace` before `pack`.
