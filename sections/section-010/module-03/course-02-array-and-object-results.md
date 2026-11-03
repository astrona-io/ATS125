# Array And Object Results

A Task that lists the files it created or reports the URL and the digest of an image has more than one value to return. A result can hold a list or a set of named values, not only a string. This part declares array and object results, writes them as JSON, and reads them from the status of the `TaskRun`.

## Declare the result types

A Task result has a `type`: `string` (the default), `array` or `object`. An object result also lists its `properties`, as an object parameter does. Array and object results are beta features in Tekton Pipelines v1.17.1 and work with the default setting `enable-api-fields: beta`.

The step writes the value as a JSON text into the result file. A JSON array looks like `["a","b"]` and a JSON object like `{"url":"u","digest":"d"}`. Tekton reads the file and checks it against the declared type.

<!-- astrona:playground:renew -->

Save this as `task-image-facts.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: image-facts
  namespace: starfleet
spec:
  params:
    - name: app
      type: string
  results:
    - name: tags
      type: array
      description: Tags of the image
    - name: image
      type: object
      description: The image location
      properties:
        url:
          type: string
        digest:
          type: string
  steps:
    - name: write
      image: busybox:1.37.0
      env:
        - name: APP
          value: $(params.app)
      script: |
        #!/bin/sh
        set -eu
        printf '["%s","latest"]' "$APP" > "$(results.tags.path)"
        printf '{"url":"registry.local/%s","digest":"sha256:0000"}' "$APP" > "$(results.image.path)"
```

Apply it and run it:

```sh
kubectl apply -f task-image-facts.yaml
tkn task start image-facts -n starfleet -p app=bridge --showlog
```

The step prints nothing, because it only writes result files.

## Read the results from the status

The status of the `TaskRun` keeps the result with its type. Read both results:

```sh
kubectl get taskrun -n starfleet -l tekton.dev/task=image-facts -o jsonpath='{range .items[0].status.results[*]}{.name}{" ("}{.type}{") = "}{.value}{"\n"}{end}'
```

The array result prints as a list with the items `bridge` and `latest`. The object result prints as a map with the keys `url` and `digest`. Each line also shows the type that Tekton recorded.

Read one item with an index into the JSON, in the same way as any JSON value:

```sh
kubectl get taskrun -n starfleet -l tekton.dev/task=image-facts -o jsonpath='{.items[0].status.results[?(@.name=="tags")].value[0]}{"\n"}'
```

It prints the first tag, `bridge`.

## What goes wrong

Tekton checks the result against its declared type. If a step writes text that is not valid JSON, or a JSON object where the Task declared an array, the `TaskRun` fails with a result error, although the step itself exited with code 0. An object result must also contain every key that `properties` lists. If a key is missing, the run fails.

An empty array written as `[]` is treated as a result that was never set. A Task that may return no items should write a marker, or the consumer should handle the missing result.

Array and object results share the same 4096-byte limit as all other results of a pod. A long list belongs in a workspace file, with only the file name in the result.

You can now return structured values and read them back. The open question is how a Task refers to the run it belongs to, and how it reads single items of an array parameter.

## Common pitfalls

> [!WARNING]
> - **A result file that is not JSON.** An array or object result must be valid JSON. Use `printf` with double quotes around every string.
> - **`echo` adding a newline.** The newline is white space in JSON and is accepted, but keep `printf` as the habit for string results.
> - **A missing key in an object result.** Every key in `properties` must appear in the JSON.
> - **Returning `[]`.** An empty array counts as uninitialized.
> - **Long lists.** All results of a pod share about 4096 bytes. Write long data to a workspace.
