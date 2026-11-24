# Shipyard usage guide

How to use Shipyard day to day. For what's in the repo and why, see the [README](README.md).

## Contents

1. [First-time setup](#1-first-time-setup)
2. [Set up a project](#2-set-up-a-project)
3. [Pick the right path for the task](#3-pick-the-right-path-for-the-task)
4. [The full loop, step by step](#4-the-full-loop-step-by-step)
5. [A worked example](#5-a-worked-example)
6. [When something goes wrong](#6-when-something-goes-wrong)
7. [Teaching the workflow](#7-teaching-the-workflow)
8. [Keeping it healthy](#8-keeping-it-healthy)
9. [Troubleshooting](#9-troubleshooting)
10. [Cheat sheet](#10-cheat-sheet)

---

## 1. First-time setup

Do this once per machine.

1. Clone this repo somewhere permanent. The installer links to it, so don't move it later.
2. Run the installer for your OS:
   ```powershell
   # Windows
   powershell -ExecutionPolicy Bypass -File install.ps1
   ```
   ```bash
   # Linux. Needs jq, git and GNU grep.
   bash install.sh
   ```
3. In Claude Code, open `/plugin` and disable any plugin whose skills overlap, like `mattpocock-skills`.
4. Restart Claude Code.

Check it worked. In a new session, type `/` and you should see `interview-me`, `to-spec`, `to-tickets`, `implement`, `review`, `retrospective`, `add-language` and `setup-project`.

Re-run the installer any time you add, rename or remove a skill. It's safe to run again.

## 2. Set up a project

Do this once per repo, before the first feature.

### Starting from scratch

`/setup-project` needs code to read, so an empty repo starts with a **walking skeleton**: the thinnest version that builds, lints, tests and runs one trivial behavior end to end.

1. `git init` an empty folder and open Claude Code there.
2. `/interview-me <what you want to build>`. It also asks about stack, storage and how it runs. Pick the boring option unless you have a reason.
3. `/add-language` for the stack you chose, so the skeleton follows its conventions from line one.
4. `/to-spec`, then `/to-tickets`. Ticket 01 is always the walking skeleton.
5. `/implement` ticket 01 in a fresh session. It commits the skeleton.
6. `/setup-project`. Now it has real commands to verify and a layout to map.
7. Carry on with ticket 02 as usual.

Keep the skeleton tiny. Its job is to prove the commands work, not to start the features.

### Existing project

#### `/setup-project`

Run it at the repo root. It:

1. Reads manifests, CI, linter and test config, the README and recent commits.
2. Runs the build, lint and test commands, and keeps only the ones that worked.
3. Maps the folders that matter, shared helpers and test fixtures.
4. Notes patterns this codebase uses that a newcomer would miss.
5. Asks you one round of questions the code can't answer: gotchas, no-go areas, business rules. Each shows what the code does now and why it matters. New to the repo? Answer "don't know". It keeps the current behavior and lists the question for you to ask a teammate.
6. Shows a draft `CLAUDE.md` under 60 lines. It writes it once you approve.

The `CLAUDE.md` describes the code as it is today. If one of your answers asks for a change, like "categories should ignore case", that becomes a task, not a line in the file.

At the end it gives you a hand-off list. Act on each part:

- **Failed commands.** Fix them or tell the agent the right one. A command that doesn't run means nothing gets verified.
- **Missing conventions.** Run `/add-language` for each.
- **Linter rules.** Turn them on yourself. Linters catch empty catches and focused tests in places the hooks can't see.
- **Code that differs from a conventions doc.** The code wins by default. Change it only if your team agrees.
- **Open questions.** Ask a teammate, then add the answer with `/retrospective`.
- **Tasks.** Each comes as a ready `/implement` or `/interview-me` line. Run them once `CLAUDE.md` is committed.

The agent commits `CLAUDE.md` once you approve the draft.

#### `/add-language <name> [version]`

Run it once per language or framework, for example `/add-language python 3.13` or `/add-language react 19`. It searches official docs and tool docs, keeps only rules that change the code an agent writes, and saves `claude/conventions/<name>.md` in this repo.

Read the doc before you accept it. Cut anything you disagree with. Once you approve, the agent commits it **in this repo**, since it's shared by every project.

A framework doc builds on its language doc. Add `typescript` before `react`.

## 3. Pick the right path for the task

Not every task needs the full loop. Match the effort to the size.

| Task | Path |
|---|---|
| Typo, rename, one-line fix | Just ask. The core rules still apply. |
| Small bug or change in one or two files | `/implement <describe the task>` |
| A feature you can describe in a few sentences | `/interview-me` → `/to-spec` → `/implement <spec>` |
| A feature that spans layers or several sessions | `/interview-me` → `/to-spec` → `/to-tickets` → `/implement` per ticket |
| A brand-new project | See [Starting from scratch](#starting-from-scratch) |
| Reviewing any diff, branch or PR | `/review [spec path] [base ref]` |

When in doubt, start with `/interview-me`. If it finds nothing to ask, the task really is small.

## 4. The full loop, step by step

### Step 1: `/interview-me <idea>`

Describe the idea in a sentence or two. The agent looks up facts in the code first, then asks questions in rounds.

Each question looks like this:

```
**Q1. Duplicate emails**
Two users sign up with the same email in different cases. Same account or two?
Recommend: same account. Compare emails lowercased.
```

How to answer well:

- Answer by number. "Q1 yes, Q2 the second option, Q3 not sure, what would you do?"
- Agree with the recommendation by just saying "yes". It's usually a good default.
- Say "out of scope" freely. A smaller first version is almost always better.
- If a question shows you haven't decided something, that's the point. Decide now, not mid-build.

After each round it keeps a **Decided** list. It's done when there's nothing left to ask and you confirm the list.

### Step 2: `/to-spec`

Run it in the same session, right after the interview. It writes `docs/specs/<slug>/spec.md` from what you decided, without asking new questions. If something is missing, it tells you and stops.

Review the spec carefully. This is the cheapest place to catch a mistake. Check that:

- Every behavior has a concrete example, with real input and expected output. These become the tests.
- Every error case says exactly what the user sees.
- **Out of scope** lists what you said no to.

Ask for changes in plain words. When you approve, it marks the spec `Status: approved` and tells you whether it fits one session.

### Step 3: `/to-tickets <spec path>` (big work only)

It splits the spec into vertical slices. Each slice works end to end and can be checked on its own. You'll see a list like:

```
1. Prefactor: extract email normalizer     Blocked by: none
2. Sign up with a new email                Blocked by: 1
3. Reject duplicate email                  Blocked by: 2
```

Push back if a ticket is a horizontal layer like "add the DB table", or too big for one session. When you approve, it writes one file per ticket next to the spec.

### Step 4: `/implement <spec or ticket path>`

Start a **fresh session** for each ticket. Old context makes the agent sloppier.

What happens:

1. **Load.** It reads the ticket, the spec, the project `CLAUDE.md` and the conventions docs. It checks that blocking tickets are done.
2. **Explore.** It reads the code it will change and finds helpers to reuse.
3. **Plan.** It lists the behaviors, the reuse and anything new. It only stops for your approval if the plan goes beyond the spec, like a new module or a dependency. For a plain-text task, it always stops.
4. **Build test-first.** For each behavior: write a failing test, watch it fail, write the simplest code to pass, then clean up. A test that has passed is frozen.
5. **Verify.** Full test suite, typecheck, linter, then it runs the change for real.
6. **Review.** It calls `review`, which runs `spec-reviewer` and `quality-reviewer` in parallel. It fixes the findings. Up to two rounds.
7. **Close.** It ticks the ticket, sets `Status: done`, commits, and reports.

Commits are sized to review one at a time. Each holds one logical change with its tests and passes on its own. A prefactor or rename comes first in its own commit. Files are staged by name, and anything left out is reported.

You'll get a report with the commits, commands run, anything it couldn't verify and problems it left alone.

### Step 5: you review the commits and push

Read each commit with `git show` or in your editor. The reviewers are good, but you own the code. Look hardest at:

- Tests: do they check what the spec says, with real values?
- Error handling: does anything get swallowed?
- Anything the report says it couldn't verify.

Ask for fixes, and they land as new commits. When it's right, push with `! git push`. Agents can't push.

Next ticket: new session, `/implement` the next one.

## 5. A worked example

Adding password reset to a web app.

```
> /interview-me users can reset their password by email
```

The agent finds the existing mailer and user model, then asks round 1: token lifetime, single-use or not, what happens for an unknown email, rate limits. You answer. Round 2 follows from your answers: what the email says, whether old sessions get logged out. You confirm the Decided list.

```
> /to-spec
```

It writes `docs/specs/password-reset/spec.md`. One behavior reads:

> When a user requests a reset for a known email, then they get one email with a link valid for 30 minutes. Example: request at 10:00 for `ana@x.com`, link works at 10:29, fails at 10:31 with "Link expired".

You approve. It says the spec is too big for one session.

```
> /to-tickets docs/specs/password-reset/spec.md
```

Three tickets: request a reset, use the link, expire and reuse rules. You approve.

New session:

```
> /implement docs/specs/password-reset/01-request-reset.md
```

It writes a failing test for "known email gets one email", makes it pass with the existing mailer, then moves on. The quality reviewer flags a `try/except` that hid mailer errors. It fixes it. It commits. You read the commits, push, and start the next ticket in a fresh session.

## 6. When something goes wrong

**The agent did something you don't like.** Say so plainly, like "don't wrap this in a class". Then run `/retrospective` so it never happens again. See [section 7](#7-teaching-the-workflow).

**An edit gets blocked by the guard.** The agent tried to skip a test or swallow an error. It sees the reason and should fix the code. If the exception is truly right, like a best-effort cache warmup, it can add `guard-ok: <reason>` on that line, and it must tell you why.

**A push gets blocked.** That's on purpose. Run `! git push` yourself.

**A dependency install asks for permission.** Approve it only if the plan said a new dependency was needed. Otherwise say no and ask why.

**The agent wants to change a test.** It must stop and explain why the test is wrong. If you agree, say so. If not, tell it to fix the code.

**The review finds the same issue twice.** The skill stops after two rounds and reports what's left. Decide yourself, or fix it with a clear instruction.

**The agent built the wrong thing.** The spec was probably vague. Fix the spec first, then `/implement` again. Don't patch around a bad spec.

**The agent goes in circles.** Stop it. Start a fresh session and give it the ticket again. Long, messy sessions rarely recover.

**You want a second opinion on any diff.** Run `/review` by hand. It works on uncommitted changes, a branch, or a base ref like `/review docs/specs/x/spec.md main`.

## 7. Teaching the workflow

The workflow gets better each time you correct it. This is the most important habit.

### `/retrospective`

Run it right after you correct the agent, while the context is fresh. It also fires on its own when you say things like "never do that again".

It will:

1. Pin down what was done, what you want instead, and why.
2. Write it as one concrete rule that leads with what to do.
3. Pick the right home for it:

| The lesson is about | It goes in |
|---|---|
| This project only | The project `CLAUDE.md` |
| One language or framework | `claude/conventions/<name>.md`, tagged `(lesson)` |
| Any code anywhere | `claude/CLAUDE.md` |
| How a workflow step runs | That skill's `SKILL.md` |
| Something review missed | `claude/agents/spec-reviewer.md` or `quality-reviewer.md`, plus the rule's own home |

4. Show you the exact edit and apply it once you agree.
5. If a regex can catch the mistake reliably, add it to `guard.patterns` with test cases.

Edits to `claude/` land in this repo, because of the links. The agent commits them here. Push them yourself.

Good lessons are concrete:

- Weak: "Write cleaner code."
- Strong: "Return early on invalid input instead of nesting the main path in an else. Flat code reads top to bottom."

## 8. Keeping it healthy

**Push workflow changes.** `/retrospective` and `/add-language` commit in this repo. Push those commits too. Use `git log` here to see how your rules evolved, and `git revert` to undo a bad one.

**Prune monthly.** Read `claude/CLAUDE.md` and each conventions doc. Delete rules that never fire or that the linter now covers. Long rule files get ignored.

**How files that describe changing things stay fresh:**

| File | Goes stale when | Kept fresh by |
|---|---|---|
| Project `CLAUDE.md` | A command, folder or pattern changes | The quality reviewer flags the stale line, and it's fixed in that same change. Re-run `/setup-project` after big restructures. |
| Conventions docs | The project moves to a newer version | `/implement` reports the gap. Run `/add-language <name> <version>`. It keeps your `(lesson)` rules. |
| Specs and tickets | Never | They record a decision at one point in time. Code and tests hold the current truth. A later change gets its own spec. |

**Test the hooks after editing them:**

```powershell
powershell -ExecutionPolicy Bypass -File claude\hooks\test.ps1   # Windows
bash claude/hooks/test.sh                                         # Linux
```

Rules live in `*.patterns` and test cases in `*.cases.json`. Both OSes share them, so edit those, not the scripts.

**Watch the review findings.** If a reviewer keeps flagging the same thing, the rule belongs earlier: in `CLAUDE.md`, a conventions doc, or the linter.

## 9. Troubleshooting

**Skills don't show up after `/`.** Re-run the installer and restart Claude Code. Check that `~/.claude/skills/<name>` is a link into this repo.

**Rules don't seem to apply.** Check `~/.claude/CLAUDE.md` contains `@~/.claude/workflow/CLAUDE.md` between the `workflow` markers.

**A hook blocks something legitimate.** Add a case for the false alarm to its `.cases.json`, fix the pattern in its `.patterns` file, then run the tests.

**Two skills compete,** for example a plugin's `code-review` and this `review`. Disable the plugin in `/plugin`.

**You moved this repo.** The links break. Remove the old links in `~/.claude` and `~/.claude/skills` with `cmd /c rmdir <path>` on Windows or `rm <path>` on Linux, then re-run the installer.

**Uninstall.** Remove the links the same way, delete the workflow block from `~/.claude/CLAUDE.md`, and restore `settings.json` from `~/.claude/backups`.

## 10. Cheat sheet

| Command | When |
|---|---|
| `/setup-project` | Once per repo, again when it drifts |
| `/add-language <name> [version]` | Once per language or framework |
| `/interview-me <idea>` | Start of any real feature |
| `/to-spec` | Right after the interview, same session |
| `/to-tickets <spec>` | When the spec is too big for one session |
| `/implement <spec, ticket or task>` | Fresh session per ticket |
| `/review [spec] [base ref]` | Any diff, any time |
| `/retrospective` | Right after you correct the agent |
| `! git push` | Only you push |

Your five decision points: the interview answers, the spec, the ticket split, reviewing the commits, and the push.
