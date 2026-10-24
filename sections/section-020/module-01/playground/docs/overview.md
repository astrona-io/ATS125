# Overview: Share Files With Workspaces (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Tekton Pipelines and the `tkn` command-line tool, and gives you an empty namespace for your own Tasks. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The default StorageClass `standard`. Its provisioner creates a PersistentVolume (PV) as a folder on the node the first time a pod uses a PersistentVolumeClaim (PVC).
- **Tekton Pipelines v1.17.1** in the namespaces `tekton-pipelines` and `tekton-pipelines-resolvers`.
- The Tekton command-line tool `tkn`, version **0.46.2**, on your PATH.
- An empty namespace `starfleet` for your Tasks, TaskRuns, ConfigMaps, Secrets and PVCs.
- The image `busybox:1.37.0`, already loaded on the node, for your steps.

A workspace is a folder that a `Task` declares and a `TaskRun` fills with a real volume: an `emptyDir`, a ConfigMap, a Secret, a PVC or a PVC created from a `volumeClaimTemplate`.

## Helpers

Paste these once in each new terminal. `show_bindings` prints the workspace bindings of a `TaskRun`. `show_mounts` prints the mount paths of each step container of a `TaskRun`. `show_pvcs` lists the PVCs in `starfleet` with their owner, so you can see which ones Tekton created.

```sh
show_bindings() {
  kubectl get taskrun "$1" -n starfleet -o jsonpath='{range .spec.workspaces[*]}{.name}{": "}{.persistentVolumeClaim.claimName}{.configMap.name}{.secret.secretName}{" subPath="}{.subPath}{"\n"}{end}'
}
show_mounts() {
  kubectl get pod "$1-pod" -n starfleet -o jsonpath='{range .spec.containers[*]}{.name}{": "}{range .volumeMounts[*]}{.mountPath}{" "}{end}{"\n"}{end}'
}
show_pvcs() {
  kubectl get pvc -n starfleet -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,OWNER:.metadata.ownerReferences[0].name
}
```

Use them like this: `show_bindings share-1`, `show_mounts share-1`, `show_pvcs`.

## Practice tasks

- Run a Task with a workspace once with an `emptyDir` and once with a PVC. Run it twice with each, and check which one keeps a file between runs.
- Bind a ConfigMap as a workspace and try to write into it. Read the step log.
- Declare a workspace `optional: true` and print `$(workspaces.<name>.bound)` and `$(workspaces.<name>.path)` with and without a binding.
- Bind two workspaces to the same PVC with different `subPath` values, then to two different PVCs, and compare the conditions of the two TaskRuns.
- Use a `volumeClaimTemplate`, list the PVCs with `show_pvcs`, delete the TaskRun and list them again.
- Isolate a Secret workspace to one step with `workspaces:` under that step, and check with `show_mounts` which containers mount it.
