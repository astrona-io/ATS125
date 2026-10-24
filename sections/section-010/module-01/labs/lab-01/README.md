---
estimated_duration: 20m
---

# Repair A Task's Parameters, Environment And Results

- **ID:** LAB
- **Slug:** ats-125-lab-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for the namespace `starfleet`. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this lab was written from the Tekton v1.17.1 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-125-lab-010-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-125-lab-010-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI and Tekton Pipelines, then the broken Task and TaskRun |
| `manifests/` | The namespace `starfleet`, the broken Task `image-tag` and TaskRun `image-tag-run` |
| `solution/` | Reference solution used by `astrona test`, with the fixed Task and TaskRun |
| `testing/` | Waits for the Tekton Deployments |
| `validation/` | Grading scripts, one per check; the last one runs its own TaskRun |
