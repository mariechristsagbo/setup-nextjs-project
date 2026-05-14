#!/usr/bin/env bash
set -Eeuo pipefail

commands_file="${1:-setup.commands}"

if [[ ! -f "$commands_file" ]]; then
  echo "[error] Missing commands file: $commands_file"
  echo "[hint] Copy setup.commands.example to setup.commands and edit it."
  exit 1
fi

step=0
while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
  line="$(printf '%s' "$raw_line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  if [[ -z "$line" || "${line:0:1}" == "#" ]]; then
    continue
  fi

  step=$((step + 1))
  echo "[step $step] $line"

  if bash -lc "$line"; then
    :
  else
    code=$?
    echo "[error] Step $step failed (exit $code)."
    exit "$code"
  fi
done < "$commands_file"

echo "[ok] All commands completed successfully."
