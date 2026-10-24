---
estimated_duration: 30m
---

# Repair A Failing Image Build

- **ID:** CAPSTONE
- **Slug:** ats-125-capstone-030
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded capstone

Graded capstone for section 030, in the namespace `starfleet`, with an OCI
registry and a client pod in the namespace `registry`. Read `question.md`
for the task; `solution.md` is the walkthrough.

> **Not yet run.** This capstone was written from the Tekton v1.17.1
> documentation and source. The Buildah failure modes (overlay without
> `/dev/fuse`, HTTPS against an HTTP registry, missing Dockerfile) were
> checked in a container with the default Kubernetes capabilities. It has not
> passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-125-capstone-030
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-125-capstone-030`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI, Tekton Pipelines and the registry, then the source and the broken Task and TaskRun |
| `manifests/` | The namespaces, registry and client pod, the source PVC with its seed pod, the Task `image-build` and the TaskRun `image-build-run` |
| `solution/` | Reference solution used by `astrona test`, with the fixed Task and the TaskRun |
| `testing/` | Waits for the Tekton Deployments and the registry |
| `validation/` | Grading scripts, one per check; the last one runs a build that must fail |
