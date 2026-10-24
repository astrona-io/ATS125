# Overview: Control Step Failures And Build An Image (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Tekton Pipelines, an OCI registry inside the cluster and the source of a small app in a PersistentVolumeClaim. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Tekton Pipelines v1.17.1** and the Tekton command-line tool `tkn`, version **0.46.2**.
- An OCI registry (Distribution `registry:3.1.2`) in the namespace `registry`, reachable inside the cluster at `registry.registry.svc.cluster.local:5000`. It speaks plain HTTP and has no login, which is fine for a lab and nowhere else.
- A pod `client` with `curl` in the namespace `registry`, to call the registry API from inside the cluster.
- The PersistentVolumeClaim `bridge-source` in `starfleet`, with `bridge-app/Dockerfile` and `bridge-app/message.txt`.
- The images `busybox:1.37.0` and `quay.io/buildah/stable:v1.43.5`, already loaded on the node.

To browse the registry from your machine, run `kubectl -n registry port-forward svc/registry 5000:5000` in a second terminal and open `http://localhost:5000/v2/_catalog`. Pick another local port if 5000 is taken.

## Helpers

Paste these once in each new terminal. `show_steps` prints each step of a `TaskRun` with its exit code and termination reason. `registry_tags` lists the tags of one repository. `registry_digest` prints the manifest digest of one tag.

```sh
show_steps() {
  kubectl get taskrun "$1" -n starfleet -o jsonpath='{.status.conditions[0].reason}{"\n"}{range .status.steps[*]}{.name}{" exit "}{.terminated.exitCode}{" "}{.terminationReason}{"\n"}{end}'
}
registry_tags() {
  kubectl -n registry exec deploy/client -- curl -s "http://registry.registry.svc.cluster.local:5000/v2/$1/tags/list"
}
registry_digest() {
  kubectl -n registry exec deploy/client -- curl -s -I -H 'Accept: application/vnd.oci.image.manifest.v1+json' "http://registry.registry.svc.cluster.local:5000/v2/$1/manifests/$2" | grep -i docker-content-digest
}
```

Use them like this: `show_steps build-1`, `registry_tags starfleet/bridge-app`, `registry_digest starfleet/bridge-app 1.0`.

## Practice tasks

- Write a step that runs `exit 3` with `onError: continue`, and a next step that prints `$(steps.step-<name>.exitCode.path)`. Then remove `onError` and compare `show_steps`.
- Give a step `timeout: 5s` and a script that sleeps for 30 seconds. Read the step's termination reason and the message of the condition.
- Set the `timeout` of a `TaskRun` to `10s` with a step that sleeps for a minute, and check whether the pod still exists afterwards.
- Create a `TaskRun` with `spec.status: TaskRunPending`, read its condition, then remove the field and watch it start.
- Run Buildah without `--storage-driver=vfs`, and then push without `--tls-verify=false`, and read each error.
- Build the same source twice with two tags and compare the digests with `registry_digest`.
