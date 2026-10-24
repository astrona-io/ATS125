# Overview: Write A Task From Steps, Parameters And Results (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Tekton Pipelines and the `tkn` command-line tool, and gives you an empty namespace for your own Tasks. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tekton Pipelines v1.17.1**, installed from its release manifest. Its Deployments are:

  | Deployment | Namespace | What it does |
  | --- | --- | --- |
  | `tekton-pipelines-controller` | `tekton-pipelines` | Creates one pod for each `TaskRun` and writes its status |
  | `tekton-pipelines-webhook` | `tekton-pipelines` | Sets defaults on and validates Tekton objects when they are created |
  | `tekton-events-controller` | `tekton-pipelines` | Sends CloudEvents about runs, when a sink is configured |
  | `tekton-pipelines-remote-resolvers` | `tekton-pipelines-resolvers` | Fetches Tasks from Git, bundles, Artifact Hub, URLs or other namespaces |

- The Tekton command-line tool `tkn`, version **0.46.2**, on your PATH.
- An empty namespace `starfleet` for your Tasks and TaskRuns.
- The image `busybox:1.37.0`, already loaded on the node, for your steps.

A `Task` is a list of steps with parameters and results; a `TaskRun` is one execution of it. The tekton-pipelines-controller creates one pod per `TaskRun`, with one container per step.

## Helpers

Paste these once in each new terminal. `show_steps` prints each step of a `TaskRun` with its exit code and termination reason. `show_results` prints the results of a `TaskRun` with brackets around each value, so a trailing newline is easy to see. `show_env` prints the environment variables of one step container.

```sh
show_steps() {
  kubectl get taskrun "$1" -n starfleet -o jsonpath='{range .status.steps[*]}{.name}{" exit "}{.terminated.exitCode}{" "}{.terminationReason}{"\n"}{end}'
}
show_results() {
  kubectl get taskrun "$1" -n starfleet -o jsonpath='{range .status.results[*]}{.name}{"=["}{.value}{"]"}{"\n"}{end}'
}
show_env() {
  kubectl get pod "$1-pod" -n starfleet -o jsonpath="{.spec.containers[?(@.name==\"step-$2\")].env}{\"\\n\"}"
}
```

Use them like this: `show_steps greet-1`, `show_results greet-1`, `show_env greet-1 hello`.

## Practice tasks

- Write a step with `command: ["echo"]` and `args: ["hello"]`, and a second step with the same text in a `script`. Compare the `command` of both containers in the pod.
- Write a `script` without a shebang that uses `[[ ]]`, run it on `busybox:1.37.0`, and read what the default `#!/bin/sh` and `set -e` do with it.
- Put an environment variable in `stepTemplate`, override it in one step, and print it from every step.
- Declare an `array` parameter, pass it to a step through `args: ["$(params.<name>[*])"]`, and print `$#` and `"$@"`. Then try to use it inside `script` and read the webhook's error.
- Write a result with `echo` and another with `printf '%s'`, and compare them with `show_results`.
- Give one step a step result with `$(step.results.<name>.path)` and read it in the next step through `env`.
- Set `computeResources.limits.memory` to `16Mi` on a step that runs `head -c 64m /dev/zero | tail`, and read the reason of the `TaskRun`.
