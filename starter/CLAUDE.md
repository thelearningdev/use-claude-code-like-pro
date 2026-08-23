# splitwise-lite

A CLI for splitting shared costs. See `_docs/spec.md` for what it is and
`_docs/backlog.md` for what is left to build.

## Commands

```bash
uv sync                # install, including dev dependencies
uv run splitwise       # run the CLI
uv run pytest          # run the tests
```

## Money

Money is always integer cents. Never floats, never `Decimal`, never a
string that looks like money. An expense of 60.00 is `6000`.

When an amount does not divide evenly between participants, the
remainder is distributed deliberately and the transfers still reconcile
to the original total. Losing a cent is a bug, not a rounding detail.

## Dependencies

This project has no runtime dependencies and that is deliberate. Do not
run `uv add`, `pip install` or `poetry add`. If you believe a dependency
is genuinely needed, say so and stop.

## Conventions

- Python 3.11+, standard library only
- State is a single JSON file in the working directory
- Errors are messages and a non-zero exit code, not tracebacks
