# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Volumes and sidecars

## Scenario

The `starfleet` team wants to test a status page in the same pod as the test. A small web server must serve a status file, and a step must download the file from the server and report what it got.

## Your task

1. Write the Task `status-reader` in the namespace `starfleet`.
2. Give it one string parameter `message` with the default `all systems nominal`, and one string result `body`.
3. Declare an `emptyDir` volume in the Task. Run a sidecar named `server` that serves the folder of that volume over HTTP on port `8080`.
4. Add the step `publish`, which writes the value of `message` to the file `status.txt` in that folder, and the step `fetch`, which downloads `http://127.0.0.1:8080/status.txt` and writes the answer to the result `body`.
5. Create the TaskRun `status-reader-run` for the Task without any parameter.

## Constraints

- Use `busybox:1.37.0` for the sidecar and the steps. Its `httpd` applet is the web server.
- The sidecar and the step `publish` must mount the same volume.
- The step `fetch` must retry, because the sidecar may not listen yet.
- The result must have no newline at the end. Do not type the message into the step `fetch`.
- Use `taskRef` in the TaskRun.

## Done when

- The Task has a sidecar named `server`, a volume, and the steps `publish` and `fetch`, in that order.
- The TaskRun `status-reader-run` succeeded with `body` = `all systems nominal`.
- A new TaskRun of `status-reader` with the message `docking complete` succeeds with `body` = `docking complete`.
