# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Parameters and results

## Scenario

The `starfleet` team keeps a registry card for every ship. Nobody has written the Task that builds the card yet. The card holds the name and the class of the ship, a list of tags, and the name of the run that produced it, so that an audit can find the run later.

## Your task

1. Write the Task `ship-card` in the namespace `starfleet`.
2. Give it one `object` parameter named `ship` with the string keys `name` and `class`. Neither key has a default.
3. Give it three results:
   - `card` (a string): `<name>/<class>`, for example `bridge/flagship`.
   - `tags` (an array): the two items `<name>` and `<class>`, in that order.
   - `run-name` (a string): the name of the `TaskRun` that ran the Task.
4. Create the TaskRun `ship-card-run` for the Task with `name` = `bridge` and `class` = `flagship`.

## Constraints

- The values must come from the parameter. Do not type `bridge` or `flagship` into the Task.
- The name of the run must come from the `context` variables of Tekton, not from text typed into the Task.
- Use `taskRef` in the TaskRun. Do not embed the steps with `taskSpec`.
- Results must have no newline at the end.

## Done when

- The TaskRun `ship-card-run` succeeded with `card` = `bridge/flagship`, `tags` = `["bridge","flagship"]` and `run-name` = `ship-card-run`.
- A new TaskRun of `ship-card` with another ship succeeds, and its `card`, `tags` and `run-name` match its own values.
