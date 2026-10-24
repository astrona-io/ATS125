# Solution: Repair A Failing Image Build

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: `image-build-run` succeeded with every step at exit code `0` and `BUILD_STATUS` = `built and pushed`; the registry serves `bridge-app:1.1` with the digest in `IMAGE_DIGEST`; and a build with a missing Dockerfile makes `report` fail the TaskRun.

## Step 1: Look past the Succeeded condition

Start with the condition, the steps and the results:

```sh
kubectl get taskrun image-build-run -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{range .status.steps[*]}{.name}{" exit "}{.terminated.exitCode}{" "}{.terminationReason}{"\n"}{end}{range .status.results[*]}{.name}{"="}{.value}{"\n"}{end}'
```

The reason is `Succeeded`, but `build` and `push` both ended with a non-zero exit code and the termination reason `Continued`. Both steps have `onError: continue`: the entrypoint binary records the real exit code, writes it to the file `/tekton/steps/step-<name>/exitCode`, and lets the next step start. `BUILD_STATUS` says `failed` with both exit codes, and there is no `IMAGE_DIGEST`. The step `report` saw the failure, wrote it down and still ended with exit code `0`. That is why the TaskRun succeeded.

Confirm that the registry has nothing:

```sh
kubectl -n registry exec deploy/client -- curl -s http://registry.registry.svc.cluster.local:5000/v2/starfleet/bridge-app/tags/list
```

The registry answers with an error that the repository name is not known.

## Step 2: Read why the build failed

Read the log of the first failing step:

```sh
kubectl logs image-build-run-pod -n starfleet -c step-build
```

Buildah pulled the base image, then failed to mount the build container. The error names `fuse-overlayfs` and says that the device `/dev/fuse` was not found. Without `--storage-driver`, Buildah in this image uses the `overlay` driver through `fuse-overlayfs`, which needs `/dev/fuse`. A normal pod has no such device. The `vfs` driver copies files instead of mounting them and works without extra rights. Both `buildah` commands share one storage folder, so both need `--storage-driver=vfs`. If you add it to `build` only, `push` looks in the `overlay` storage and reports that the image is not known.

## Step 3: Read why the push failed

Add `--storage-driver=vfs` to both commands and run again. Edit the Task in place:

```sh
kubectl edit task image-build -n starfleet
```

A started TaskRun never runs again, so delete it and create it again from a file. Save this as `taskrun-image-build-run.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: image-build-run
  namespace: starfleet
spec:
  taskRef:
    name: image-build
  params:
    - name: IMAGE
      value: registry.registry.svc.cluster.local:5000/starfleet/bridge-app:1.1
    - name: CONTEXT
      value: bridge-app
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: bridge-source
```

Apply it after deleting the old one:

```sh
kubectl delete taskrun image-build-run -n starfleet
kubectl apply -f taskrun-image-build-run.yaml
```

Then wait for the end and read the log of the push:

```sh
tkn taskrun logs image-build-run -n starfleet -f
kubectl logs image-build-run-pod -n starfleet -c step-push
```

`build` now ends with exit code `0`. `push` fails: Buildah tries `https://` on port 5000, and the error says that the server gave an HTTP response to an HTTPS client. The lab registry speaks plain HTTP, so the push needs `--tls-verify=false`. Keep TLS verification on for any real registry.

## Step 4: Make report fail the run

Before you run it again, fix the step that hid both failures. `report` reads the exit codes of `build` and `push` through `$(steps.step-build.exitCode.path)` and `$(steps.step-push.exitCode.path)`, writes `BUILD_STATUS` in both cases, and ends with `exit 0`. A step that should stop a failed build from looking green must exit with a non-zero code when a code it read is not `0`. `report` then fails, and the TaskRun gets the reason `StepFailed`.

Save this as `task-image-build.yaml`. It holds all three fixes:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: image-build
  namespace: starfleet
