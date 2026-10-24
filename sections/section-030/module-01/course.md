# Control Step Failures And Build An Image

A build `TaskRun` turns red at two in the morning. Did the build fail, the push, or the clock? Or worse: it turned green, and the image is not in the registry. To answer quickly you must know how a `TaskRun` moves through its states, how each step can end, and how a `Task` can keep running after a failure to report what went wrong. This module teaches those mechanics and then puts them to work in a `Task` that builds and pushes a container image.

A `TaskRun` has one `Succeeded` condition, `Unknown` while it runs and `True` or `False` at the end. Each step leaves a record in `status.steps` with its exit code and a termination reason such as `Completed`, `Error`, `Skipped`, `Continued` or `TimeoutExceeded`. The field `onError: continue` lets a step fail without ending the run, and a later step can read its exit code from a file.

The module has three parts. **The TaskRun Lifecycle And Step Termination States** follows a run from creation to its end and makes each step state happen once, including step and run timeouts. **Handle Step Failures With onError And Exit Codes** builds a last step that always runs, writes a status and decides the outcome. **Build And Push An Image From A Workspace** writes a Buildah `Task` that builds from a PersistentVolumeClaim, pushes to the registry in your cluster and reports the digest. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Name the reasons of the `Succeeded` condition from `Started` to the end, and say which component sets them.
- Read `terminated.exitCode` and `terminationReason` of each step, and find the first step that really failed.
- Tell a step `timeout` from the `TaskRun` timeout, and say what happens to the pod in each case.
- Use `onError: continue` and `$(steps.step-<name>.exitCode.path)` to make a last step report and decide the outcome.
- Build an image with Buildah in a normal pod, share its storage between steps and push it to a registry.
- Report `IMAGE_DIGEST` and `IMAGE_URL`, and check them against the registry API.

## Before you start

You need to be able to write a `Task` with parameters, results and workspaces, and to bind a PersistentVolumeClaim to a workspace. You should know what a container image, a tag and a registry are.

Your playground is a single-node `kind` cluster with these parts:

| Part of the playground | What it is |
| --- | --- |
| Namespace `tekton-pipelines` | Tekton Pipelines v1.17.1: the controller, the webhook and the events controller |
| Namespace `starfleet` | The PersistentVolumeClaim `bridge-source` with a small Dockerfile in `bridge-app`. Your Tasks go here |
| Namespace `registry` | An OCI registry at `registry.registry.svc.cluster.local:5000` (plain HTTP, lab only) and a pod `client` with `curl` |
| Images on the node | `busybox:1.37.0` and `quay.io/buildah/stable:v1.43.5` |
| `tkn` on your PATH | The Tekton command-line tool, version 0.46.2 |

Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
