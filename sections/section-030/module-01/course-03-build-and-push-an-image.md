# Build And Push An Image From A Workspace

Most CI/CD pipelines (continuous integration and delivery) end with a container image in a registry. In Tekton that is a `Task` like any other: a step that runs a build tool on source code from a workspace, a step that pushes the image, and results that say exactly what was pushed. This part writes that `Task` with Buildah, runs it against the registry inside your playground, and proves the image is there.

## Pick a build tool that runs in a normal pod

A step runs as an ordinary container. It has no Docker daemon and, unless you allow it, no extra Linux capabilities and no access to devices such as `/dev/fuse`. The build tool must work inside those limits.

Two tools are common in Tekton Tasks. Kaniko was the classic choice, but its original project, `GoogleContainerTools/kaniko`, was archived in June 2025. Chainguard keeps a fork with security fixes, but publishes no free container images of it. Buildah, from the same project family as Podman, is maintained and publishes versioned images such as `quay.io/buildah/stable:v1.43.5`. This course uses Buildah.

Buildah needs two settings in a normal pod. Its default storage driver in this image, `overlay` through `fuse-overlayfs`, needs `/dev/fuse`, which the pod does not have; `--storage-driver=vfs` copies files instead of mounting them. And Buildah keeps images in `/var/lib/containers`, which is private to each container, so a build step and a push step must share that folder through a volume.

## The source and the registry

Your playground already holds both. The PersistentVolumeClaim (PVC) `bridge-source` in `starfleet` has the folder `bridge-app` with a `Dockerfile` and a file `message.txt`. An OCI registry, a server that stores images by the OCI (Open Container Initiative) distribution rules, runs in the namespace `registry` at `registry.registry.svc.cluster.local:5000`, and a pod `client` with `curl` can call it.

<!-- astrona:playground:renew -->

Read the Dockerfile and ask the registry what it holds:

```sh
kubectl get configmap bridge-app-files -n starfleet -o jsonpath='{.data.Dockerfile}'
kubectl -n registry exec deploy/client -- curl -s http://registry.registry.svc.cluster.local:5000/v2/_catalog
```

The Dockerfile starts `FROM mirror.gcr.io/library/busybox:1.37.0`, Google's mirror of the Docker Hub image, copies `message.txt` and sets a command. The registry has no repositories yet. It speaks plain HTTP without a login. That is acceptable for a lab inside one cluster, and nowhere else.

## The build Task

The `Task` below follows the usual interface of build Tasks: an `IMAGE` parameter with the full reference, a `CONTEXT` and a `DOCKERFILE`, a `source` workspace, and the results `IMAGE_DIGEST` and `IMAGE_URL`. The Task-level `volumes` field declares an `emptyDir` named `container-storage`, and both steps mount it at `/var/lib/containers`.

Save this as `task-image-build.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: image-build
  namespace: starfleet
spec:
  params:
    - name: IMAGE
      type: string
      description: The full image reference to push, with its tag
    - name: CONTEXT
      type: string
      default: "."
    - name: DOCKERFILE
      type: string
      default: Dockerfile
  workspaces:
    - name: source
  results:
    - name: IMAGE_DIGEST
    - name: IMAGE_URL
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

`--tls-verify=false` lets the push use plain HTTP; without it, Buildah tries HTTPS and fails because the registry answers in HTTP. `--digestfile` makes Buildah write the digest of the pushed manifest, `sha256:` and 64 hexadecimal characters, to a file. The step copies it into the result with `printf '%s'`, so no newline sneaks in.

## Run the build

Bind the workspace to the PVC and pass the image reference:

```sh
tkn task start image-build -n starfleet \
  -p IMAGE=registry.registry.svc.cluster.local:5000/starfleet/bridge-app:1.0 \
  -p CONTEXT=bridge-app \
  -w name=source,claimName=bridge-source \
  --use-param-defaults --showlog
```

The log of `build` shows Buildah pulling the base image and running the three Dockerfile instructions; the log of `push` shows the blobs and the manifest going to the registry. The build takes about a minute. Then read the results, with the name `tkn` printed in place of `<NAME>`:

```sh
kubectl get taskrun <NAME> -n starfleet -o jsonpath='{range .status.results[*]}{.name}{"="}{.value}{"\n"}{end}'
```

`IMAGE_URL` is the reference you passed, and `IMAGE_DIGEST` is a `sha256:` digest.

## Prove the image is in the registry

A result is a claim; the registry is the proof. The registry API answers two questions. `/v2/<repository>/tags/list` lists the tags of a repository, and a `HEAD` request on `/v2/<repository>/manifests/<tag>` returns the digest in the header `Docker-Content-Digest`. The registry only returns an OCI manifest to a client that says it accepts one, so send the `Accept` header:

```sh
kubectl -n registry exec deploy/client -- curl -s http://registry.registry.svc.cluster.local:5000/v2/starfleet/bridge-app/tags/list
kubectl -n registry exec deploy/client -- curl -s -I -H 'Accept: application/vnd.oci.image.manifest.v1+json' http://registry.registry.svc.cluster.local:5000/v2/starfleet/bridge-app/manifests/1.0
```

The first command lists the tag `1.0`. The second prints the response headers, and `Docker-Content-Digest` has the same value as `IMAGE_DIGEST`. That match is what later tools, such as an image signer or a deploy `Task`, rely on: they use the digest, which never changes, instead of the tag, which can be moved.

You can now build an image without a daemon and without extra rights, share Buildah's storage between steps, push to a registry, report the digest as a result, and check it against the registry. Together with `onError` and exit codes, you can also make such a build report exactly which part failed.

## Common pitfalls

> [!WARNING]
> - **No `--storage-driver=vfs`.** Buildah tries `fuse-overlayfs`, finds no `/dev/fuse`, and the build fails. Do not fix it with `privileged: true`.
> - **Build and push without a shared volume.** The push step has its own empty `/var/lib/containers` and reports that the image is not known.
> - **`--tls-verify=false` on a real registry.** It is for this lab registry only. Real registries use HTTPS with a trusted certificate.
> - **Asking for a manifest without an `Accept` header.** The registry answers `MANIFEST_UNKNOWN` for an OCI manifest.
> - **Trusting the tag.** A tag can point to a new image tomorrow. Compare and pass on the digest.

## Your mission: Write A Build Task That Pushes To A Registry

You can now write a Buildah `Task` that builds from a workspace, pushes to a registry and reports the digest. The graded lab gives you the source in a PVC and a lab registry, and asks you to write the `Task` and a `TaskRun` so that the registry serves `bridge-app:1.0` with the digest your run reports.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-125-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-125-lab-030-01
astrona start ats-125-playground-030-01
```
