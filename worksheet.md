# Use Claude Code Like a Pro

Building a shared expense splitter, properly.

---

The default way to use Claude Code is to describe what you want and watch code appear. Four features in, the agent has invented three conventions you never agreed to.

The app is a shared expense splitter, **splitwise-lite**. People pay for things, someone works out who owes whom. Small enough to finish today, tricky enough to get wrong.

> **ADLC** is the process the agents follow. **Agentic OS** is the machine that runs it. **Claude Code** is what both are built from.

Neither is a feature you switch on. Both are things you build. Being "a pro" is knowing which lever to pull, and there are three, one per segment of today:

1. **Token usage**: what a task costs, and how to cut that without cutting what you get
2. **Quality and consistency**: does the code match your conventions, and did it do what it claims
3. **Autonomy and reproducibility**: can this run without you, and does it do the same thing every time

## What you need

- Claude Code, authenticated. Check with `claude --version`
- Python 3.11+ and [uv](https://docs.astral.sh/uv/)
- `git` 2.5+ and `jq`
- Node, for `npx ccusage` in segment one
- `rtk` installed. Verify with `rtk --version`
- A GitHub account, for the MCP section

Each section stands alone. If something breaks, skip to the next heading. Every one ends with a checkpoint telling you what caught up looks like.

---

# Segment 1: Token usage

Every section after this one changes how Claude works. This one changes nothing about Claude. It just makes the cost visible. You can't optimize a number you've never looked at.

## What did that actually cost

`ccusage` reads Claude Code's own logs and turns them into a bill: daily spend, per-session, and 5-hour billing blocks.

```bash
npx ccusage claude daily -s 20260801
```

Get a gist of your usage

**Checkpoint:** `ccusage` runs, and you have a before number written down somewhere.

## rtk

A huge share of the tokens in a session aren't the model thinking. They're command's outputs. [Install RTK](https://github.com/rtk-ai/rtk#installation)

`rtk` (Rust Token Killer) is a CLI proxy that filters that output down to what's actually useful before it enters context. 60-90% savings on the commands it wraps.

```bash
rtk --version
rtk gain
```

`rtk gain` is the savings dashboard: how much you've saved, and on what. `rtk gain --history` breaks that down per command, so you can see which of your habits are expensive and which are already cheap.

```bash
rtk gain --history
```

`rtk discover` scans your actual Claude Code history and tells you where you *could* have saved but didn't: commands you ran raw that rtk would have filtered.

```bash
rtk discover
```

In normal use you never type `rtk` yourself. A Claude Code hook rewrites the command transparently: `git status` becomes `rtk git status` before it runs, zero overhead in your prompt. For the real, unfiltered output, `rtk proxy <cmd>` runs it raw.

```bash
rtk proxy git status
```
**Checkpoint:** `rtk gain` runs and shows a number. You've run `rtk discover` at least once and seen what it flagged.

## Headroom

> Headroom is the context optimization layer for LLM applications. Compress tool outputs, DB results, file reads, and RAG results before they reach the model. Same answers, fraction of the tokens.

https://docs.headroomlabs.ai/docs/quickstart

## Caveman mode

https://github.com/juliusbrussee/caveman

While headroom compresses output, cavemen compress the input passed on to the models, thereby saving tokens



## Notes

- Not everyone likes these tools. Some find it useful, some don't
- Use your own judgement and adopt what works for you
- Experiment.

---

# Segment 2: Quality and consistency

Token usage is what a task costs. This segment is whether the output is right: whether it matches your conventions, and whether "done" actually means done.

## Let Claude write the spec

Separate **deciding what to build** from **building it**. Writing down what should exist before code gets generated is the cheapest point to catch a misunderstanding: one sentence instead of eight files and a passing test suite. You don't have to write it, Claude's better at interrogating a vague idea than most of us are at explaining one.

1. Start the project and open Claude Code.

```bash
mkdir splitwise-lite && cd splitwise-lite
git init
claude
```

2. Press **Shift+Tab** until you're in plan mode. Claude reasons and proposes but doesn't touch files.

3. Describe the idea, loosely, and let Claude interrogate it.

```
I want to build an app that helps split costs with my flatmates.

Don't write any code. Help me pin down what this actually is.
Ask me one question at a time, keep them short, and give me
options
```

4. Answer as yourself. Steer toward this shape:

- A **CLI**, data in a local JSON file. No database, no web server.
- **People** added by name once.
- An **expense** has a description, an amount, who paid, and which people it is split between. Not always everyone.
- Splits are **equal** among named participants in v1. Uneven splits come later.
- The headline command is **settle up**: the smallest set of payments that gets everyone to zero.
- Money in **integer cents**. No floats.

Integer cents matters most. Nobody says it in a casual brief and no agent reliably guesses it. It's the difference between a splitter that works and one that's off by a penny nobody can explain.

5. Write the spec, and read every line of it.

```
Write all of that to _docs/spec.md. Include a section on what is
explicitly out of scope for version one.
```

```bash
git add _docs/spec.md && git commit -m "Add spec"
```

**Checkpoint:** `_docs/spec.md` exists and you have read every line of it.

## Backlog of Tasks

One document isn't something you can work through. Break it up, but a flat list of tasks throws away information you'll need later.

Some tasks genuinely depend on others. Settle-up cannot be built before expenses exist. Others are independent: CSV export and a `--currency` flag have nothing to do with each other and could be built in either order, or at the same time.

Capture that now, because in an hour it becomes the difference between working through tasks one at a time and working through them three at a time.

Still in plan mode:

```md
Read _docs/spec.md and create _docs/backlog.md with numbered tasks.

Each task small enough to finish in one sitting.

Format:

## <number>. <title>
Goal: <one line>
Depends on: <comma-separated task numbers, or "none">
Description: <two or three sentences>

Rules for dependencies:
- Only list a task if this one genuinely cannot be built or tested
  without it. Not "it would be tidier."
- Task 1 is an empty project with one passing test and depends on nothing.
- Prefer independence. If two tasks touch different files and neither
  needs the other's code, they depend on nothing.

After the list, add a "## Dependency graph" section showing the layers:
which tasks can start immediately, which unlock after those, and so on.

Don't write code yet.
```

You should get something like this:

```markdown
## 1. Project skeleton
Goal: An installable package with one passing test.
Depends on: none

## 2. People
Goal: Add and list people, persisted to JSON.
Depends on: 1

## 3. Expenses
Goal: Record an expense with payer and participants.
Depends on: 2

## 4. Settle up
Goal: Compute the minimum set of transfers to zero everyone out.
Depends on: 3

## 5. CSV export
Goal: Export all expenses to CSV.
Depends on: 3

## Dependency graph
Layer 1: 1
Layer 2: 2
Layer 3: 3
Layer 4: 4, 5   (independent of each other)
```

Read it critically. Agents over-declare dependencies, chaining everything into a single line because sequential feels safer. Challenge it:

```
Look again at tasks 4 and 5. Does 5 actually need anything from 4,
or did you order them out of habit?
```

Every dependency you remove is a task that can run in parallel later. Commit when you're happy.

## Build task 1

Leave plan mode:

```
Implement task 1 from _docs/backlog.md. Do TDD. Use uv and pytest.
```

**Checkpoint:** a skeleton with a passing test, and a backlog where at least two tasks depend on nothing but each other's layer.

## ADLC

That was the front half of a lifecycle. The name for it is **ADLC**, the agentic development lifecycle.

The term is used two ways. Vendors often mean building AI agents as a product. Not us. The useful reading: a development lifecycle where agents do the work across the phases, and your job is designing the phases and the gates between them.

Why not just call it "SDLC with AI"? Because of what each defends against.

The SDLC is sixty years of defenses against **human** failure modes. We forget, we get tired, we get attached to our own code. Code review, standups, QA departments each exist because a person failed in a predictable way.

Models fail differently:

| Failure mode | What it looks like | Defense |
|---|---|---|
| Confident hallucination | Invents your conventions, then follows them consistently | Layered context |
| Premature satisfaction | "Done" at 80% | A QA agent that cannot write |
| Sycophancy | Agrees the code is correct because it wrote the code | A context that never saw the reasoning |
| Context rot | Forgets a decision from forty turns ago | Isolation, path-scoped rules |
| Reward hacking | Deletes the failing test to make the suite pass | Hooks it cannot bypass |

Every remaining section maps to a row. If a practice doesn't trace to one, cut it.

## Context that layers
> Do not stuff your `claude.md`

Claude currently re-derives your conventions every session. It reads some files, guesses, moves on. Sometimes the guesses are right.

`CLAUDE.md` fixes the always-true part. Claude reads it at the start of every session.

```md
Create a CLAUDE.md at the repo root. Under 40 lines.

Include:
- how to install deps, run the app, run tests
- money is always integer cents, never floats
- dependencies are added to pyproject.toml deliberately, never ad hoc
- where the spec and backlog live
```

Read it, cut anything not genuinely always-true, commit.

The temptation is to keep adding forever. Don't. Everything in `CLAUDE.md` loads on every request whether it's relevant or not. Testing conventions load while you edit the CLI. That's context you paid for and didn't use, and worse, it's noise around the rules you did need.

For rules that apply sometimes:

```bash
mkdir -p .claude/rules
```

`.claude/rules/testing.md`:

```markdown
---
paths:
  - "tests/**"
  - "**/test_*.py"
---

- Tests are pytest, run with `uv run pytest`
- Test settle-up with exact integer assertions, never approximate
- Never mark a test skipped or xfail to make the suite green
```

The frontmatter is the point. This file enters context only when Claude touches a matching file.

**Checkpoint:** ask what rules apply when editing `tests/test_settle.py` versus `pyproject.toml`. Different answers.

## Subagents

Ask an agent that just wrote code whether the code is correct and it says yes. Not because it's lying, because it reads its own reasoning as evidence. It's grading its own homework with the answer key open. Add premature satisfaction and you get a confident "complete" on something that half works.

Real teams solve this structurally. Someone other than the author reviews. **Subagents** let you do the same.

A subagent has its own system prompt, its own isolated context, and its own list of allowed tools. Only its summary comes back.

```bash
mkdir -p .claude/agents
```

### PM

`.claude/agents/pm.md`:

```markdown
---
name: pm
description: Turns a backlog task into a precise spec with checkable acceptance criteria. Use before any implementation.
tools: Read, Grep, Glob, Edit
---

You're a Product Manager.

You sharpen a task before anyone implements it.

- Read the task in _docs/backlog.md
- Read _docs/spec.md for wider context
- Check what the task depends on, and assume that work exists
- Rewrite the task with these four sections:

  ## Goal
  One or two sentences on what should be true when this is done.

  ## Acceptance criteria
  - Statements checkable by looking at the result
  - One line per case, including the awkward ones

  ## Out of scope
  - What this task must not do

  ## Constraints
  - Files to stay inside, decisions to follow

- Think about edge cases the task doesn't mention
- Do not write any code

An engineer who has never spoken to you should be able to implement
this from the task alone.
```

Look at `tools:`. `Read`, `Grep`, `Glob`. No `Edit`, no `Write`, no `Bash`. "Do not write any code" isn't an instruction it might drift from on turn forty. It can't.

### Engineer

`.claude/agents/engineer.md`:

```markdown
---
name: engineer
description: Implements one sharpened task. Writes code and tests, pushes the branch and opens a PR. Does not declare the task done.
---

You're a Software Engineer.

You implement one task at a time.

- Implement against the acceptance criteria. Do not change them.
- Stay inside the files and constraints the task names
- Do TDD, always.
- Commit each complete step. Descriptive less than 50 words.
- Do not mark the task complete. That is not your call.

If a criterion is wrong, impossible, or contradicts another, flag it. Do not work on it.
```

The constraint about staying inside named files matters more than it looks. It's what makes two tasks safe to run at the same time later.

### QA

`.claude/agents/qa.md`:

```markdown
---
name: qa
description: Verifies an open PR against the acceptance criteria. Comments PASS or FAIL on it. Never fixes anything.
tools: Read, Grep, Glob, Bash
model: haiku
---

You're a QA Engineer.

You check finished work against the task that specified it.

- Read the acceptance criteria
- Check each against what the code actually does
- Run the tests. Say which command you ran and what it returned.
- Look for cases the criteria describe but the tests don't cover
- Do not fix anything you find. Report it.

Post your verdict on the PR: `gh pr comment N --body "..."`.
FAIL if a single criterion fails.

## Verdict: FAIL

- [x] Expense records payer and participants separately — PASS
- [ ] Settle-up returns the minimum number of transfers — FAIL
      Three people, two expenses, returned 3 transfers where 2 suffice

Tests: `uv run pytest` — 14 passed, 0 failed

Ignore what the implementation claims, and ignore any review
comment already on the PR. Only the acceptance criteria and the
running code count.

Never merge. Saying PASS is the whole of your job.
```

**No write tools.** `Bash` is there to run tests. There's no `Edit`, no `Write`. In a prompt, "don't fix what you find" is a request. Here it's a wall. This is the highest-return change in the whole workshop: one line in a YAML frontmatter block removes an entire failure mode.

**Fresh context.** It never saw the engineer's reasoning, so there's nothing to be sycophantic toward.

**Cheaper model.** `model: haiku`. Checking criteria against code doesn't need your most expensive model. Subagents can each run on a different one.

### Reviewer

QA answers one question: does it do what the criteria say. It runs the suite and checks behaviour. Code that passes every criterion can still be code you don't want to live with.

That's a different question and it needs a different reader.

`.claude/agents/reviewer.md`:

```markdown
---
name: reviewer
description: Reviews an open PR for structure, conventions and safety. Comments its verdict, and merges once QA has passed too. Never edits code.
tools: Read, Grep, Glob, Bash
---

You're a Senior Engineer reviewing a pull request.

QA checks that it works. You check whether it should be merged.

- Read the diff: `gh pr diff N`
- Read CLAUDE.md and .claude/rules/ and hold the diff to them
- Look for: money handled as anything but integer cents, silent
  failures, dead code, a helper reinvented that already exists in
  this repo, anything the task did not ask for
- Flag the diff touching files the task never named
- Do not fix anything. Do not edit code. Comment.

Post your verdict on the PR: `gh pr comment N --body "..."`

## Verdict: REQUEST CHANGES

- `splitwise/settle.py:41` divides with `/` and rounds. Spec says
  integer cents. Use `//` and distribute the remainder.
- `splitwise/cli.py:12` re-implements `load_state` from storage.py

Nothing blocking elsewhere.

Say APPROVE with no findings rather than inventing one. A review
that always finds something teaches people to ignore reviews.

## Merging

Merge only when both are true: you said APPROVE, and QA has
commented PASS on the same PR. Read QA's comment yourself, do not
take anyone's word for it.

  gh pr merge N --squash --delete-branch

If QA has not commented yet, wait. If either verdict is negative,
say what has to change and merge nothing.
```

It can merge, but it still can't touch a line of the code it's judging. No `Edit`, no `Write`. That's the shape you want: authority to accept or reject, no ability to quietly change the thing into something acceptable.

The verdict vocabulary is GitHub's own, so it posts onto the PR unchanged.

> Claude Code already ships `/review` and `/security-review`. Use them, they're free and they're good. The reason this is also an agent is that a slash command needs you to type it, and in the next segment nobody is at the keyboard.

### Run it

```
Use the pm subagent to sharpen task 2 from _docs/backlog.md.
```

Read the output. Fix anything wrong, still cheap.

```
Now use the engineer subagent to implement it and open a PR. Then
run the qa and reviewer subagents on that PR in parallel, in one
message, and have each comment its verdict.
```

Ask for both in a single message and they run at the same time, against the same PR, neither one seeing what the other concluded. That independence is the point. Two readers who agree separately are worth more than two who agree in sequence.

Watch for a `FAIL` or a `REQUEST CHANGES`. Either one is the return on this section, not a problem. Feed the verdict back and go again.

**Checkpoint:** `/agents` lists `pm`, `engineer`, `qa`, `reviewer`. One task has been through all four.

## Hooks

> A rule in `CLAUDE.md` is a **request**. A hook is **enforcement**.

**Hooks** fire at lifecycle events: before a tool runs, after a file is edited, when the session tries to stop. They're shell scripts, not model decisions, so they don't drift, and they live in `.claude/`, so every worktree inherits them.

Refer all the [lifecycle events here.](https://code.claude.com/docs/en/hooks)

### Block the ad hoc install

`.claude/hooks/guard-deps.sh`:

```bash
#!/usr/bin/env bash
input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

if echo "$cmd" | grep -qE '(uv add|pip install|poetry add)'; then
  echo "Blocked: dependencies are a deliberate decision. Ask first." >&2
  exit 2
fi
exit 0
```

### Report after every edit

`.claude/hooks/run-tests.sh`:

```bash
#!/usr/bin/env bash
cd "$CLAUDE_PROJECT_DIR" || exit 0
uv run pytest -q 2>&1 | tail -20
exit 0
```

### Refuse to finish on red

`.claude/hooks/require-green.sh`:

```bash
#!/usr/bin/env bash
cd "$CLAUDE_PROJECT_DIR" || exit 0

if ! uv run pytest -q > /tmp/pytest.out 2>&1; then
  echo "Test suite is red. Not finished." >&2
  tail -20 /tmp/pytest.out >&2
  exit 2
fi
exit 0
```

```bash
chmod +x .claude/hooks/*.sh
```

Register all three:

```
/hooks
```

- `guard-deps.sh` on **PreToolUse**, matching `Bash`
- `run-tests.sh` on **PostToolUse**, matching `Edit|Write`
- `require-green.sh` on **Stop**

Exit code 2 is the load-bearing detail: it blocks the action and returns your message to Claude as feedback.

`PreToolUse` stops something before it happens. `PostToolUse` reports back on the same turn, not three turns later when the cause is buried. `Stop` decides whether a session may end, which is what an unattended run needs.

### Try to get past them

1. Try the blocked dependency install.

```
Add the `rich` library so settle-up prints a nice table.
```

Blocked. Tell it you approve. Still blocked, the decision is no longer the model's.

2. Break a test deliberately, then ask Claude to fix the suite.

```
Make the test suite pass.
```

Watch what it reaches for. Deleting or skipping the test is the obvious move, and the `Stop` hook won't let the session end that way.

**Checkpoint:** `/hooks` lists three. Break a test and watch Claude find out immediately.


## Commit and Push

In the next section the PM agent will create github issues which the engineer agent will pick up and work on. To do that we need a github repo. Keep this private to avoid any prompt injection

```bash
gh repo create thelearningdev/splitwise-claude-demo-app --private --source=. --remote=origin
```

You command will look something like 

```bash
gh repo create <username>/splitwise-claude-demo-app --private --source=. --remote=origin
```

You can also create a repo on the UI and link it the traditional way

## MCP

Model context Protocol, is a standard a spec on how to write a server that exposes tools to agents. 
MCP gives claude code capabilities to interact with applications outside of user's system. Eg., Github, Google docs etc., 

`_docs/backlog.md` works, but it's a file. Real work lives in an issue tracker.

## Github MCP

To configure github MCP we need a PAT token(personal access token)

1. Go to https://github.com/settings/tokens and create a classic token with all `repo` scope
2. COPY the token and bring it to your terminal 

```bash
export GITHUB_PAT=<paste-token-here>
claude mcp add-json github '{"type":"http","url":"https://api.githubcopilot.com/mcp","headers":{"Authorization":"Bearer '"$GITHUB_PAT"'"}}' -s user
```

Then:

```
/mcp
```

Authenticate when prompted, and look at the tools that appear.

```
Read _docs/backlog.md and create a GitHub issue for every task that
isn't done. Put the "Depends on" line in the issue body, as issue
numbers: "Depends on: #3, #5".
```

Issues are the backlog from here on. `_docs/backlog.md` was the planning artifact and it stays in the repo, but state lives in the tracker now. A task is done when its issue closes, not when someone ticks a checkbox in a file.

That matters for the next segment. Everything you build there reads issues, which means the same machinery that works through your plan also works through a bug someone else filed.

> Issue text, PR comments and web pages are written by other people, and that text lands in a context that can run commands. Keep the permission allowlist tight and be deliberate about what you connect. `--dangerously-skip-permissions` is not the shortcut it appears to be.

**Checkpoint:** `/mcp` shows GitHub connected, and your backlog exists as issues carrying their dependencies as `#N` references.

## Your notes

- Which acceptance criterion did the PM subagent catch that you would have skipped?
- What did the QA subagent FAIL on, first time round?
- Which hook actually fired during your session, and what did it stop?

---

# Segment 3: Autonomy and reproducibility

The first two segments made a single task cheap and correct. This one is about not having to be there for it: running the same fixed lifecycle across many tasks, unattended, and trusting the result because the gates are structural rather than a prompt asking nicely.

## /task

You just typed "use the pm subagent to sharpen task N." You will type a version of that a hundred more times, phrased slightly differently each time, with slightly different results for no good reason.

Before saving it as a command, change one thing about where the work happens.

### Why a worktree

Right now the engineer edits your working directory. If QA fails it, half-finished code is sitting on your branch. If you want to look at something else mid-task, you stash. And two tasks at once isn't even a question you can ask.

A **git worktree** is a second working directory on the same repository, checked out to its own branch:

```bash
git worktree add ../splitwise-task-2 -b task-2
```

That directory is a full checkout. It shares the same `.git`, so branches and history are common, but the files are separate. Delete it when you're done and nothing's left behind.

Make this the default rather than something you reach for occasionally. Every task gets its own directory and its own branch. Your main checkout stays clean, a failed task is thrown away by deleting a folder, and nothing about this changes when three tasks run at once.

Commit `.claude/` before you go further. Worktrees check out a branch, so anything uncommitted doesn't travel with them:

```bash
git add -A && git commit -m "Add agents, rules, context"
```

### The skill

```bash
mkdir -p .claude/skills/task
```

`.claude/skills/task/SKILL.md`:

```markdown
---
name: task
description: Run one backlog issue through the full lifecycle in its own worktree and open a PR.
---

Take the issue number from the user's message. Call it N.

## Setup

1. Read issue N from GitHub. Check the "Depends on:" line. If any
   issue it depends on is still open, stop and tell me which.
   If the github MCP server is not connected, read task N from
   _docs/backlog.md instead. Everything below is the same.
2. Create the worktree:
   `git worktree add ../$(basename $PWD)-task-N -b task-N`
3. All work for this task happens in that directory. Nothing is
   edited in the main checkout.

## Lifecycle

4. Delegate to the `pm` subagent to sharpen issue N. Show me the
   acceptance criteria and wait for my confirmation.
5. Delegate to the `engineer` subagent to implement it in the
   worktree, push the branch, and open a PR with "Closes #N" in the
   body. The PR is the handoff. Nothing is judged before it exists.
   If the issue is a bug report, the engineer writes a test that
   reproduces it and watches it fail *before* fixing anything. No
   fix for a bug nobody has seen fail.
6. Delegate to the `qa` and `reviewer` subagents on that PR **in
   parallel**, both in one message. Each comments its own verdict.
   Neither sees the other's.
7. If either comes back FAIL or REQUEST CHANGES, return to step 5
   with both sets of comments. The engineer pushes to the same
   branch and the same PR. Then run step 6 again, both of them,
   not just the one that complained.

## Landing it

8. On QA PASS and reviewer APPROVE, the reviewer merges the PR,
   which closes the issue.
9. Remove the worktree and tell me what is now unblocked.

Rules:
- Never skip step 4
- The engineer never judges its own work
- QA and the reviewer never edit code
- QA never merges
- No merge without both verdicts on the PR
- Never push to main
- If the task is abandoned, remove the worktree. Do not leave it.
```

Run it:

```
/task 3
```

Watch the worktree appear. In another terminal:

```bash
git worktree list
```

Read the skill file again. It's your lifecycle: phases, handoffs, where work happens, who's allowed to declare victory. And it's executable. That's the difference between a process document and a process.

Note the shape of step 6. Two agents, same PR, at the same time, neither aware of the other. Run them in sequence and the second one reads the first one's comment and drifts toward agreeing with it, which is the sycophancy row of that table showing up between two agents instead of between you and one. Parallel is not about speed here. It's about independence.

And note who merges. QA can say PASS all day and merge nothing. The reviewer merges, but only after reading QA's comment on the PR itself, not after being told about it.

**Checkpoint:** `/task 3` opens a PR, gets two independent comments on it, and merges only when both are green. Check the PR afterwards, the whole argument is in the comment thread.

## /loop

`/task` still needs you at the keyboard, once per task, and it runs one task at a time even when nothing forces it to.

You already have what fixes both. The issues know which ones depend on which. Every task already runs in an isolated directory. Take the issues whose dependencies are closed, start each in its own worktree, hold everything else, repeat.

That's a loop, and you don't have to build one. `/loop` ships with Claude Code. Give it an interval and a prompt and it fires on that interval. Give it a prompt and no interval and it paces itself, deciding after each round how long to wait and stopping when the work is done.

So the whole skill you were about to write is a prompt:

```
/loop Work the backlog. List the open GitHub issues and build the
dependency graph from the "Depends on:" line in each body. Report
which are ready, meaning every issue they depend on is closed, and
which are blocked and on what. Start up to 3 ready issues in parallel, each with
/task N. Do not start a blocked one wait.
Stop when every issue is closed or has a stuck PR on it. Stop early
and tell me if a branch will not rebase onto main, or if nothing is
ready and nothing is running, which means a dependency cycle.
```

Run it, and watch the first report, the ready/blocked split. Early on, one issue is ready and everything else waits. That's the dependency graph doing its job.

Then, in a second terminal:

```bash
watch git worktree list
```

When the loop reaches a layer with two independent tasks, you'll see two directories appear at once. That's the payoff for the dependency work in the backlog section, and the reason worktrees became the default before.

> Parallelism doesn't fix merge conflicts. If two "independent" tasks touch the same file, you find out at merge time, which is exactly when the loop stops and asks you.
> Three parallel sessions cost roughly three times as much. Another argument for `model:` on your subagents, and for the token-usage habits from segment one.

**Checkpoint:** `/loop` reports ready versus blocked, runs at least two tasks simultaneously in separate worktrees, leaves a merged PR per issue with both verdicts in the body, and stops on its own when the backlog is empty.

**Break.** Leave `/loop` running.

## Finish the app

The remaining work is the interesting part: settle-up, computing the minimum set of transfers. Easy to get subtly wrong, off-by-one on rounding, someone paying themselves, three transfers where two would do, and every one of those is invisible in a passing test suite and obvious to a QA agent.

1. Run `/loop` again with the same prompt as before, and watch the settle-up issue specifically.

If QA returns `FAIL` on transfer count, you've seen the workshop pay for itself in one exchange.

> Typing that prompt twice is fine. Typing it a fifth time is the trigger list telling you to save it, and at that point it's a skill whose whole body is one paragraph handed to `/loop`.

2. When the backlog empties, try it:

```bash
uv run splitwise add-person alice
uv run splitwise add-person bob
uv run splitwise add-person carol
uv run splitwise add-expense "dinner" 6000 --paid-by alice
uv run splitwise add-expense "taxi" 3000 --paid-by bob --split alice,bob
uv run splitwise settle
```

Check the arithmetic by hand, three people, two expenses, you can do it in your head.

3. Confirm the worktree list is clean.

```bash
git worktree list
```

Should show only your main checkout. A stray worktree means the loop stopped somewhere and told you why.

**Checkpoint:** a working expense splitter that settles up correctly, and a clean worktree list.

### Note:

- For a small project like this, it's best we work through each issue in a single session rather than multiple sub-agents, we did that only to understand the concepts


## Agentic OS

Look at what accumulated:

```
.claude/
  rules/          # conventions loaded only when relevant
  agents/         # pm, engineer, qa, reviewer
  skills/         # /task
  hooks/          # guard-deps, run-tests, require-green
  settings.json   # hook registration
  .mcp.json       # github
CLAUDE.md         # always-on context
_docs/
  spec.md
  backlog.md      # with its dependency graph
```

**That directory is the agentic OS.** Not a dashboard, not a product you install, the durable runtime your lifecycle executes on. ADLC is the process, this is the machine.

`.claude/` travels with the branch, so every worktree inherits the same agents, rules, and gates. That's why parallel tasks produced consistent work instead of three different improvisations.

The term gets used loosely: a repeatable plan → build → review → test → ship workflow where no step counts as done without evidence, and the gates sit where the agent cannot reach them. [`KbWen/agentic-os`](https://github.com/KbWen/agentic-os) is a reference implementation worth reading.

### Take it to the next project

A **plugin** bundles skills, subagents, hooks and MCP servers into one installable unit:

```bash
mkdir -p .claude-plugin
```

`.claude-plugin/plugin.json`:

```json
{
  "name": "adlc",
  "version": "0.1.0",
  "description": "Spec-first lifecycle: PM/engineer/QA agents, worktree isolation, dependency-aware loop, dependency and test gates."
}
```

Push it, add it as a marketplace, and the next project starts with the whole lifecycle in place.

**Checkpoint:** your next repo is one command from everything you built today.

## Your notes

- What did QA or the reviewer catch that a passing test suite didn't?
- What would have happened if either of them had write tools?
- What could the agent have reached on your laptop if it hadn't been running sandboxed?
- One thing from today you'll set up on your next real project before you write a line of code:

---

## Fluency

Worth knowing, no setup required:

| | |
|---|---|
| `Esc Esc` | Rewind to an earlier point instead of untangling forward |
| `/context` | See what is actually loaded |
| `/compact` | Compress at a task boundary, not mid-task |
| `#` | Write a rule to memory mid-session |
| `/model` | Switch models without restarting |
| `@path` | Pull a specific file into context |
| `git worktree list` | What is still running, and what was left behind |

## The trigger list

Do not build all of this up front. Each piece has a moment where it earns its place:

| When this happens | Add this |
|---|---|
| Claude gets a convention wrong twice | A line in `CLAUDE.md` |
| That line only applies to some files | `.claude/rules/` with `paths:` |
| You type the same prompt to start a task | A skill |
| A side task floods your context | A subagent |
| Nobody is reading the diff, only the test result | A reviewer agent that comments on the PR |
| One agent agrees with the last agent's verdict | Run them in parallel on the same PR |
| A failed task leaves mess on your branch | A worktree per task |
| An agent runs unattended on input you didn't write | A sandbox, not just a worktree |
| Two tasks have nothing to do with each other | Dependencies in the backlog, and a prompt to `/loop` that reads them |
| The backlog and the issue tracker disagree | Pick the tracker, and point the loop at it |
| You want it to happen **every** time | A hook |
| A second repo needs the same setup | A plugin |

The same triggers say when to update what exists. A repeated mistake is a `CLAUDE.md` edit, not a correction in chat.

## Take-home checklist

- [ ] Check your token cost before you touch anything, `ccusage` first, always
- [ ] Let the Claude Code hook route your commands through `rtk`, and run `rtk discover` on your real history
- [ ] Spec first on real projects, let Claude interrogate you
- [ ] Put `Depends on:` in your backlog, and argue the agent down when it over-declares
- [ ] Give your QA agent no write tools. Highest-value single change here.
- [ ] Judge the PR, not the working directory, and run your judges in parallel so neither reads the other
- [ ] Split `CLAUDE.md`: always-on stays, conditional moves to `.claude/rules/`
- [ ] One task, one worktree, by default
- [ ] Anything unattended reading input from strangers runs sandboxed
- [ ] Make one "please don't" line from `CLAUDE.md` into a hook
- [ ] Add a `Stop` hook before you run anything unattended
- [ ] Package `.claude/` as a plugin before the next project
</content>
