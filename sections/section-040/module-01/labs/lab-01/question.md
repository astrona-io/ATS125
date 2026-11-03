# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** TaskRun timeout and retries

## Scenario

The `starfleet` team syncs data from a remote station with the Task `flaky-sync`. The station answers only after a few tries. A TaskRun named `flaky-sync-failed` already ran without retries and failed. The team wants a run that survives the early failures and cannot hang.

## Your task

1. Find out why `flaky-sync-failed` failed. Read its condition and the log of its pod.
2. Create the TaskRun `flaky-sync-run` for the Task `flaky-sync` in the namespace `starfleet`.
3. Give it enough retries for the Task to succeed, and a timeout for each attempt.

## Constraints

- Do not change the Task `flaky-sync`, and do not delete `flaky-sync-failed`.
- Use `taskRef` in the TaskRun.
- Set the timeout to more than zero and to no more than 10 minutes.

## Done when

- `flaky-sync-run` succeeded and its status records two failed attempts.
- Its `spec.retries` is 2 or more and its `spec.timeout` is set.
- Its result `attempt` is `2`.
