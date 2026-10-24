# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS125 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Tasks, Steps & Workspaces** domain of the
  **Tekton** training path (`ATP024`). It is 20% of the path. There is no
  official Tekton certification exam; the path's domains and weights are
  Astrona's own, set in `ATP024/path.yaml` (10/20/25/15/15/15 for ATS124 to
  ATS129).
- **Where Tekton sits:** Tekton is an **incubating project of the Cloud Native
  Computing Foundation (CNCF)**. The CNCF accepted it on 13 March 2026. Before
  that it was a founding and graduated project of the Continuous Delivery
  Foundation (CD Foundation). It is **not** a CNCF graduated project, and it is
  no longer a CD Foundation project. Both foundations belong to the Linux
  Foundation. Say this correctly wherever the course mentions it.
- **What the domain really tests:** writing and repairing Tasks, not
  remembering words. The student must *do* things (write steps and
  parameters, bind workspaces, read `status.steps`, build and push an image).
  Every explanation should lead to a command they can run, and every fix
  should be proved with a TaskRun whose `Succeeded` condition is `True`, whose
  results have the expected values, and, for builds, whose digest the
  registry serves.
- **The three topics:** the anatomy of a Task (steps, parameters, results),
  workspaces, and the step lifecycle with a container build Task. The README
  table maps each section to its topic.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Write Tasks With Steps, Parameters And Results | Task anatomy |
  | 020 | Share Data With Workspaces | Workspaces |
  | 030 | Step Lifecycle And A Container Build Task | Step lifecycle and image builds |

- **"Exit handlers":** Tekton has no exit-handler field on a Task. The course
  teaches the real mechanism: `onError: continue` (or the default
  `stopAndFail`) on steps, the exit code file read through
  `$(steps.step-<name>.exitCode.path)`, and a last step that writes a status
  and exits non-zero. `finally` belongs to Pipelines (another domain); name it
  in one sentence only.
- **The versions:** everything is written for **Tekton Pipelines v1.17.1**,
  the **tkn CLI v0.46.2** and **Buildah v1.43.5**
  (`quay.io/buildah/stable:v1.43.5`) on a single-node `kind` cluster.
  Pipelines 1.17 needs Kubernetes 1.28 or later. v1.17 is a monthly release
  (end of life 31 October 2026); the current long-term support (LTS) release
  is v1.15. Other ecosystem versions of the path (for orientation only):
  Dashboard v0.73.0, Triggers v0.37.2, Chains v0.29.9, Pipelines-as-Code
  v0.52.0, Operator v0.81.2, Pruner v0.4.4. Do not teach fields, flags or
  output from other versions without saying so.
- **The main sources:** the Tekton documentation, <https://tekton.dev/docs/>,
  and the `docs/` folders and source of `tektoncd/pipeline` (tag `v1.17.1`)
  and `tektoncd/cli` (tag `v0.46.2`). Check every page against them.

### Status: built, not yet run

The first version of this repository was written from the Tekton
documentation and the source at the pinned tags **without a live run**. No
playground or lab has been started, and no `astrona test` has passed yet. The
Buildah commands were checked in Podman containers with the default
Kubernetes capability set against `registry:3.1.2` (build, push, digest file,
the overlay error without `/dev/fuse`, the HTTPS error against an HTTP
registry, exit code 125 for a missing Dockerfile). Until a maintainer runs
them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

The biggest open risks are: Buildah in a kind pod on hosts with AppArmor
(the test was Podman on macOS; the Dockerfiles have no `RUN` line, so no
mount namespace is needed); the timing of the section 010 capstone, whose
first failure must be `CreateContainerConfigError` (a wrong Secret key)
before the bash-shebang failure shows; the step and run timeout demos in
section 030 part 1, which depend on pod start time; and pulls of
`mirror.gcr.io/library/busybox:1.37.0` from inside the build pods.

### Terms, not metaphors

Explanations use Tekton's and Kubernetes' own words. Define each one in plain
technical language on first use in a file, for example:

