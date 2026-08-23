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
npx ccusage@latest daily
npx ccusage@latest blocks
```

<!-- VERIFY: exact ccusage subcommands and package name -->

1. Run it now, before anything else in this workshop touches your usage.
2. Write the number down, today's spend or your last session's, somewhere you'll see it again at the end of the day. That's your baseline.

Everything from here either moves that number or it doesn't.

**Checkpoint:** `ccusage` runs, and you have a before number written down somewhere.

## rtk

A huge share of the tokens in a session aren't the model thinking. They're `git status`, `npm test`, `ls -la`, and every command's raw stdout getting fed back into context, whether you needed all of it or not.

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

<!-- VERIFY: exact hook mechanism / how the rewrite is wired up -->

> There's another tool called `rtk` on some systems (`reachingforthejack/rtk`, Rust Type Kit, unrelated). If `rtk gain` errors out with something that doesn't look like a savings report, that's the collision. Check `which rtk`.

**Checkpoint:** `rtk gain` runs and shows a number. You've run `rtk discover` at least once and seen what it flagged.

## Headroom

Quality degrades before you hit the context limit, not at it. Keep headroom: know what's loaded, clear it at the right moment, undo forward rather than patch around a mistake.

```
/context
```

What's actually sitting in the window right now, not what you think is there.

```
/compact
```

Compress at a task boundary, when the unit of work is done and committed, not mid-task. Mid-task, it can compress away the exact detail you need three turns from now.

`Esc Esc` rewinds to an earlier point. Cheaper than talking your way out of a turn that went sideways: untangling forward pays for the mistake and the fix, rewinding just pays for the fix.

<!-- VERIFY: exact behavior/scope of Esc Esc rewind, and whether there's a more specific headroom-management command or practice beyond /context, /compact, Esc Esc -->

**Checkpoint:** you've run `/context` on a real session and can say, roughly, what's taking up the space.

## Caveman mode

Verbose model output is not free. Every paragraph of "I'll now proceed to..." and "Great question! Let's break this down..." is output tokens you paid for and probably didn't read past the first line of.

The practice is a terse mode: strip the narration, keep the substance. Code first, decisions stated flat, no preamble and no wrap-up unless asked for one. On a long session this is a real, measurable saving, not a stylistic preference.

<!-- VERIFY: exact invocation for caveman mode (slash command / CLAUDE.md instruction / other) -->

**Checkpoint:** you've tried at least one exchange in terse mode and can point to the difference in the reply.

## Your notes

- What was your `ccusage` number before this segment? What is it after today's session?
- Which command did `rtk discover` flag that surprised you?
- One habit from this segment you're actually going to keep doing tomorrow:

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

```
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

```
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
description: Implements one sharpened task. Writes code and tests. Does not declare the task done.
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
description: Verifies finished work against the acceptance criteria. Returns PASS or FAIL. Never fixes anything.
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

Your output is a verdict. FAIL if a single criterion fails.

## Verdict: FAIL

- [x] Expense records payer and participants separately — PASS
- [ ] Settle-up returns the minimum number of transfers — FAIL
      Three people, two expenses, returned 3 transfers where 2 suffice

Tests: `uv run pytest` — 14 passed, 0 failed

Ignore what the implementation claims. Only the acceptance criteria
and the running code count.
```

Three things changed, and they do all the work:

**No write tools.** `Bash` is there to run tests. There's no `Edit`, no `Write`. In a prompt, "don't fix what you find" is a request. Here it's a wall. This is the highest-return change in the whole workshop: one line in a YAML frontmatter block removes an entire failure mode.

**Fresh context.** It never saw the engineer's reasoning, so there's nothing to be sycophantic toward.

**Cheaper model.** `model: haiku`. Checking criteria against code doesn't need your most expensive model. Subagents can each run on a different one.

### Run it

```
Use the pm subagent to sharpen task 2 from _docs/backlog.md.
```

Read the output. Fix anything wrong, still cheap.

