# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Task anatomy

## Scenario

The `starfleet` team uses the Task `image-tag` to work out where the image of an app will live. The step `compose` builds the image reference from the registry address, the app and the version, and the step `count-labels` counts the labels the image will get. The registry address belongs in one place only: the `stepTemplate`. Today the TaskRun `image-tag-run` for the `bridge` app failed, and the team suspects that more is wrong than the failure shows.

## Your task

1. Find out why the TaskRun `image-tag-run` in the namespace `starfleet` failed. Read its `Succeeded` condition first.
2. Fix every fault, in the `TaskRun` and in the `Task`. There are three. Some only show once the run gets further.
3. Leave a TaskRun named `image-tag-run` that succeeds with these results:
   - `image-ref` = `registry.registry.svc.cluster.local:5000/starfleet/bridge:2.1`
   - `label-count` = `2`

## Constraints

- Keep the name `image-tag-run`. The TaskRun must refer to the Task `image-tag` with `taskRef`; do not embed the steps with `taskSpec`.
- The TaskRun passes `app` = `bridge`, `version` = `2.1` and the two labels `team=bridge` and `tier=web`.
- Do not change the parameters or results of the Task. `labels` stays an `array` parameter.
- The registry address must come from the `stepTemplate` only. No step may set its own `REGISTRY` variable.
- Keep the two steps `compose` and `count-labels`, in that order. Do not type the count into the script: the grader runs the Task with three labels and expects `3`.

## Done when

- The TaskRun `image-tag-run` in `starfleet` uses the Task `image-tag`, passes `labels` as an array of two items, and its `Succeeded` condition is `True`.
- Its results are exactly `image-ref` = `registry.registry.svc.cluster.local:5000/starfleet/bridge:2.1` and `label-count` = `2`, with no newline at the end.
- A new TaskRun of `image-tag` with `app` = `probe`, no `version` and three labels succeeds with `image-ref` = `registry.registry.svc.cluster.local:5000/starfleet/probe:1.0` and `label-count` = `3`.