| Term | First-use definition (example wording) |
| --- | --- |
| `Task` | A reusable list of steps, with parameters, results and workspaces, stored in one namespace |
| `TaskRun` | One execution of a `Task`; Tekton creates one pod for it |
| Step | One container in the TaskRun's pod; steps run one after the other |
| Entrypoint binary | A Tekton program that replaces each step's command, starts it in order and records its exit code |
| `script` / `command` and `args` | Two ways to say what a step runs; a step has one or the other |
| `stepTemplate` | Container settings merged into every step; the value in a step wins |
| `StepAction` | A reusable step stored as its own object (`tekton.dev/v1beta1`), used with `ref` |
| Parameter (`params`) | A named input value of type `string`, `array` or `object`; used as `$(params.<name>)` |
| Result (`results`) | A short named output written to `$(results.<name>.path)`; copied to `status.results` |
| Step result | A value one step writes to `$(step.results.<name>.path)` and a later step reads as `$(steps.<step>.results.<name>)` |
| Workspace | A named folder a `Task` declares and a `TaskRun` binds to a volume |
| `volumeClaimTemplate` | A PVC template; Tekton creates one PVC per run, owned by the `TaskRun` |
| `subPath` | Limits a workspace binding to one folder of the volume |
| `terminationReason` | How a step ended: `Completed`, `Error`, `Skipped`, `Continued`, `TimeoutExceeded`, `Cancelled` |
| `onError` | `continue` lets a failed step not stop the run; `stopAndFail` is the default |
| Buildah | A daemonless image build tool; runs in a normal pod with `--storage-driver=vfs` |
| OCI registry | A server that stores images by the Open Container Initiative distribution rules |

A `Task` and a `TaskRun` are the most confused pair. On first use in a file,
always say which one you mean, and say that the pod belongs to the TaskRun.

### The example workloads

| Name | Image | What it is |
| --- | --- | --- |
| Namespace `starfleet` | | Where every Task and TaskRun of the course runs |
| Namespace `registry` | `registry:3.1.2`, `nicolaka/netshoot:v0.13` | The lab OCI registry (HTTP, port 5000) and the `client` pod with `curl` (section 030 only) |
| Task `greet`, `preflight`, `tag-info`, `crew-count` | `busybox:1.37.0` | Examples for steps, parameters and results (section 010 parts) |
| Task `image-tag` | `busybox:1.37.0` | Section 010 lab: `stepTemplate` env `REGISTRY`, array parameter `labels` |
| Task `crew-manifest` | `busybox:1.37.0` | Section 010 capstone: Secret `report-token`, step result `lines` |
| Task `share-notes`, `checklist`, `log-entry` | `busybox:1.37.0` | Examples for workspaces (section 020 parts) |
| Task `crew-roster` | `busybox:1.37.0` | Section 020 lab: PVC `roster-data`, ConfigMap `roster-settings`, Secret `roster-token` |
| Task `deck-report` | `busybox:1.37.0` | Section 020 capstone: PVCs `report-data`, `report-cache`, ConfigMap `report-config` |
| Task `launch-sequence`, `systems-test` | `busybox:1.37.0` | Examples for step states and `onError` (section 030 parts) |
| Task `image-build` | `quay.io/buildah/stable:v1.43.5` | Builds `bridge-app` from the PVC `bridge-source` and pushes it |

Every step uses a `script` or a `command`, never a bare image: without one,
the controller asks the registry for the image's entrypoint.

### Environment facts the text must respect

- **Install from the release manifest:**
  `kubectl apply -f https://infra.tekton.dev/tekton-releases/pipeline/previous/v1.17.1/release.yaml`.
  The install script is the same as in ATS124 (tkn tarball, `apply_with_retry`,
  rollout waits, webhook dry-run probe); the section 030 variant also waits
  for the registry `/v2/` from the client pod.
- **Steps (checked in the v1.17.1 source):** the controller sets every step's
  command to `/tekton/bin/entrypoint` with `-entrypoint <cmd> -- <args>`;
  scripts land in `/tekton/scripts`. A script without a shebang gets
  `#!/bin/sh` and `set -e`. `script` and `command` exclude each other. Tekton
  sets no default `workingDir`; relative ones and ones under `/workspace` are
  created by the `working-dir-initializer` init container. `stepTemplate` is
  merged by strategic merge (env by name), step wins, and is not applied to
  steps with `ref`.