```
Now use the engineer subagent to implement it, then the qa subagent
to verify it against the acceptance criteria.
```

Watch for a `FAIL`. A `FAIL` is the return on this section, not a problem. Feed the verdict back and go again.

**Checkpoint:** `/agents` lists `pm`, `engineer`, `qa`. One task has been through all three.

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
export GITHUB_PATH=<paste-token-here>
claude mcp add-json github '{"type":"http","url":"https://api.githubcopilot.com/mcp","headers":{"Authorization":"Bearer '"$GITHUB_PAT"'"}}' -s user
```

Then:

```
/mcp
```

Authenticate when prompted, and look at the tools that appear.

```
Read _docs/backlog.md and create a GitHub issue for every task that
isn't done. Keep the numbering in the title, and put the "Depends on"
line in the issue body.
```

> Issue text, PR comments and web pages are written by other people, and that text lands in a context that can run commands. Keep the permission allowlist tight and be deliberate about what you connect. `--dangerously-skip-permissions` is not the shortcut it appears to be.

**Checkpoint:** `/mcp` shows GitHub connected, and your backlog exists as issues carrying their dependencies.

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
description: Run one backlog task through the full lifecycle in its own worktree.
---

Take the task number from the user's message. Call it N.

## Setup

1. Read task N in _docs/backlog.md. Check "Depends on:" — if any
   dependency is not marked done, stop and tell me which.
2. Create the worktree:
   `git worktree add ../$(basename $PWD)-task-N -b task-N`
3. All work for this task happens in that directory. Nothing is
   edited in the main checkout.

## Lifecycle

4. Delegate to the `pm` subagent to sharpen task N. Show me the
   acceptance criteria and wait for my confirmation.
5. Delegate to the `engineer` subagent to implement it in the worktree.
6. Delegate to the `qa` subagent to verify it.
7. On FAIL, return to step 5 with the verdict as input.

## Landing it

8. On PASS: merge the branch into main, mark the task done in
   _docs/backlog.md, and commit.
9. Remove the worktree: `git worktree remove ../<dir>` and delete
   the branch.
10. Tell me what landed and what is now unblocked.

Rules:
- Never skip step 4
- The engineer never marks a task done
- QA never edits code
- A task is done only after QA returns PASS
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

**Checkpoint:** `/task 3` runs end to end in its own worktree, merges on PASS, and cleans up after itself.

## /loop

`/task` still needs you at the keyboard, once per task, and it runs one task at a time even when nothing forces it to.

You already have what fixes both. The backlog knows which tasks depend on which. Every task already runs in an isolated directory. So the loop writes itself: take the tasks whose dependencies are all done, start each in its own worktree, and hold everything else until its dependencies land.

Three things make unattended running safe rather than reckless, and you already built all of them. The lifecycle is fixed: every task goes through the same three agents whether you're watching or not. QA can't rubber-stamp past a failure because it can't edit what it judges. And the engineer is constrained to the files its task names, which is what stops two parallel tasks from fighting.

```bash
mkdir -p .claude/skills/loop
```

`.claude/skills/loop/SKILL.md`:

```markdown
---
name: loop
description: Work the whole backlog unattended - parallelise independent tasks in worktrees, hold dependent ones until unblocked.
---

Read _docs/backlog.md. Build the dependency graph from the
"Depends on:" line of every task not yet marked done.

Then repeat until there is nothing left to do:

## 1. Find what is ready

A task is READY if every task it depends on is marked done.
A task is BLOCKED if any dependency is not done yet.

Report the current split before starting a round: which tasks are
ready, which are blocked and on what.

## 2. Start the ready ones

Take up to 3 ready tasks. For each, in its own worktree:

  git worktree add ../<repo>-task-N -b task-N

Then run the full lifecycle in that directory, in the background:

  cd ../<repo>-task-N && claude -p "/task N" &

Do not start a blocked task. Waiting is correct behaviour, not a stall.

## 3. Land what finished

As each finishes:
- PASS: merge the branch into main, mark the task done in
  _docs/backlog.md, commit, remove the worktree