spec:
  description: Builds and pushes an image, then reports how the build went.
  params:
    - name: IMAGE
      type: string
      description: The full image reference to push, with its tag
    - name: CONTEXT
      type: string
      description: The build context, relative to the source workspace
      default: "."
    - name: DOCKERFILE
      type: string
      description: The Dockerfile, relative to the build context
      default: Dockerfile
  workspaces:
    - name: source
      description: Holds the build context
  results:
    - name: IMAGE_DIGEST
      description: The digest of the pushed image manifest
    - name: IMAGE_URL
      description: The image reference that was pushed
    - name: BUILD_STATUS
      description: One line about how the build and the push went
  volumes:
    - name: container-storage
      emptyDir: {}
  stepTemplate:
    image: quay.io/buildah/stable:v1.43.5
    workingDir: $(workspaces.source.path)
    volumeMounts:
      - name: container-storage
        mountPath: /var/lib/containers
  steps:
    - name: build
      onError: continue
      script: |
        #!/bin/sh
        set -eu
        buildah --storage-driver=vfs build \
          --format=oci \
          --file "$(params.CONTEXT)/$(params.DOCKERFILE)" \
          --tag "$(params.IMAGE)" \
          "$(params.CONTEXT)"
    - name: push
      onError: continue
      script: |
        #!/bin/sh
        set -eu
        buildah --storage-driver=vfs push \
          --tls-verify=false \
          --digestfile /tmp/image-digest \
          "$(params.IMAGE)"
        printf '%s' "$(cat /tmp/image-digest)" > "$(results.IMAGE_DIGEST.path)"
        printf '%s' "$(params.IMAGE)" > "$(results.IMAGE_URL.path)"
    - name: report
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        set -u
        build_code="$(cat "$(steps.step-build.exitCode.path)")"
        push_code="$(cat "$(steps.step-push.exitCode.path)")"
        if [ "$build_code" = "0" ] && [ "$push_code" = "0" ]; then
          printf 'built and pushed' | tee "$(results.BUILD_STATUS.path)"
          echo
        else
          printf 'failed: build exit %s, push exit %s' "$build_code" "$push_code" | tee "$(results.BUILD_STATUS.path)"
          echo
          echo "The image was not pushed. Read the logs of step-build and step-push." >&2
          exit 1
        fi
```

Apply it:

```sh
kubectl apply -f task-image-build.yaml
```

## Step 5: Build and check the image

Create the TaskRun again:

```sh
kubectl delete taskrun image-build-run -n starfleet
kubectl apply -f taskrun-image-build-run.yaml
kubectl wait --for=condition=Succeeded taskrun/image-build-run -n starfleet --timeout=300s
kubectl get taskrun image-build-run -n starfleet -o jsonpath='{range .status.steps[*]}{.name}{" exit "}{.terminated.exitCode}{"\n"}{end}{range .status.results[*]}{.name}{"="}{.value}{"\n"}{end}'
```

All three steps end with exit code `0`, and `BUILD_STATUS` is `built and pushed`. Compare `IMAGE_DIGEST` with the digest the registry serves:

```sh
kubectl -n registry exec deploy/client -- curl -s -I -H 'Accept: application/vnd.oci.image.manifest.v1+json' http://registry.registry.svc.cluster.local:5000/v2/starfleet/bridge-app/manifests/1.1
```

The header `Docker-Content-Digest` has the same value.

## Step 6: Test the failure path

Prove that a broken build now fails the run. Save this as `taskrun-image-build-broken.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: image-build-broken-
  namespace: starfleet
spec:
  taskRef:
    name: image-build
  params:
    - name: IMAGE
      value: registry.registry.svc.cluster.local:5000/starfleet/bridge-app:broken
    - name: CONTEXT
      value: bridge-app
    - name: DOCKERFILE
      value: Missing.Dockerfile
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: bridge-source
```

Create it:

```sh
kubectl create -f taskrun-image-build-broken.yaml
```

Then check the result with the generated name in place of `<NAME>`:

```sh
kubectl get taskrun <NAME> -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{range .status.steps[*]}{.name}{" exit "}{.terminated.exitCode}{" "}{.terminationReason}{"\n"}{end}'
```

The reason is `StepFailed`. `build` and `push` show `Continued`, and `report` ran and ended with exit code `1`.

## Step 7: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Remove `onError: continue` from `build` and `push` | Failures now fail the run, but `report` is `Skipped` and never writes `BUILD_STATUS`; the grader requires it to run |
| Set `privileged: true` to make `overlay` work | The constraint forbids it, and it gives the build full access to the node |
| Trust the `Succeeded` condition alone | With `onError: continue`, a failed step does not change the condition; read `status.steps` |
| Make `report` fail on the build exit code only | A failed push would still look green |

## Common mistakes

- Writing `$(steps.build.exitCode.path)`. The variable needs the container name: `$(steps.step-build.exitCode.path)`.
- Adding `--storage-driver=vfs` to one command only. Both must use the same storage driver.
- Reading the push error and changing the registry. The registry is fine; the client must not ask for HTTPS.

## Practice on your own

- Add `timeout: 1s` to the step `build`, run it, and read the termination reason of the step and the message of the condition.
- Change `report` to `exit 2` on failure, and find the code in `status.steps`.
- Set `STORAGE_DRIVER=vfs` as an environment variable in the `stepTemplate` instead of the flag, and check whether Buildah picks it up.