- **Parameters:** array references are refused by the webhook in `script`,
  `env`, `image`, `workingDir`, `name`; in `command`/`args` they must be a whole
  item. A wrong type gives `TaskRunValidationFailed` with "param types don't
  match the user-specified type". `enable-param-enum` is `false` by default.
  `tkn task start` prompts for parameters with defaults unless
  `--use-param-defaults` is given, and for optional workspaces unless
  `--skip-optional-workspace`.
- **Results:** termination message, 4096 bytes shared by the pod. Step results
  can be referenced only in `env`, `command` and `args` (the webhook refuses
  them in `script`). A Task result can take `value: $(steps.<s>.results.<r>)`.
- **Missing Secret/ConfigMap key in `env`:** the container waits with
  `CreateContainerConfigError`; the controller fails the TaskRun with the
  reason `CreateContainerConfigError` and the message "Failed to create pod
  due to config error".
- **Workspaces:** default mount `/workspace/<name>`; pod volumes are named
  `ws-<hash>`. Unbound required workspace: `TaskRunValidationFailed`
  ("declared workspace ... is required but has not been bound"). ConfigMap
  and Secret bindings are read-only. Isolated (step-level) workspaces are
  beta and on by default (`enable-api-fields: beta`). With the default
  `coschedule: workspaces`, a TaskRun binding two different PVCs (a
  `volumeClaimTemplate` counts) fails with `TaskRunValidationFailed` ("more
  than one PersistentVolumeClaim is bound"); two bindings of the same claim
  are fine. `volumeClaimTemplate` PVCs are named `pvc-<hash>` and owned by the
  TaskRun. The kubelet creates a missing `subPath` folder. kind's default
  StorageClass `standard` is WaitForFirstConsumer.
- **Step and run states:** `terminationReason` values from the source:
  `Completed`, `Error` (Kubernetes reasons), `Skipped`, `Continued`,
  `TimeoutExceeded`, `Cancelled`. A failed step gives the run reason
  `StepFailed`; a step timeout also gives `StepFailed` with the message
  "... exited because the step exceeded the specified timeout limit" and
  fails the run even with `onError: continue`. The run timeout
  (`TaskRunTimeout`) and a cancel delete the pod. The exit code file
  `/tekton/steps/step-<name>/exitCode` is written only for steps that ended
  with 0 or with `onError: continue`.
- **Buildah (checked live in Podman, default caps):** default storage
  `overlay` via `fuse-overlayfs` fails without `/dev/fuse`; `--storage-driver=vfs`
  works; build and push in two steps need a shared volume at
  `/var/lib/containers`; push to HTTP needs `--tls-verify=false` (else "server
  gave HTTP response to HTTPS client"); `--digestfile` writes the digest
  without a newline; it equals the registry's `Docker-Content-Digest`. The
  registry refuses an OCI manifest GET without an OCI `Accept` header
  (`MANIFEST_UNKNOWN`).
- **Kaniko:** `GoogleContainerTools/kaniko` was archived in June 2025;
  Chainguard's fork (`chainguard-forks/kaniko`) publishes no free images.
  The course mentions Kaniko only to explain why it uses Buildah.
- **Many environments start broken on purpose.** The fault is the material.
  Never "fix" it in the bootstrap.

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction (see "Every course starts with an Introduction") | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab: task, walkthrough, setup, grader | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`, which is the only learner page) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` points at `question.md` and `solution.md` |
| `README.md` | Short intro for authors with `estimated_duration` front matter and the run, submit and destroy commands |
| `prerequisites.md` | What the learner needs before starting |
| `question.md` | The task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough |
| `bootstrap/01-install-tekton.sh`, `02-seed-state.sh` | The tkn CLI, Tekton Pipelines (and the registry wait in section 030), and the starting state |
| `manifests/` | `lab-start.yaml` (namespace `starfleet`; in section 030 also the registry and client pod) and the seeded objects |
| `solution/apply.sh` | Reference end state, applied only by `astrona test` |
| `testing/wait-for-tekton.sh` | Waits until the Tekton Deployments (and the registry) answer before the reference solution runs |
| `validation/validate-*.sh` | Behavioural grading, one script per check |

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS125`, domain
`Tasks, Steps & Workspaces`, weight `20`) and one entry per section under
`modules:` (`module-010`, `module-020`, `module-030`). Each section's
`content` lists, in order: the section `README.md`, then for each module its
landing page, its parts, and right after the part a lab tests, a `Question`
reading (`labs/lab-01/question.md`) followed by the `type: lab` entry; the
module's closing page comes last. The section capstone closes the section.
Playgrounds are not listed.

Every `type: lab` entry carries the same fields, in the same order, as in
ATS016: `title`, `path`, `difficulty`, `estimated_duration`, `topic`,
`task_kind`, `tags`, `learning_goals`, `resources`.

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, for example `15m`, `30m`.
- `topic`: exactly one of `task-anatomy`, `workspaces`, `step-lifecycle`,
  `image-build`.
- `task_kind`: exactly one of `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb.
- `resources`: 1 to 4 pages on `tekton.dev`, each with a `name` and a `url`
  that loads. This is the **only** place outside links are allowed.

**Tag list** (lower case, hyphens, never synonyms):

- Task anatomy: `task`, `taskrun`, `step`, `script`, `command-args`, `env`,
  `envfrom`, `secret-key-ref`, `step-template`, `compute-resources`, `params`,
  `array-params`, `results`, `step-results`, `stepaction`
- Workspaces: `workspaces`, `emptydir`, `configmap-workspace`,
  `secret-workspace`, `pvc-workspace`, `volume-claim-template`, `subpath`,
  `readonly-workspace`, `optional-workspace`, `isolated-workspace`,
  `coschedule`
- Step lifecycle: `status-conditions`, `termination-reason`, `exit-code`,
  `on-error`, `step-timeout`, `taskrun-timeout`, `exit-handler`
- Image build: `buildah`, `task-volumes`, `oci-registry`, `image-digest`,
  `tls-verify`, `tkn`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-010/module-01/playground
astrona destroy ats-125-playground-010-01   # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-125-lab-010-01

# Authors: run a local, uncommitted copy, and prove a lab passes with its reference solution
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-125-playground-<section>-<module>`, a module lab
is `ats-125-lab-<section>-<module>` and a capstone is
`ats-125-capstone-<section>`; keep those names. Lab bootstrap scripts do not
pin a kube context: astrona sets `KUBECONFIG` for the lab. Every lab must pass
`astrona validate` and `astrona test`.

Graders check **behaviour**, not just that an object exists: a TaskRun with
`Succeeded` `True`, the expected result values (exact, no newline), files in
the PersistentVolumeClaim read by a grader TaskRun, the image digest in the
registry, and a fresh TaskRun created by the grader with other values.
Graders also reject the plausible but wrong fix (an array parameter turned
into a string, a Secret changed instead of the Task, values typed into
scripts, a second PVC or a `volumeClaimTemplate`, `onError` removed so the
exit handler never runs). A lab's `question.md` and `solution.md` must match
what its `validation/` scripts actually check.

Test clusters on the maintainer's machine: one at a time. No script uses a
fixed host port; graders reach the registry through `kubectl exec` into the
client pod.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **APIs:** [Tasks](https://tekton.dev/docs/pipelines/tasks/),
  [TaskRuns](https://tekton.dev/docs/pipelines/taskruns/),
  [Workspaces](https://tekton.dev/docs/pipelines/workspaces/),
  [StepActions](https://tekton.dev/docs/pipelines/stepactions/),
  [variables](https://tekton.dev/docs/pipelines/variables/),
  [compute resources](https://tekton.dev/docs/pipelines/compute-resources/)
- **Configuration:** [additional configuration](https://tekton.dev/docs/pipelines/additional-configs/) (feature flags, `coschedule`)
- **Source at v1.17.1:** `pkg/pod/status.go` (failure reasons, termination
  reasons), `pkg/entrypoint/entrypointer.go` (onError, exit code files),
  `pkg/workspace/validate.go` (binding checks), `pkg/apis/pipeline/v1/*_validation.go`
- **CLI:** [tkn](https://tekton.dev/docs/cli/) and `docs/cmd/` in `tektoncd/cli` at `v0.46.2`
- **Buildah:** `buildah build` and `buildah push` man pages of v1.43
- **The landscape:** Tekton's page on the CNCF site,
  <https://www.cncf.io/projects/tekton/> (incubating, accepted 13 March 2026).

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository:
planning (`domain-plan`), creating the tree (`domain-scaffold`), building
modules (`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds
(`lab`), lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
