# Use Claude Code Like a Pro

A workshop on building the process your agents follow, not just prompting better.

You build a shared expense splitter, **splitwise-lite**, and along the way you build the machine that builds it: a spec, a dependency-aware backlog, four subagents, hooks that enforce instead of ask, and a loop that works the whole backlog while you're not watching.

> **ADLC** is the process the agents follow. **Agentic OS** is the machine that runs it. **Claude Code** is what both are built from.

## What's here

| | |
|---|---|
| [`worksheet.md`](worksheet.md) | The workshop. Follow this. |
| [`slides/index.html`](slides/index.html) | Slides for the room. Open in a browser. |

The worksheet is the real artifact. Every section ends with a checkpoint, so if something breaks you can skip to the next heading and still be caught up.

## Setup

Check each of these before the session starts, not during it.

```bash
claude --version     # Claude Code, authenticated
python3 --version    # 3.11+
uv --version
git --version        # 2.5+
jq --version
node --version       # for npx ccusage
rtk --version
gh auth status       # GitHub CLI, logged in
```

You also need a GitHub account with permission to create a repo, for the MCP and PR sections.

> If `rtk --version` errors, check `which rtk`. There's an unrelated tool with the same name (`reachingforthejack/rtk`, Rust Type Kit).

## The three segments

1. **Token usage.** What a task actually costs, and how to cut that without cutting what you get. `ccusage`, `rtk`, context headroom.
2. **Quality and consistency.** Spec before code. Layered context. PM, engineer, QA and reviewer subagents. Hooks as enforcement. GitHub over a markdown file.
3. **Autonomy and reproducibility.** One task, one worktree, one PR. The whole backlog in parallel. An issue that fixes itself while you're at lunch, inside a sandbox.

## What you end up with

```
.claude/
  rules/          # conventions loaded only when relevant
  agents/         # pm, engineer, qa, reviewer
  skills/         # /task
  hooks/          # guard-deps, run-tests, require-green
  settings.json   # hook registration, sandbox
scripts/
  watch-issues.sh # the unattended trigger
CLAUDE.md         # always-on context
_docs/
  spec.md
  backlog.md
```

That directory is the point. Package it as a plugin and the next project starts with the whole lifecycle already in place.

## Running it as a workshop

90 minutes, no break.

The demos worth protecting if you run short: the QA subagent returning `FAIL` on something that looked done, a hook blocking a dependency install the model insists it needs, and the sandboxed agent being refused when it reaches for `~/.ssh`.

Search the worksheet for `<!-- VERIFY:` before you present. Those mark details that need checking against your own setup on the day.
