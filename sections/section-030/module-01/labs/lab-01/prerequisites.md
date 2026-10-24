# Prerequisites

Before starting this lab you should be able to:

- Write a `Task` with `params`, a workspace, `results`, Task-level `volumes` and step `volumeMounts`.
- Explain why Buildah needs `--storage-driver=vfs` in a normal pod, and why the push to this lab registry needs `--tls-verify=false`.
- Call the registry API (`/v2/<repository>/tags/list` and `/v2/<repository>/manifests/<tag>`) with `curl`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Tekton Pipelines v1.17.1** and the `tkn` command-line tool, version **0.46.2**.
- An OCI registry (Distribution `registry:3.1.2`, plain HTTP, lab only) at `registry.registry.svc.cluster.local:5000`, and a pod `client` with `curl` in the namespace `registry`.
- The PersistentVolumeClaim `bridge-source` in `starfleet`, with `bridge-app/Dockerfile` and `bridge-app/message.txt`.
- The step image `quay.io/buildah/stable:v1.43.5`, already loaded on the node.

## Working rules

- Everything is graded on the **final cluster state**. Leave the Task and the TaskRun in place.
- The grader runs your Task once more with its own tag, so the Task must use its parameters, not fixed values.
- A build takes about a minute.
