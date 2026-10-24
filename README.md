# ATS125 — Tasks, Steps & Workspaces (Tekton)

Course material for the **Tasks, Steps & Workspaces** domain of the Astrona
Tekton training path ([ATP024](https://github.com/astrona-io/ATP024)), which
is **20% of the path**. Written for **Tekton Pipelines v1.17.1**, the **tkn
CLI v0.46.2** and **Buildah v1.43.5**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Tekton documentation and the v1.17.1 source. The Buildah commands
> and their failure modes were checked in a container with the default
> Kubernetes capabilities against `registry:3.1.2`. No environment has been
> started on a cluster, and no lab has passed `astrona test` yet. See
> `CLAUDE.md`.

Tekton is an incubating project of the Cloud Native Computing Foundation
(CNCF) since March 2026; before that it was a graduated project of the
Continuous Delivery Foundation. There is no official Tekton certification
exam; the path's domains and weights are Astrona's own.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's modules into a
  single scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Write Tasks With Steps, Parameters And Results | 1 | 1 + capstone | Task anatomy |
| [020](sections/section-020) | Share Data With Workspaces | 1 | 1 + capstone | Workspaces |
| [030](sections/section-030) | Step Lifecycle And A Container Build Task | 1 | 1 + capstone | Step lifecycle and image builds |

The order goes from the inside of a `Task` to the files around it and then to
its behaviour over time. Section 010 takes a `Task` apart: steps, parameters
and results. Section 020 gives Tasks files through workspaces. Section 030
reads how runs and steps end, handles failed steps with `onError` and exit
codes, and ends with a Buildah Task that builds from a workspace and pushes
to a registry inside the cluster.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Write A Task From Steps, Parameters And Results](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Share Files With Workspaces](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Control Step Failures And Build An Image](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |

| Lab | Title | Kind | Faults or work |
| --- | --- | --- | --- |
| 010-01 | Repair A Task's Parameters, Environment And Results | troubleshooting | an array parameter passed as a string, a step that hides a `stepTemplate` variable, a result written with a newline |
| 020-01 | Bind Workspaces To A TaskRun | build | bind a PVC with `subPath`, a ConfigMap and an isolated Secret workspace |
| 030-01 | Write A Build Task That Pushes To A Registry | build | a Buildah Task with `IMAGE`/`CONTEXT`/`DOCKERFILE`, a `source` workspace and `IMAGE_DIGEST`/`IMAGE_URL` |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Repair A Task Built From Steps, Parameters And Results | a wrong Secret key (`CreateContainerConfigError`), a `bash` shebang on busybox, a `stepTemplate` that ignores a parameter |
| [020](sections/section-020/capstone/labs/lab-01) | Repair The Workspaces Of A Report Task | two PVCs in one TaskRun, `readOnly` on the output workspace, a wrong `subPath` that still succeeds |
| [030](sections/section-030/capstone/labs/lab-01) | Repair A Failing Image Build | Buildah without `--storage-driver=vfs`, a push with TLS verification to an HTTP registry, an exit-handler step that never fails the run |

---

## The lab environment

Every playground and lab is a single-node **kind** cluster (Kubernetes 1.28
or later) with the `tkn` CLI 0.46.2 installed on the machine, Tekton
Pipelines v1.17.1 from its release manifest, and the namespace `starfleet`.
Step images use `busybox:1.37.0`, preloaded on the node. Tekton's own images
come from `ghcr.io` (and the `place-scripts` shell image from `cgr.dev`) by
digest, so every start needs outbound internet.

The section 030 environments add an OCI registry (`registry:3.1.2`, plain
HTTP, lab only) as `registry.registry.svc.cluster.local:5000`, a client pod
(`nicolaka/netshoot:v0.13`) in the namespace `registry`, and the
PersistentVolumeClaim `bridge-source` with a small busybox-based Dockerfile.
Builds use `quay.io/buildah/stable:v1.43.5` (preloaded) and pull their base
image from `mirror.gcr.io`.

Graders read Tekton objects with `kubectl`, call the registry from inside the
cluster through the client pod, and often create a TaskRun of their own
(`generateName`, label `astrona.io/grader: "true"`) to test behaviour. No
script uses a fixed host port.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final cluster state** with independent checks, and
several of them deliberately reject the plausible-but-wrong fix (changing an
array parameter to a string, adding a key to a Secret instead of fixing the
Task, typing values into scripts, switching off the one-PVC rule, running
Buildah privileged, removing `onError` so the exit handler never runs).
