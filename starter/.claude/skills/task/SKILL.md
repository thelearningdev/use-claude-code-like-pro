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
