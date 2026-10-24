---
estimated_duration: 30m
---

# Write A Build Task That Pushes To A Registry

- **ID:** LAB
- **Slug:** ats-125-lab-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `starfleet`, with an OCI registry and a client
pod in the namespace `registry`. Read `question.md` for the task;
`solution.md` is the walkthrough.

Not yet run: this lab was written from the Tekton v1.17.1 documentation and
source, and the Buildah commands were checked in a container with the
default Kubernetes capabilities against `registry:3.1.2`. It has not passed
`astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-125-lab-030-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-125-lab-030-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines and the registry, then the source code in the PVC |
| `manifests/` | The namespaces, the registry and client pod, the ConfigMap and PVC with the source and its seed pod |
| `solution/` | Reference solution used by `astrona test`: the Task `image-build` and the TaskRun `image-build-run` |
| `testing/` | Waits for the Tekton Deployments and the registry |
| `validation/` | Grading scripts, one per check; the last one runs its own build |

The build pulls its base image from `mirror.gcr.io` and the step image is
preloaded, so a start needs outbound internet but no Docker Hub pulls during
the build.
