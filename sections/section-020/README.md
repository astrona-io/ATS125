# Section 020: Share Data With Workspaces

Parameters and results carry short values. Real CI/CD work, that is continuous integration and delivery, carries files: source code, settings, credentials, build caches and reports. In Tekton those files travel through workspaces, folders that a `Task` declares and a `TaskRun` fills with real storage.

This section teaches workspaces from the simplest binding to the most durable one. You first declare a workspace, use its variables and bind it to an `emptyDir`. Then you mount read-only settings from a ConfigMap and a token from a Secret, make a workspace optional and limit it to one step. Last, you keep files between runs with a PersistentVolumeClaim, use `subPath` and `volumeClaimTemplate`, and meet the rule that one `TaskRun` binds one PersistentVolumeClaim by default.

**Topic covered:** Workspaces

## What you will learn

- The fields of a workspace declaration and the workspace variables.
- `emptyDir`, ConfigMap, Secret, PersistentVolumeClaim and `volumeClaimTemplate` bindings, in YAML and with `tkn`.
- Read-only, optional and isolated workspaces.
- `subPath`, and why a wrong one does not fail.
- The life of a PersistentVolumeClaim made from a template, and the one-PersistentVolumeClaim rule.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The module also has its own playground, a cluster where you can explore freely, and the landing page starts it for you.

### 1. Share Files With Workspaces

The module starts at its landing page, which also launches the playground. The playground runs Tekton Pipelines v1.17.1, the `tkn` command-line tool and an empty namespace `starfleet`, with kind's default StorageClass for your PersistentVolumeClaims.

1. Declare Workspaces And Bind An emptyDir
2. ConfigMap And Secret Workspaces
3. Persistent Workspaces With PersistentVolumeClaims, followed by the lab **Bind Workspaces To A TaskRun**
4. Summary

## Section capstone: Repair The Workspaces Of A Report Task

The capstone is one graded scenario that combines the whole module. The `deck-report` Task of the `starfleet` team adds a weekly line to a history file in a PersistentVolumeClaim, and its TaskRun fails: it binds two PersistentVolumeClaims, the Task declares its output read-only, and the history sits in a different folder than the run uses. Find each fault, fix the Task and the TaskRun, and prove that the history grew by one line. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS125.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-125-capstone-020
```
