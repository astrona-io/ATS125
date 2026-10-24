# ConfigMap And Secret Workspaces

Many Tasks need input they must not change: a settings file, a list of allowed values, a token for a registry or an API. Kubernetes keeps such data in ConfigMaps and Secrets. A workspace can mount either of them as a folder of files, one file per key. This part binds both, makes a workspace read-only, makes one optional, and limits a Secret to the one step that needs it.

## Bind a ConfigMap

A ConfigMap binding looks like a ConfigMap volume in a pod: `configMap` with the `name` of the ConfigMap, and optional `items` to pick keys. Every key becomes a file in the workspace folder. The `Task` below reads the file `deck` from the workspace `settings`, which it declares `readOnly: true` because it never writes there.

<!-- astrona:playground:renew -->

Save this as `configmap-checklist-settings.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: checklist-settings
  namespace: starfleet
data:
  deck: bridge
  checks: |
    engines
    shields
    sensors
```

Apply it:

```sh
kubectl apply -f configmap-checklist-settings.yaml
```

Save this as `task-checklist.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: checklist
  namespace: starfleet
spec:
  workspaces:
    - name: settings
      description: Checklist settings; the keys deck and checks
      readOnly: true
      mountPath: /etc/checklist
    - name: token
      description: Optional API token; the key token
      optional: true
  results:
    - name: summary
  steps:
    - name: run-checks
      image: busybox:1.37.0
      script: |
        #!/bin/sh
        set -eu
        ls -l "$(workspaces.settings.path)"
        deck="$(cat "$(workspaces.settings.path)/deck")"
        count="$(grep -c . "$(workspaces.settings.path)/checks")"
        printf '%s: %s checks' "$deck" "$count" | tee "$(results.summary.path)"
        echo
        echo "try to write" > "$(workspaces.settings.path)/note.txt" || echo "settings is read-only"
    - name: upload
      image: busybox:1.37.0
      workspaces:
        - name: token
      script: |
        #!/bin/sh
        set -eu
        if [ "$(workspaces.token.bound)" = "true" ]; then
          echo "Uploading with a token of $(wc -c < "$(workspaces.token.path)/token") bytes"
        else
          echo "No token bound; skipping the upload"
        fi
```

Apply it:

```sh
kubectl apply -f task-checklist.yaml
```

Then run it with only the ConfigMap bound. `tkn` uses `config=` for a ConfigMap binding:

```sh
tkn task start checklist -n starfleet -w name=settings,config=checklist-settings --skip-optional-workspace --showlog
```

`run-checks` lists the files `deck` and `checks` in `/etc/checklist`, prints `bridge: 3 checks`, and then prints `settings is read-only`: the write failed. `upload` prints that no token is bound. The run succeeds, because `token` is optional.

A ConfigMap or Secret volume is always read-only in Kubernetes, with or without `readOnly` in the declaration. `readOnly: true` matters most for writable volumes such as a PersistentVolumeClaim: it tells Tekton to mount the volume read-only, so the `Task` cannot change it by accident. A ConfigMap must exist before the `TaskRun` starts. If it is missing, the kubelet cannot mount the volume and the pod waits.

## Optional workspaces

`optional: true` lets the `TaskRun` leave a workspace out. The steps then see `$(workspaces.<name>.bound)` as `false` and `$(workspaces.<name>.path)` as an empty string, so they must check `bound` before they use the path. A good use is a credential that only some callers have, or a cache that speeds things up when it is there. The `default-task-run-workspace-binding` key of the ConfigMap `config-defaults` can give required workspaces a default binding; optional workspaces never get it.

## Bind a Secret to one step only

A Secret binding uses `secret` with `secretName`, the same as a Secret volume in a pod. Every key becomes a file. In the `Task` above, the step `upload` lists `token` under its own `workspaces`. That makes `token` an isolated workspace: Tekton mounts it only into the steps that list it, and every other step cannot see the files. Isolated workspaces are a beta feature, and the default `enable-api-fields: "beta"` of Tekton Pipelines v1.17.1 switches it on.

Save this as `secret-checklist-token.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: checklist-token
  namespace: starfleet
type: Opaque
stringData:
  token: lab-only-token
```

Apply it:

```sh
kubectl apply -f secret-checklist-token.yaml
```

Then run the `Task` with both bindings, and look at the mounts of each step container. Use the name of the `TaskRun` that `tkn` prints in place of `<NAME>`:

```sh
tkn task start checklist -n starfleet -w name=settings,config=checklist-settings -w name=token,secret=checklist-token --showlog
kubectl get pod <NAME>-pod -n starfleet -o jsonpath='{range .spec.containers[*]}{.name}{": "}{range .volumeMounts[*]}{.mountPath}{" "}{end}{"\n"}{end}'
```

`upload` now prints the size of the token. Both containers mount `/etc/checklist`, but only `step-upload` mounts `/workspace/token`. An image you do not fully trust in `run-checks` could not read the token.

Workspaces are not the only way to give a step a Secret. `env` with `secretKeyRef` puts one key into an environment variable, which every process in the container can read and which may end up in a log. A Secret workspace gives the step a file, and an isolated workspace limits it to one step. Prefer files for credentials.

You can now give a `Task` read-only settings from a ConfigMap, make a workspace optional, and limit a Secret to one step. The open question is storage that outlives the pod, so that one `TaskRun` can read what another one wrote.

## Common pitfalls

> [!WARNING]
> - **Writing to a ConfigMap or Secret workspace.** It is always read-only. Write to a separate, writable workspace.
> - **`name` for a Secret binding.** A Secret binding uses `secretName`; a ConfigMap binding uses `name`.
> - **Using the path of an optional workspace without checking `bound`.** The path is empty when nothing is bound.
> - **A ConfigMap or Secret that does not exist yet.** The pod cannot mount it and waits. Create it before the `TaskRun`.
> - **Expecting the isolated workspace in every step.** Only the steps that list it under `workspaces` mount it.
