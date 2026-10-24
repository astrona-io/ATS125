---
estimated_duration: 30m
---

# Repair The Workspaces Of A Report Task

- **ID:** CAPSTONE
- **Slug:** ats-125-capstone-020
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded capstone

Graded capstone for section 020, in the namespace `starfleet`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This capstone was written from the Tekton v1.17.1
> documentation and source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-125-capstone-020
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-125-capstone-020`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI and Tekton Pipelines, then the data and the broken Task and TaskRun |
| `manifests/` | The namespace, the PVCs `report-data` (with its seed pod) and `report-cache`, the ConfigMap, the Task `deck-report` and the TaskRun `deck-report-run` |
| `solution/` | Reference solution used by `astrona test`, with the fixed Task and TaskRun |
| `testing/` | Waits for the Tekton Deployments |
| `validation/` | Grading scripts, one per check; two of them run their own TaskRun |
