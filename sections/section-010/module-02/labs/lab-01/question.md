# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** StepActions

## Scenario

The `starfleet` team wants every launch checklist to write its log line in the same format. The `StepAction` `compose-line` in the namespace `starfleet` already composes a line from a prefix and a message and returns it as the step result `line`. No Task uses it yet.

## Your task

1. Read the `StepAction` `compose-line`: its parameters and its result.
2. Write the Task `launch-log` in `starfleet`. It takes one string parameter `message`, runs the `StepAction` in a step named `compose`, and reports the line as a Task result named `entry`.
3. Create the TaskRun `launch-log-run` for the Task with the message `engines online`.

## Constraints

- The step `compose` must use the `StepAction` with `ref`. Do not copy its script or image into the Task.
- The prefix of the line must be `launch`. The Task must pass it to the `StepAction`.
- The message must come from the Task parameter `message`, not from text typed into the step.
- The TaskRun must use `taskRef` for the Task `launch-log`.

## Done when

- The Task `launch-log` has the step `compose` with `ref.name` `compose-line` and no `image` or `script` in that step.
- The TaskRun `launch-log-run` succeeded and reports `entry` = `launch: engines online`, with no newline at the end.
- A new TaskRun of `launch-log` with any other message succeeds and reports `entry` = `launch: <that message>`.
