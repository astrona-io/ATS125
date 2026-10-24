# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Workspaces

## Scenario

The `starfleet` team keeps the crew list of each deck in the PersistentVolumeClaim `roster-data`: the file `crew.txt` of the `bridge` deck sits in the folder `bridge`, and the one of the `scout` deck in the folder `scout`. The Task `crew-roster` reads a crew list, writes `roster.txt` next to it and signs it when it gets a token. Nobody has run it yet for the `bridge` deck.

## Your task

Read the three workspaces of the Task `crew-roster` in the namespace `starfleet`. Then create a TaskRun named `crew-roster-run` that binds them:

- `source`: the PersistentVolumeClaim `roster-data`, limited to its folder `bridge`.
- `settings`: the ConfigMap `roster-settings`.
- `token`: the Secret `roster-token`, so that the roster gets signed.

## Constraints

- Do not change the Task `crew-roster`, the ConfigMap `roster-settings` or the Secret `roster-token`.
- Refer to the Task with `taskRef`; do not embed it with `taskSpec`.
- Do not copy the files to another volume. `roster.txt` must end up in the folder `bridge` of `roster-data`.

## Done when

- The TaskRun `crew-roster-run` in `starfleet` uses the Task `crew-roster`, binds `source` to `roster-data` with the `subPath` `bridge`, `settings` to the ConfigMap `roster-settings` and `token` to the Secret `roster-token`, and its `Succeeded` condition is `True`.
- Its results are `roster` = `bridge: 3 crew members` and `signed` = `true`.
- The folder `bridge` of `roster-data` holds `roster.txt` (first line `deck: bridge`, four lines in all) and `roster.sig`.
