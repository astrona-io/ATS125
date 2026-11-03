---
estimated_duration: 25m
---

# Fix A Failing TaskRun With Timeout And Retries

- **ID:** LAB
- **Slug:** ats-125-lab-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded graded lab for the namespace `starfleet`. Read `question.md` for the task; `solution.md` is the walkthrough.

Not yet run: this lab was written from the Tekton v1.17.1 documentation and
source and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-125-lab-040-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-125-lab-040-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | tkn CLI and Tekton Pipelines, then the starting state |
| `manifests/` | The namespace `starfleet` and the seeded objects |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Waits for the Tekton Deployments |
| `validation/` | Grading scripts, one per check |