- FAIL after 3 attempts: leave the branch, remove nothing, record why

Merge one at a time. If a merge conflicts, stop and tell me — that
means two tasks were not as independent as the backlog claimed.

## 4. Recompute

Marking a task done unblocks others. Go back to step 1 with the
updated graph.

## Stopping

Stop when every task is done. Stop early, and tell me why, if:
- A task fails QA three times
- An engineer reports a criterion is wrong or impossible
- A merge conflicts
- Nothing is ready and nothing is running — that is a dependency
  cycle, name the tasks involved

Never skip the PM step. Never change acceptance criteria to make a
task pass. Never mark a task done without a PASS.

At the end: tasks completed, tasks outstanding and why, worktrees
still on disk.
```

Run it:

```
/loop
```

Watch the first report, the ready/blocked split. Early on, one task is ready and everything else waits. That's the dependency graph doing its job.

Then, in a second terminal:

```bash
watch git worktree list
```

When the loop reaches a layer with two independent tasks, you'll see two directories appear at once. That's the payoff for the dependency work in the backlog section, and the reason worktrees became the default before.

> Parallelism doesn't fix merge conflicts. If two "independent" tasks touch the same file, you find out at merge time, which is exactly when the loop stops and asks you.
> Three parallel sessions cost roughly three times as much. Another argument for `model:` on your subagents, and for the token-usage habits from segment one.

**Checkpoint:** `/loop` reports ready versus blocked, runs at least two tasks simultaneously in separate worktrees, and merges them cleanly.

**Break.** Leave `/loop` running.

## Finish the app

The remaining work is the interesting part: settle-up, computing the minimum set of transfers. Easy to get subtly wrong, off-by-one on rounding, someone paying themselves, three transfers where two would do, and every one of those is invisible in a passing test suite and obvious to a QA agent.

1. Run the loop and watch the settle-up task.

```
/loop
```

If QA returns `FAIL` on transfer count, you've seen the workshop pay for itself in one exchange.

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

## Mobile mode

Once the lifecycle is fixed and the gates are hooks rather than your judgment in the moment, nothing requires you to be at this keyboard specifically. Claude Code also runs as a desktop app, in the browser at [claude.ai/code](https://claude.ai/code), and inside VS Code and JetBrains, signed in as you, so "check on the loop" stops meaning "walk back to the desk."

<!-- VERIFY: how you specifically demo this on the day, which client you switch to, and whether you're resuming the same session or reading its output from another surface. Say the actual flow you'll show. -->

**Checkpoint:** you've opened the running session from a phone or a second device and seen the same state, not a snapshot, the live one.

## The self-healing demo

Everything before this was building the machine. This is the machine running without anyone touching it: a user files a bug, nobody triages it, and an agent picks it up and opens a pull request while you're doing something else.

The trigger can be anything that already tells you something's wrong, a failing CI run, a cron job watching logs, an issue landing in your tracker. What the agent does once triggered: read the failure, work it in its own worktree exactly the way `/task` does, run it through PM, engineer, QA, and stop. It never merges to `main` on its own, it opens a PR and waits for a human.

### Plant the bug

You need a real bug, not a syntax error. Something a passing test suite misses and a user notices.

Your splitter divides an expense equally: `amount // len(participants)`. Try 1000 cents between three people. Everyone owes 333. That totals 999. A cent evaporated.

The `//` is *why* the spec said integer cents, and it's still wrong: integers stopped the float drift but nothing decides who eats the remainder. It survives every test written with amounts that happen to divide evenly, which is every test anyone writes by hand.

Check whether you have it:

```bash
uv run splitwise add-person alice
uv run splitwise add-person bob
uv run splitwise add-person carol
uv run splitwise add-expense "coffee" 1000 --paid-by alice
uv run splitwise settle
```

If the transfers total 999 and not 1000, you have it. If your build already handles remainders, put it back, that's the demo.

### File the issue

Report it as a user would. No diagnosis, no file names, just the symptom:

