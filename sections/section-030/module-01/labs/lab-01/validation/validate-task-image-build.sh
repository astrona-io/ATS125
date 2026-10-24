#!/usr/bin/env bash
# PASS when the Task image-build in starfleet has the agreed interface:
# params IMAGE (no default), CONTEXT (default ".") and DOCKERFILE (default
# "Dockerfile"), the workspace source, the results IMAGE_DIGEST and IMAGE_URL,
# and Buildah steps with the image quay.io/buildah/stable:v1.43.5.
set -uo pipefail

NS="starfleet"
TASK="image-build"

if ! kubectl -n "$NS" get task "$TASK" >/dev/null 2>&1; then
  echo "FAIL: Task $TASK does not exist in $NS."
  exit 1
fi

params="$(kubectl -n "$NS" get task "$TASK" -o jsonpath='{.spec.params[*].name}')"
for param in IMAGE CONTEXT DOCKERFILE; do
  case " $params " in
    *" $param "*) ;;
    *) echo "FAIL: Task $TASK must declare the parameter $param (found '$params')."; exit 1 ;;
  esac
done
image_default="$(kubectl -n "$NS" get task "$TASK" -o jsonpath='{.spec.params[?(@.name=="IMAGE")].default}')"
context_default="$(kubectl -n "$NS" get task "$TASK" -o jsonpath='{.spec.params[?(@.name=="CONTEXT")].default}')"
dockerfile_default="$(kubectl -n "$NS" get task "$TASK" -o jsonpath='{.spec.params[?(@.name=="DOCKERFILE")].default}')"
if [ -n "$image_default" ] || [ "$context_default" != "." ] || [ "$dockerfile_default" != "Dockerfile" ]; then
  echo "FAIL: IMAGE must have no default, CONTEXT the default '.', DOCKERFILE the default 'Dockerfile' (found '$image_default', '$context_default', '$dockerfile_default')."
  exit 1
fi

workspaces="$(kubectl -n "$NS" get task "$TASK" -o jsonpath='{.spec.workspaces[*].name}')"
if [ "$workspaces" != "source" ]; then
  echo "FAIL: Task $TASK must declare exactly one workspace named source (found '$workspaces')."
  exit 1
fi
results="$(kubectl -n "$NS" get task "$TASK" -o jsonpath='{.spec.results[*].name}')"
for result in IMAGE_DIGEST IMAGE_URL; do
  case " $results " in
    *" $result "*) ;;
    *) echo "FAIL: Task $TASK must declare the result $result (found '$results')."; exit 1 ;;
  esac
done

images="$(kubectl -n "$NS" get task "$TASK" -o jsonpath='{.spec.steps[*].image} {.spec.stepTemplate.image}')"
case " $images " in
  *" quay.io/buildah/stable:v1.43.5 "*) ;;
  *) echo "FAIL: the steps of Task $TASK must use the image quay.io/buildah/stable:v1.43.5 (found '$images')."; exit 1 ;;
esac

echo "PASS: Task $TASK has the params IMAGE, CONTEXT, DOCKERFILE, the workspace source, the two results and Buildah steps."
exit 0
