# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Task anatomy

## Scenario

The `starfleet` team wrote the Task `crew-manifest` to list the crew of one deck. The step `collect` writes one line per crew member, the step `measure` counts the lines into the step result `lines`, and the step `report` turns the count and the deck into the result `summary`. `report` also needs a token from the Secret `report-token`. The TaskRun `crew-manifest-run` for the `engineering` deck has never worked.

## Your task

1. Find out why `crew-manifest-run` in the namespace `starfleet` fails. Each time you fix one fault, run it again and read the next failure.
2. Fix every fault. There are three, and all of them are in the Task.
3. Leave a TaskRun named `crew-manifest-run` that succeeds with these results:
   - `crew-count` = `3`
   - `summary` = `engineering: 3 crew members`

## Constraints

- Do not change the Secret `report-token`. Its key is `api-token`.
- The TaskRun `crew-manifest-run` keeps `taskRef` name `crew-manifest` and the parameters `crew` = `bridge`, `scout`, `shuttle` (an array) and `deck` = `engineering`. Do not embed the steps with `taskSpec`.
- Keep the three steps `collect`, `measure` and `report`, in that order, with the image `busybox:1.37.0`.
- The result `crew-count` keeps `value: $(steps.measure.results.lines)`. The variable `DECK` keeps coming from the `stepTemplate`.
- Do not type values into the scripts: the grader runs the Task with two crew members and `deck` = `hangar`, and expects `hangar: 2 crew members`.

## Done when

- `crew-manifest-run` uses the Task `crew-manifest` with the parameters above, ran `collect`, `measure` and `report` in that order, and its `Succeeded` condition is `True`.
- Its results are `crew-count` = `3` and `summary` = `engineering: 3 crew members`.
- The Secret `report-token` still has only the key `api-token`, and a new TaskRun with `crew` = `probe`, `scout` and `deck` = `hangar` reports `crew-count` = `2` and `summary` = `hangar: 2 crew members`.