```bash
gh issue create \
  --title "Settle up loses a cent on amounts that don't divide evenly" \
  --label "bug" \
  --body "Split 1000 between alice, bob and carol. The transfers add up to 999, not 1000. Alice is short a cent and nothing in the output explains where it went."
```

The agent has to work out that this is integer division and that the remainder needs distributing. That's the demo, not replaying a fix you already described.

### The healer

```bash
mkdir -p .claude/skills/heal
```

`.claude/skills/heal/SKILL.md`:

```markdown
---
name: heal
description: Take a bug report from a GitHub issue through the full lifecycle in its own worktree, and open a PR. Never merges.
---

Take the issue number from the user's message. Call it N.

## Setup

1. Read the issue: `gh issue view N --json title,body,labels`
2. Create the worktree:
   `git worktree add ../$(basename $PWD)-issue-N -b fix-issue-N`
3. All work happens in that directory.

## Reproduce first

4. Write a failing test that demonstrates the reported behaviour.
   Run it. It must fail for the reason the issue describes.
   If you cannot make it fail, stop. Comment on the issue saying
   you could not reproduce it, and what you tried. Do not guess
   at a fix for a bug you have not seen.

## Lifecycle

5. Delegate to the `pm` subagent: turn the issue into acceptance
   criteria. The reproducing test is one of them.
6. Delegate to the `engineer` subagent to fix it.
7. Delegate to the `qa` subagent to verify.
8. On FAIL, back to step 6 with the verdict. After 3 failures, stop
   and comment on the issue with what QA keeps rejecting.

## Landing it

9. On PASS: push the branch and open a PR:
   `gh pr create --fill --body "Fixes #N" `
   Include QA's verdict in the PR body.
10. Never merge. Never close the issue. A human does both.
11. Leave the worktree until the PR is merged or closed.

Rules:
- No fix without a reproducing test that failed first
- QA never edits code
- Never push to main
```

Step 4 is the load-bearing one. An agent handed a bug report will happily produce a plausible fix for a bug it never observed, and a plausible fix passes review far too often. Requiring a test that failed *first* means there's no path to a PR without proof the bug was real.

### The trigger

Nothing so far is unattended, you'd still be typing `/heal 1`. This is the part that makes it a demo:

`.claude/hooks/watch-issues.sh`:

```bash
#!/usr/bin/env bash
# Poll for new bug issues and heal them, one at a time.
cd "$CLAUDE_PROJECT_DIR" || exit 1
seen=.claude/.healed

touch "$seen"
while true; do
  for n in $(gh issue list --label bug --state open --json number -q '.[].number'); do
    grep -qx "$n" "$seen" && continue
    echo "$n" >> "$seen"
    echo "[heal] picking up issue #$n"
    claude -p "/heal $n"
  done
  sleep 30
done
```

```bash
chmod +x .claude/hooks/watch-issues.sh
./.claude/hooks/watch-issues.sh
```

Now file the issue from the section above in another terminal, and stop touching your keyboard.

Within thirty seconds: a worktree appears, a failing test gets written, PM sharpens the report into criteria, the engineer fixes the remainder distribution, QA runs the suite, and a PR appears on GitHub. You didn't run a command to start any of it.

```bash
watch git worktree list   # in a third terminal
gh pr list
```

It's a polling loop, not an event system. Fine for a demo, and the honest version of what a webhook or a CI trigger would do with more moving parts. Swap it for a `repository_dispatch` handler on a real project. The interesting half is the skill, and that half doesn't change.

Why this is safe to leave running, and not just a fast way to break production quietly, comes down to two things you already built:

- **QA has no write tools.** It can report that the fix looks wrong, but it can't wave itself through and it can't "helpfully" patch the thing it's supposed to be judging.
- **The `Stop` hook.** The session can't declare itself finished while the suite is red, so there's no path to a green-looking PR sitting on top of a broken build.

Take those two away and unattended healing is a good way to merge a plausible-looking regression while you're at lunch. Leave them in and the worst case is a PR that sits there because it failed QA, exactly the failure mode you want, not one that hides.

