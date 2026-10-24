# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Workspaces

## Scenario

Every week the `starfleet` team adds one line to its report history with the Task `deck-report`. The history lives in the file `history.txt` in the folder `reports` of the PersistentVolumeClaim `report-data`, and it already holds two lines. The step `render` writes the new line into the workspace `cache`, and the step `append` adds it to the history and counts the lines into the result `entries`. The TaskRun `deck-report-run` for 2026-10-15 fails.

## Your task

1. Find out why `deck-report-run` in the namespace `starfleet` fails. Each time you fix one fault, run it again and read the next failure.
2. Fix every fault. There are three, in the TaskRun and in the Task. One of them does not make the run fail.
3. Leave a TaskRun named `deck-report-run` that succeeds and adds `2026-10-15 engineering: ok` to `reports/history.txt` in `report-data`.

## Constraints

- The TaskRun keeps `taskRef` name `deck-report` and the parameter `run-date` = `2026-10-15`.
- The workspace `output` stays bound to `report-data`. Nothing in `cache` needs to persist. Do not create new PersistentVolumeClaims, and do not change the feature flags of Tekton.
- The workspace `config` stays read-only. Do not change the steps of the Task.
- Do not edit `history.txt` by hand.

## Done when

- `deck-report-run` uses the Task `deck-report` with `run-date` = `2026-10-15`, binds `output` to `report-data` with the `subPath` `reports`, binds no other PersistentVolumeClaim, and its `Succeeded` condition is `True`.
- `reports/history.txt` in `report-data` still starts with the two earlier lines, holds the line `2026-10-15 engineering: ok`, and has as many lines as the result `entries` of `deck-report-run` (at least 3).
- The Task declares `output` writable and `config` read-only, and a new TaskRun of it with `emptyDir` volumes for `output` and `cache` succeeds with `entries` = `1`.
