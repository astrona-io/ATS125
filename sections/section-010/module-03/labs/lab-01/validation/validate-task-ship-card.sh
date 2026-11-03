#!/usr/bin/env bash
# PASS when the Task ship-card declares the object parameter ship with the
# keys name and class, and the results card (string), tags (array) and
# run-name (string).
set -uo pipefail
NS="starfleet"
if ! kubectl -n "$NS" get task ship-card >/dev/null 2>&1; then
  echo "FAIL: Task ship-card does not exist in $NS."; exit 1
fi
ptype="$(kubectl -n "$NS" get task ship-card -o jsonpath='{.spec.params[?(@.name=="ship")].type}')"
if [ "$ptype" != "object" ]; then
  echo "FAIL: the parameter ship must have the type object (found '${ptype}')."; exit 1
fi
keys="$(kubectl -n "$NS" get task ship-card -o jsonpath='{.spec.params[?(@.name=="ship")].properties}')"
case "$keys" in
  *'"name"'*'"class"'*|*'"class"'*'"name"'*) ;;
  *) echo "FAIL: the parameter ship must declare the keys name and class (found '${keys}')."; exit 1 ;;
esac
for pair in card:string tags:array run-name:string; do
  r="${pair%%:*}"; t="${pair##*:}"
  found="$(kubectl -n "$NS" get task ship-card -o jsonpath="{.spec.results[?(@.name==\"$r\")].type}")"
  if [ -z "$found" ] && [ "$t" = "string" ]; then found="string"; fi
  if ! kubectl -n "$NS" get task ship-card -o jsonpath='{.spec.results[*].name}' | tr ' ' '\n' | grep -qx "$r"; then
    echo "FAIL: the Task must declare the result $r."; exit 1
  fi
  if [ "$found" != "$t" ]; then
    echo "FAIL: the result $r must have the type $t (found '${found}')."; exit 1
  fi
done
echo "PASS: Task ship-card declares the object parameter ship and the results card, tags and run-name."
exit 0