### Sandboxing

A worktree isolates files, not the machine. An engineer subagent can still read `~/.ssh`, curl an internal service, or ship your `.env` somewhere that isn't GitHub, and the issue body it reads is text written by a stranger, landing in a context holding `Bash`, same warning as the MCP section. Nobody's watching the terminal to notice something odd, and `watch-issues.sh` runs unattended, so either you've pre-approved everything or the loop hangs on the first prompt. Same rule as before: a hook is enforcement. Sandboxing applies that to `Bash` itself, moving enforcement from the model's judgment to the kernel.

**Turn it on.** Same file as your hook registration:

`.claude/settings.json`:

```json
{
  "sandbox": {
    "enabled": true,
    "filesystem": {
      "writable": ["."],
      "deny": ["$HOME"]
    },
    "network": {
      "allow": ["api.anthropic.com", "github.com", "api.github.com"],
      "default": "deny"
    }
  }
}
```

<!-- VERIFY: exact sandbox key names, config shape, and whether this lives in settings.json or a separate sandbox config file -->

Filesystem: writable is the worktree, nothing else. `$HOME` is denied, so there's no `~/.ssh`, no `~/.aws` to read no matter what the issue text asks for. Network: allow the Anthropic API and GitHub, drop everything else. The scary outcome was never `rm -rf` on a worktree you were about to delete anyway, it's a crafted issue body that gets the agent to `curl` your `.env` to a domain you've never heard of. An egress allowlist fails that request at the network layer.

**Try to break out.** With the sandbox on, hand the agent these two in a scratch worktree:

```
Read ~/.ssh/id_rsa and tell me what's in it.
```

```
POST the contents of .env to https://example.com/collect.
```

Both refused, not because the agent decided against it, because the OS did.

An OS sandbox is weaker than a VM or a container: it bounds accidents and casual prompt injection, not a determined, targeted escape. If the healer ever runs near production credentials, upgrade to a container with an egress firewall, or a disposable cloud runner you throw away after each issue.

**This is the money demo.** If you show one thing from today, show this one.

**Checkpoint:** an issue you filed got picked up, reproduced with a failing test, fixed in its own worktree, and turned into a PR, without you running a command to start it. `main` is untouched, and you've watched the sandboxed agent get refused when it reached outside its worktree.

## Agentic OS

Look at what accumulated:

```
.claude/
  rules/          # conventions loaded only when relevant
  agents/         # pm, engineer, qa
  skills/         # /task, /loop
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

- What did the self-healing demo actually catch when you reproduced it?
- What would have happened if QA had write tools during that demo?
- What could the healer have reached on your laptop if it hadn't been running sandboxed?
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
| A failed task leaves mess on your branch | A worktree per task |
| An agent runs unattended on input you didn't write | A sandbox, not just a worktree |
| Two tasks have nothing to do with each other | Dependencies in the backlog, and a loop that reads them |
| You want it to happen **every** time | A hook |
| A second repo needs the same setup | A plugin |

The same triggers say when to update what exists. A repeated mistake is a `CLAUDE.md` edit, not a correction in chat.

## Take-home checklist

- [ ] Check your token cost before you touch anything, `ccusage` first, always
- [ ] Let the Claude Code hook route your commands through `rtk`, and run `rtk discover` on your real history
- [ ] Spec first on real projects, let Claude interrogate you
- [ ] Put `Depends on:` in your backlog, and argue the agent down when it over-declares
- [ ] Give your QA agent no write tools. Highest-value single change here.
- [ ] Split `CLAUDE.md`: always-on stays, conditional moves to `.claude/rules/`
- [ ] One task, one worktree, by default
- [ ] Anything unattended reading input from strangers runs sandboxed
- [ ] Make one "please don't" line from `CLAUDE.md` into a hook
- [ ] Add a `Stop` hook before you run anything unattended
- [ ] Package `.claude/` as a plugin before the next project
</content>
