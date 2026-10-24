# Section 010: Write Tasks With Steps, Parameters And Results

Every piece of work in Tekton is described by a `Task`. Builds, tests, scans and deployments are all lists of steps with inputs and outputs. Before you can share files between steps, build images or handle failures, you must be able to read and write the `Task` itself: what each step runs, which values it gets, and what it hands back.

This section teaches that anatomy. You first take a step apart: its image, `command` and `args` or `script`, its environment and working directory, and the `stepTemplate` that sets values for every step. Then you pass parameters of the types `string`, `array` and `object` into a `Task`. Last, you write Task results and step results, and learn the limits that come with them.

**Topic covered:** Task anatomy

## What you will learn

- The fields of a step, and what the entrypoint binary does with `command`, `args` and `script`.
- The default shebang of a `script`, and why every step needs a `command` or a `script`.
- Environment variables with `env`, `valueFrom` and `envFrom`, the working directory, `computeResources`, and the `stepTemplate`.
- `StepAction` objects, used from a step with `ref`.
- Parameter types `string`, `array` and `object`, defaults, and where each type may appear.
- Task results, their 4096-byte limit, and step results passed from one step to a later one.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Write A Task From Steps, Parameters And Results

The module starts at its landing page, which also launches the playground. The playground runs Tekton Pipelines v1.17.1, the `tkn` command-line tool and an empty namespace `starfleet` for your Tasks.

1. Steps: Image, Command, Script And Environment
2. Parameters: Types, Defaults And Safe Substitution
3. Results From Tasks And From Steps, followed by the lab **Repair A Task's Parameters, Environment And Results**
4. Summary

## Section capstone: Repair A Task Built From Steps, Parameters And Results

The capstone is one graded scenario that combines the whole module. The `crew-manifest` Task of the `starfleet` team has never worked: one step cannot start because it reads a Secret key that does not exist, another uses a shell the image does not have, and the `stepTemplate` ignores a parameter. Find each fault from the TaskRun status, the pod and the step logs, fix the Task, and prove the fix with a TaskRun that reports the right results. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-125-capstone-010
```
