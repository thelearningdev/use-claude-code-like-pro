#!/usr/bin/env bash
cd "$CLAUDE_PROJECT_DIR" || exit 0
uv run pytest -q 2>&1 | tail -20
exit 0
