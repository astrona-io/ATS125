# Overview: Object Parameters, Array Results And Context Variables (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Tekton Pipelines and the `tkn` command-line tool, and gives you an empty namespace for your own Tasks. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tekton Pipelines v1.17.1**, installed from its release manifest.
- The Tekton command-line tool `tkn`, version **0.46.2**, on your PATH.
- An empty namespace `starfleet`.
- The image `busybox:1.37.0`, already loaded on the node.

## Helpers

`show_results` prints the results of a `TaskRun` with their type and brackets around each value.

```sh
show_results() {
  kubectl get taskrun "$1" -n starfleet -o jsonpath='{range .status.results[*]}{.name}{" ("}{.type}{") =["}{.value}{"]"}{"\n"}{end}'
}
```

## Practice tasks

- Declare an object parameter with three keys and a default for one key. Run it with the other two keys, then leave one out and read the condition.
- Write an array result with `printf` and read it with `show_results`. Then write text that is not JSON and read the reason of the failed run.
- Declare an object result with two keys and write only one. Read the failure.
- Print `$(context.taskRun.uid)` and `$(context.taskRun.retry-count)` from a step.
- Add `retries: 1` to a `TaskRun` of a Task that exits with 1 in the first attempt, and print `$(context.taskRun.retry-count)` in each attempt.
- Run `tkn task start <task> --dry-run` and read the `TaskRun` it prints.
