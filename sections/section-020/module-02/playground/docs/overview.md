# Overview: Task Volumes And Sidecars (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Tekton Pipelines and the `tkn` command-line tool, and gives you an empty namespace for your own Tasks. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tekton Pipelines v1.17.1**, installed from its release manifest.
- The Tekton command-line tool `tkn`, version **0.46.2**, on your PATH.
- An empty namespace `starfleet`.
- The image `busybox:1.37.0`, already loaded on the node.

## Helpers

`show_containers` prints the containers of the pod of a `TaskRun` with their images. `show_sidecars` prints the sidecars in the status.

```sh
show_containers() {
  kubectl get pod "$1-pod" -n starfleet -o jsonpath='{range .spec.containers[*]}{.name}{" "}{.image}{"\n"}{end}'
}
show_sidecars() {
  kubectl get taskrun "$1" -n starfleet -o jsonpath='{range .status.sidecars[*]}{.name}{" "}{.terminated.reason}{"\n"}{end}'
}
```

## Practice tasks

- Write a file to `/tmp` in one step and read it in the next. Then move it to `/workspace`.
- Mount one `emptyDir` in two steps at different paths and write in one, read in the other.
- Mount a ConfigMap as a volume and change a key. Does a running step see the change?
- Declare an optional workspace and print `$(workspaces.<name>.bound)` with and without a binding.
- Run a sidecar with `httpd` and call it from a step with and without a retry loop. Compare the logs.
- Make the sidecar exit with an error and read the reason of the `TaskRun`.
- Add `sidecarSpecs` with a small memory limit to a `TaskRun` and read the container's resources.
