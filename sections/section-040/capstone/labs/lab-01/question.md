# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** TaskRun settings and debugging

## Scenario

The `starfleet` team produces a nightly report with the Task `nightly-report`. Three TaskRuns need attention. `nightly-report-timeout` failed. `nightly-report-runaway` was started with a delay of one hour and still runs. `nightly-report-held` was created in the pending state and waits to be released. The team also wants a safe run that survives a busy station.

## Your task

1. Read why `nightly-report-timeout` failed. Create the ConfigMap `nightly-diagnosis` with the key `reason`, set to the reason of its `Succeeded` condition.
2. Stop `nightly-report-runaway` without deleting it.
3. Release `nightly-report-held` so that it runs and succeeds.
4. Create the TaskRun `nightly-report-retry` for `nightly-report` with the parameter `flaky` set to `true`. The first attempt of that Task fails on purpose. Give the run retries so it succeeds, a timeout of at most 10 minutes, and a memory limit for the step `publish`.

## Constraints

- Do not change the Task `nightly-report`, and do not delete any of the three seeded TaskRuns.
- Use `taskRef` in the new TaskRun.
- The memory limit must be set through the TaskRun, not through the Task.

## Done when

- The ConfigMap `nightly-diagnosis` holds the reason of `nightly-report-timeout`.
- `nightly-report-runaway` ended with the reason `TaskRunCancelled`.
- `nightly-report-held` has no `spec.status`, succeeded, and reports `nightly report attempt 0`.
- `nightly-report-retry` succeeded and reports `nightly report attempt 1`.
