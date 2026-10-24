# Solution: Write A Build Task That Pushes To A Registry

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the Task `image-build` has the agreed interface and Buildah steps; `image-build-run` succeeded and the registry serves `bridge-app:1.0` with the digest in `IMAGE_DIGEST`; and a grader run with its own tag does the same.

## Step 1: Look at the source and the registry

The source sits in the PersistentVolumeClaim (PVC) `bridge-source`. Check that it is bound, and read the Dockerfile from the ConfigMap it was copied from:

```sh
kubectl get pvc bridge-source -n starfleet
kubectl get configmap bridge-app-files -n starfleet -o jsonpath='{.data.Dockerfile}'
```

The Dockerfile starts from `mirror.gcr.io/library/busybox:1.37.0`, copies `message.txt` and sets a command. It has no `RUN` line, so the build only pulls the base image and adds one layer. Now ask the registry what it holds, from the `client` pod inside the cluster:

```sh
kubectl -n registry exec deploy/client -- curl -s http://registry.registry.svc.cluster.local:5000/v2/_catalog
```

It returns an empty list of repositories.

## Step 2: Write the Task

Buildah builds images without a container daemon. Two settings make it work in a normal pod. The default storage driver `overlay` needs the device `/dev/fuse`, which a normal pod does not have, so both steps use `--storage-driver=vfs`, which copies files instead of mounting them. Each step is its own container, so Buildah's storage in `/var/lib/containers` must be a shared volume: the Task declares an `emptyDir` volume and mounts it in both steps.

The push goes to a registry that speaks plain HTTP, so it uses `--tls-verify=false`. `--digestfile` makes Buildah write the digest of the pushed manifest to a file, which the step copies into the result without a newline.

Save this as `task-image-build.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: image-build
  namespace: starfleet
spec:
  description: Builds a container image from a Dockerfile in a workspace and pushes it.
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
  volumes:
    - name: container-storage
      emptyDir: {}
  steps:
    - name: build
      image: quay.io/buildah/stable:v1.43.5
      workingDir: $(workspaces.source.path)
      volumeMounts:
        - name: container-storage
          mountPath: /var/lib/containers
      script: |
        #!/bin/sh
        set -eu
        buildah --storage-driver=vfs build \
          --format=oci \
          --file "$(params.CONTEXT)/$(params.DOCKERFILE)" \
          --tag "$(params.IMAGE)" \
          "$(params.CONTEXT)"
    - name: push
      image: quay.io/buildah/stable:v1.43.5
      volumeMounts:
        - name: container-storage
          mountPath: /var/lib/containers
      script: |
        #!/bin/sh
        set -eu
        buildah --storage-driver=vfs push \
          --tls-verify=false \
          --digestfile /tmp/image-digest \
          "$(params.IMAGE)"
        printf '%s' "$(cat /tmp/image-digest)" > "$(results.IMAGE_DIGEST.path)"
        printf '%s' "$(params.IMAGE)" > "$(results.IMAGE_URL.path)"
```

Apply it:

```sh
kubectl apply -f task-image-build.yaml
```

## Step 3: Run the build

Save this as `taskrun-image-build-run.yaml`:

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
      value: registry.registry.svc.cluster.local:5000/starfleet/bridge-app:1.0
    - name: CONTEXT
      value: bridge-app
  workspaces:
    - name: source
      persistentVolumeClaim:
        claimName: bridge-source
```

Apply it:

```sh
kubectl apply -f taskrun-image-build-run.yaml
```

Then follow the logs and wait for the end:

```sh
tkn taskrun logs image-build-run -n starfleet -f
kubectl get taskrun image-build-run -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{range .status.results[*]}{.name}{"="}{.value}{"\n"}{end}'
```

The log shows Buildah pulling the base image, running the three Dockerfile instructions and pushing the blobs and the manifest. The reason is `Succeeded`, and the results show the image reference and a `sha256:` digest.

## Step 4: Prove the image is in the registry

List the tags of the repository:

```sh
kubectl -n registry exec deploy/client -- curl -s http://registry.registry.svc.cluster.local:5000/v2/starfleet/bridge-app/tags/list
```

It returns the tag `1.0`. Now ask for the manifest digest. The registry only returns an OCI manifest to a client that accepts that media type, so send the `Accept` header:

```sh
kubectl -n registry exec deploy/client -- curl -s -I -H 'Accept: application/vnd.oci.image.manifest.v1+json' http://registry.registry.svc.cluster.local:5000/v2/starfleet/bridge-app/manifests/1.0
```

The header `Docker-Content-Digest` holds the same value as the result `IMAGE_DIGEST`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Run the step with `privileged: true` to get `overlay` working | The constraint forbids it, and it gives the build full access to the node |
| Build and push in two steps without a shared volume | The push step has its own empty `/var/lib/containers` and cannot find the image |
| Write the digest with `echo` | The result ends with a newline and no longer matches the registry digest |
| Type the tag `1.0` into the script | The grader's run with another tag pushes the wrong image |
| Use `--tls-verify=false` on every registry | Fine for this lab registry, dangerous anywhere else; keep TLS on for real registries |

## Common mistakes

- Calling `/v2/<repository>/manifests/<tag>` without an `Accept` header. The registry answers `MANIFEST_UNKNOWN` for an OCI manifest.
- Giving `--file` relative to the workspace while the context is `bridge-app`. In this Task, `DOCKERFILE` is relative to `CONTEXT`.
- Using the Kaniko image from `gcr.io/kaniko-project`. Its project was archived in June 2025 and those images get no updates.

## Practice on your own

- Change `message.txt` through a TaskRun of your own that writes to `bridge-source`, build `bridge-app:1.1`, and compare the two digests.
- Add a third step that writes the image size to a result with `buildah inspect`.
- Run the Task with `DOCKERFILE` set to a file that does not exist, and read which step failed and why.
