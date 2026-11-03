# Overview: Reuse Steps With StepActions (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Tekton Pipelines and the `tkn` command-line tool, and gives you an empty namespace for your own StepActions and Tasks. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tekton Pipelines v1.17.1**, installed from its release manifest. The tekton-pipelines-controller creates one pod for each `TaskRun`, the tekton-pipelines-webhook validates Tekton objects, and the remote resolvers in `tekton-pipelines-resolvers` fetch definitions from outside the cluster.
- The Tekton command-line tool `tkn`, version **0.46.2**, on your PATH.
- An empty namespace `starfleet`.
- The image `busybox:1.37.0`, already loaded on the node.

## Helpers

Paste these once in each new terminal. `show_steps` prints each step of a `TaskRun` with its exit code and termination reason. `show_results` prints the results of a `TaskRun` with brackets around each value.

```sh
show_steps() {
  kubectl get taskrun "$1" -n starfleet -o jsonpath='{range .status.steps[*]}{.name}{" exit "}{.terminated.exitCode}{" "}{.terminationReason}{"\n"}{end}'
}
show_results() {
  kubectl get taskrun "$1" -n starfleet -o jsonpath='{range .status.results[*]}{.name}{"=["}{.value}{"]"}{"\n"}{end}'
}
```

## Practice tasks

- Write a `StepAction` with a `script`, use it from two steps of one Task, and compare the two containers in the pod.
- Apply a Task whose `ref.name` does not exist, start a run, and read the reason and message of the `Succeeded` condition.
- Add a `message` parameter without a default, leave it out in the step, and read what the `TaskRun` reports.
- Add a step result `line`, read it in a later step through `env`, and expose it as a Task result with `value`.
- Set `timeout`, `onError` and `computeResources` on a step with `ref`, and check them on the container.
- Add `image` to a step with `ref` and run `kubectl apply --dry-run=server` to read the webhook error.
