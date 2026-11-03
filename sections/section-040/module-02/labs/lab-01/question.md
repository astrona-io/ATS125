# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Reading status and debugging a Task

## Scenario

The `starfleet` team packs an orbit report with the Task `archive`. The TaskRun `archive-run` failed, and nobody knows which step broke or why. You must record the diagnosis and deliver a fixed Task.

## Your task

1. Read the status of the TaskRun `archive-run` in the namespace `starfleet`. Find the step that failed and its exit code.
2. Create the ConfigMap `archive-diagnosis` with the keys `failedStep` (the name of the failed step) and `exitCode` (its exit code).
3. Write a corrected copy of the Task named `archive-fixed`. After the fix, it must give one string result `size` that holds the number of bytes of the report.
4. Create the TaskRun `archive-fixed-run` for `archive-fixed`.

## Constraints

- Do not change the Task `archive`.
- The report text is the one the Task `archive` writes.
- The result must have no newline at the end.
- Use `taskRef` in the TaskRun.

## Done when

- The ConfigMap `archive-diagnosis` matches the failed step and exit code of `archive-run`.
- `archive-fixed-run` succeeded with `size` = `12`.
