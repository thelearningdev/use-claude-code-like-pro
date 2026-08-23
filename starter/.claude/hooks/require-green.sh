#!/usr/bin/env bash
cd "$CLAUDE_PROJECT_DIR" || exit 0

if ! uv run pytest -q > /tmp/pytest.out 2>&1; then
  echo "Test suite is red. Not finished." >&2
  tail -20 /tmp/pytest.out >&2
  exit 2
fi
exit 0
