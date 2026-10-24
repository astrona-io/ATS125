# Steps: Image, Command, Script And Environment

A `Task` is the unit of work in Tekton: a list of steps, with inputs and outputs, stored as an object in one namespace. Most of what you write in a `Task` is the steps themselves. Each step decides which container image runs, which program starts in it, which environment variables it sees and in which folder it works. This part takes one small `Task` apart field by field, so that you can read any step and predict what its container does.

## One step is one container

A step is one container in the pod of a `TaskRun`. A `TaskRun` is one execution of a `Task`; the tekton-pipelines-controller creates one pod for it and runs the steps one after the other, in the order of the list. Each step needs at least a `name` and an `image`, and it needs something to run: either `command` and `args`, or a `script`.

The `Task` below has two steps that print the same line in two ways. The first uses `command` and `args`, exactly like a container in a Kubernetes pod. The second uses `script`, a block of shell code that Tekton writes to a file and runs.

<!-- astrona:playground:renew -->

Save this as `task-greet.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: greet
  namespace: starfleet
spec:
  steps:
    - name: with-command
      image: busybox:1.37.0
      command: ["echo"]
      args: ["Hello from command and args"]
    - name: with-script
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        set -eu
        echo "Hello from a script"
        echo "Working directory: $(pwd)"
```

Apply it:

```sh
kubectl apply -f task-greet.yaml
```

Now start it with `tkn`, which creates a `TaskRun` for you and follows its logs:

```sh
tkn task start greet -n starfleet --showlog
```

The log shows the line of `with-command` first and then the two lines of `with-script`. The working directory of the second step is `/`, the working directory of the `busybox` image, because the step does not set one.

## What command and script really run

Tekton does not start your program directly. The tekton-pipelines-controller replaces the command of every step container with the entrypoint binary, a small Tekton program that waits for the step before it, runs your command, and records the exit code. Look at the containers of the pod:

```sh
kubectl get pods -n starfleet -l tekton.dev/task=greet -o jsonpath='{range .items[0].spec.containers[*]}{.name}{": "}{.command}{" "}{.args}{"\n"}{end}'
```

Both containers start `/tekton/bin/entrypoint`. For `step-with-command`, the arguments hold `-entrypoint echo`, then `--` and your arguments. For `step-with-script`, `-entrypoint` points at a script file under `/tekton/scripts`. The init container `place-scripts` wrote that file before the steps started.

Two rules follow from this. A step can have `script` or `command`, never both; the webhook rejects a step with both. If a `script` has no shebang line (`#!` and the path of an interpreter), Tekton adds `#!/bin/sh` and `set -e` at the top. Write the shebang yourself, and make sure the interpreter exists in the image: `#!/bin/bash` fails on `busybox:1.37.0`, which has no `bash`.

There is a third case: a step with an `image` and no `command` and no `script`. The tekton-pipelines-controller must then ask the registry for the entrypoint of the image, which needs network access to the registry even when the image is already on the node. Give every step a `command` or a `script`.

## Environment, working directory and the stepTemplate

A step takes the same container fields as a Kubernetes container: `env`, `envFrom`, `workingDir`, `volumeMounts`, `securityContext` and `computeResources` (the v1 name of `resources`, with `requests` and `limits`). Fields that should be the same for every step can go into `stepTemplate`. Tekton merges the template into each step; for environment variables it merges by name, and the value in the step wins.

The next version of `greet` shows all of it. The `stepTemplate` sets `DECK` and a working directory. The second step overrides `DECK`, reads `CREW_ROLE` from a ConfigMap with `valueFrom`, and imports every key of the same ConfigMap with `envFrom`.

Save this as `configmap-crew-settings.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: crew-settings
  namespace: starfleet
data:
  CREW_ROLE: pilot
  SHIP_CLASS: scout
```

Apply it:

```sh
kubectl apply -f configmap-crew-settings.yaml
```

Save this as `task-greet-env.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: greet
  namespace: starfleet
spec:
  stepTemplate:
    workingDir: /workspace/greet
    env:
      - name: DECK
        value: bridge
  steps:
    - name: from-template
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        set -eu
        echo "DECK=$DECK in $(pwd)"
    - name: with-overrides
      image: busybox:1.37.0
      env:
        - name: DECK
          value: engineering
        - name: CREW_ROLE
          valueFrom:
            configMapKeyRef:
              name: crew-settings
              key: CREW_ROLE
      envFrom:
        - configMapRef:
            name: crew-settings
      computeResources:
        requests:
          cpu: 50m
          memory: 32Mi
        limits:
          memory: 64Mi
      script: |
        #!/bin/sh
        set -eu
        echo "DECK=$DECK CREW_ROLE=$CREW_ROLE SHIP_CLASS=$SHIP_CLASS in $(pwd)"
```

Apply it:

```sh
kubectl apply -f task-greet-env.yaml
```

Then run it:

```sh
tkn task start greet -n starfleet --showlog
```

The first step prints `DECK=bridge` and the second `DECK=engineering`, together with `pilot` and `scout` from the ConfigMap. Both run in `/workspace/greet`. Tekton created that folder for you: a relative working directory, or one under `/workspace`, is created by an extra init container named `working-dir-initializer` before the steps start.

The values from the ConfigMap are read by the kubelet, the Kubernetes agent on the node, when it creates the container. If the ConfigMap or Secret, or the key that `valueFrom` names, does not exist, the kubelet cannot create that step container. The container waits with the reason `CreateContainerConfigError`, and the tekton-pipelines-controller fails the `TaskRun` with the same reason. The state of the container in the pod, not a log, then names the missing key.

The fields above all belong to the step itself. A `StepAction` is the exception worth knowing: it is a separate object (`tekton.dev/v1beta1`) that holds one reusable step, and a step uses it with `ref: {name: <stepaction>}` instead of `image` and `script`. The `stepTemplate` is not merged into a step that uses `ref`.

You can now read a step: which image runs, whether `command` or `script` starts the work, where the environment comes from and which folder the step works in. The open question is how values get into a `Task` from outside, so that the same `Task` can greet any crew member.

## Common pitfalls

> [!WARNING]
> - **`script` and `command` in one step.** The webhook rejects the `Task`. Use one of them; a `script` still receives `args` as `$1`, `$2` and so on.
> - **A shebang for a shell the image does not have.** `#!/bin/bash` on `busybox` fails with exit code 127. Use `#!/bin/sh` or an image with `bash`.
> - **A step without `command` or `script`.** The controller then needs the registry to find the image's entrypoint, and the run fails without network access.
> - **Expecting the `stepTemplate` to win.** A value set in the step overrides the template value with the same name.
> - **Assuming every step starts in `/workspace`.** Without `workingDir`, a step starts in the working directory of its image.
