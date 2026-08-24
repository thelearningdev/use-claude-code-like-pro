# splitwise-lite

Starting point for the **Use Claude Code Like a Pro** workshop.

Task 1 is done. Everything else is what you build in the session.

## Check it works

```bash
uv sync
uv run pytest
uv run splitwise --version
```

Two passing tests and a version number means you're ready.

## What's already here

| | |
|---|---|
| `plans/spec.md` | What this app is, written before any code |
| `plans/backlog.md` | Five tasks with their dependencies. Task 1 is done |
| `CLAUDE.md` | Always-on context, loaded every session |
| `.claude/rules/testing.md` | Path-scoped. Loads only when touching tests |
| `splitwise/`, `tests/` | Task 1, green |

Read the spec and the backlog before the session starts. They were
written by Claude in plan mode, from a vague description of the problem,
and edited by a human. You'll see that process demonstrated rather than
doing it yourself, because it takes twenty minutes we don't have.

> Open `.claude/rules/testing.md` and look at the `paths:` frontmatter.
> That file enters context only when Claude touches a matching file. Ask
> Claude what rules apply when editing `tests/test_cli.py` versus
> `pyproject.toml` and you should get different answers.

## The agents, hooks and skill

These ship too, so you never lose time to typing them:

```
.claude/agents/       pm, engineer, qa, reviewer
.claude/hooks/        guard-deps, run-tests, require-green
.claude/skills/task/  one issue, one worktree, one PR
scripts/              watch-issues.sh, the unattended trigger
```

Don't read them as finished furniture. Each one is built up in the
worksheet with the reasoning attached, and the reasoning is the part
worth having. Look at `agents/qa.md` first, then at the `tools:` line in
`agents/reviewer.md`, and ask what those lists make impossible.

The hooks are executable but **not registered**. Registering them is
`/hooks`, and doing it by hand once is worth the two minutes. If it
fights you, copy `.claude/settings.json.example` over to
`.claude/settings.json` instead.

Check one works before you trust it:

```bash
./.claude/hooks/guard-deps.sh <<< '{"tool_input":{"command":"uv add rich"}}'
echo $?   # 2, blocked
```

Then point `/loop` at the backlog and watch tasks 4 and 5 run at the
same time.

Follow [`worksheet.md`](../worksheet.md) in the workshop repo.
