#!/usr/bin/env bash
# Poll for new bug issues and work them, one at a time.
cd "$(git rev-parse --show-toplevel)" || exit 1
seen=.git/.worked

touch "$seen"
while true; do
  for n in $(gh issue list --label bug --state open --json number -q '.[].number'); do
    grep -qx "$n" "$seen" && continue
    echo "$n" >> "$seen"
    echo "[watch] picking up issue #$n"
    claude -p "/task $n"
  done
  sleep 30
done
