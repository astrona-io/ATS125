# Summary

Workspaces split one decision in two. The `Task` says which folders it needs and where; the `TaskRun` says which storage fills them. The same `Task` can run on an `emptyDir` for a quick test and on a PersistentVolumeClaim for real work.

## What you learned

A `Task` declares a workspace with a `name`, and optionally a `description`, a `mountPath` (default `/workspace/<name>`), `readOnly` and `optional`. Steps use `$(workspaces.<name>.path)` instead of a fixed path, `$(workspaces.<name>.bound)` to check an optional workspace, and `$(workspaces.<name>.claim)` to name the PVC behind it. A required workspace without a binding, or a binding without a declaration, fails the run with `TaskRunValidationFailed` before a pod exists.

A `TaskRun` binds each workspace to one volume. An `emptyDir` lives as long as the pod and suits files shared by the steps of one run. A ConfigMap (`name`) or a Secret (`secretName`) gives one file per key and is always read-only. An existing PVC (`claimName`) keeps files between runs, and `subPath` limits it to one folder; a missing folder is created empty. A `volumeClaimTemplate` makes a new PVC for each run, owned by the `TaskRun` and deleted with it. A workspace listed under one step's `workspaces` is mounted into that step only.

`readOnly: true` makes Tekton mount even a writable volume read-only, so a `Task` that writes there fails. With the default `coschedule: workspaces`, a `TaskRun` may bind only one PVC; two workspaces can share one claim through different `subPath` values. The key facts to remember are these:

- The `Task` declares, the `TaskRun` binds.
- ConfigMap and Secret workspaces are read-only; `readOnly` makes any workspace read-only.
- A wrong `subPath` gives an empty folder, not an error.
- One PVC per `TaskRun` by default; a `volumeClaimTemplate` counts too.

<!-- astrona:playground:destroy -->
