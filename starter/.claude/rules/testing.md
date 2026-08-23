---
paths:
  - "tests/**"
  - "**/test_*.py"
---

- Tests are pytest, run with `uv run pytest`
- Test settle-up with exact integer assertions, never approximate
- Never mark a test skipped or xfail to make the suite green
