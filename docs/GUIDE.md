# Shipyard usage guide

Day-to-day usage. What's in the repo and why is in the [README](../README.md).

1. [New machine](#new-machine)
2. [New repo](#new-repo)
3. [Picking a path](#picking-a-path)
4. [The loop](#the-loop)
5. [An example](#an-example)
6. [When things go wrong](#when-things-go-wrong)
7. [Corrections](#corrections)
8. [Upkeep](#upkeep)
9. [Fixing the setup](#fixing-the-setup)
10. [Cheat sheet](#cheat-sheet)

## New machine

1. Clone this repo somewhere permanent. The installer links to it, so moving it later breaks the links.
2. Run the installer:
   ```powershell
   powershell -ExecutionPolicy Bypass -File install/install.ps1   # Windows
   ```
   ```bash
   bash install/install.sh                                       # Linux, needs jq, git and GNU grep
   ```
3. Turn off any plugin with overlapping skills in `/plugin`.
4. Restart Claude Code. Typing `/` should list all eight skills.

Re-run the installer whenever a skill is added, renamed or removed. It's safe to run again.

## New repo

### Existing code

1. `/add-language` for each main language or framework without a doc, like `/add-language go 1.27`. A framework doc builds on its language doc, so add `typescript` before `react`. Read the doc and cut anything that doesn't fit before approving it.
2. `/setup-project` at the repo root. It runs the build, lint and test commands, maps the layout, and asks one round of questions the code can't answer. Each question shows what the code does now and why it matters. "Don't know" is a valid answer for anyone new to the codebase: it keeps the current behavior and lists the question to ask a teammate.
3. It shows a draft `CLAUDE.md` under 60 lines that describes the code as it is today. An answer that asks for a change becomes a task, not a line in the file. It commits the file once approved.

Then work through its hand-off list:

- **Failed commands.** Fix these first. Nothing gets verified if the commands don't run.
- **Linter rules.** Turn them on. Linters catch empty catches and focused tests in places the hooks can't see.
- **Code that differs from a conventions doc.** The code wins unless the team decides otherwise.
- **Open questions.** Ask a teammate, then add the answer with `/retrospective`.
- **Tasks.** Each comes as a ready `/implement` or `/interview-me` line.

### From scratch

`/setup-project` needs code to read, so an empty repo starts with a **walking skeleton**: the thinnest version that builds, lints, tests and runs one trivial behavior end to end.

1. `git init` and open Claude Code there.
2. `/interview-me <what to build>`. It also asks about stack, storage and how it runs. The boring, well-known option is usually right.
3. `/add-language` for that stack, so the skeleton follows its conventions from the first line.
4. `/to-spec`, then `/to-tickets`. Ticket 01 is always the skeleton.
5. `/implement` ticket 01 in a fresh session.
6. `/setup-project`, now that there are real commands and a layout.
7. Continue with ticket 02.

Keep the skeleton tiny. Its job is to prove the commands work, not to start on features.

## Picking a path

| Task | Path |
|---|---|
| Typo, rename, one-line fix | Just ask. The core rules still apply. |
| Small change with every decision already made | `/implement <task, with the decisions in it>` |
| A feature that fits in a few sentences | `/interview-me` → `/to-spec` → `/implement <spec>` |
| A feature across layers or several sessions | `/interview-me` → `/to-spec` → `/to-tickets` → `/implement` per ticket |
| A brand-new project | [From scratch](#from-scratch) |
| A second opinion on any diff | `/review [spec path] [base ref]` |

If the decisions don't fit in one line, start with `/interview-me`.

## The loop

### `/interview-me <idea>`

It looks things up in the code first, then asks in rounds:

```
**Q1. Duplicate emails**
Two users sign up with the same email in different cases. Same account or two?
Recommend: same account. Compare emails lowercased.
```

Answer by number, like "Q1 yes, Q2 the second one, Q3 not sure, what would you do?". "Out of scope" is always an option, and the smaller first version is usually the right one. It keeps a **Decided** list and stops when nothing is left to ask and the list is confirmed.

### `/to-spec`

Same session, right after the interview. It writes `docs/specs/<slug>/spec.md` from the decisions without asking anything new. If a decision is missing, it says so and stops.

The spec is the cheapest place to catch a mistake. Check that:

- Every behavior has a real example, input and expected output. Those become the tests.
- Every error case says exactly what the user sees.
- **Out of scope** lists what was ruled out.

Once approved, it says whether the spec fits one session or needs tickets. A spec records a decision. After it's built, leave it alone. Code and tests hold the current truth, and a later change gets its own spec.

### `/to-tickets <spec path>`

It splits the spec into slices that each work end to end:

```
1. Prefactor: extract email normalizer     Blocked by: none
2. Sign up with a new email                Blocked by: 1
3. Reject duplicate email                  Blocked by: 2
```

Push back on horizontal tickets like "add the DB table", and on anything too big for one session.

### `/implement <spec, ticket or task>`

Use a fresh session per ticket. Leftover context makes the agent sloppier.

1. **Load** the ticket, spec, project `CLAUDE.md` and conventions docs.
2. **Explore** the code it will touch and find what to reuse.
3. **Plan.** It only stops for approval if the plan goes beyond the spec, like a new module or dependency. For a plain task it always stops.
4. **Build test-first.** Failing test, watch it fail, simplest code to pass, clean up. A test that has passed is frozen.
5. **Verify.** Full tests, typecheck, linter, then the change for real.
6. **Review** with both reviewers and fix the findings, two rounds at most.
7. **Close.** Tick the ticket, commit, report.

The report lists the commits, what ran, what couldn't be verified, and problems seen but left alone.

### Reading the commits and pushing

Read each commit with `git show`. Look hardest at:

- Tests: do they check what the spec says, with real values?
- Errors: does anything get swallowed?
- Whatever the report says couldn't be verified.

Fixes land as new commits. When it's right, push with `! git push`.

## An example

Making categories case-insensitive in a small Go expense tracker. The decision was already made, so the interview was skipped:

```
> /implement lowercase categories when they're added. Old entries stay as they are.
```

The plan had two tests through a real `Store` in a temp dir: `Food` is saved as `food`, and an old `Food` entry stays as it is. It was approved with one addition: run `list` in the real check too. The agent wrote the tests, watched them fail, added one `strings.ToLower`, and ran `add 5 Food` and `list` against a file with an old entry. The quality reviewer flagged that the project `CLAUDE.md` still described the feature as missing, so that line was fixed in the same change.

## When things go wrong

**The agent did something unwanted.** Say so plainly, then run `/retrospective` so it sticks.

**The guard blocks an edit.** The agent tried to skip a test or swallow an error, and should fix the code instead. A real exception, like a best-effort cache warmup, can carry `guard-ok: <reason>` on that line, and the agent has to explain why.

**A dependency install asks for approval.** Approve only if the plan said a new dependency was needed.

**The agent wants to change a test.** It has to stop and explain. If the test really is wrong, say so. Otherwise it fixes the code.

**Review finds the same thing twice.** It stops after two rounds and reports what's left for a human to decide.

**It built the wrong thing.** The spec was vague. Fix the spec, then implement again, rather than patching around it.

**It goes in circles.** Stop it and start a fresh session on the same ticket.

## Corrections

A correction should only be needed once. Run `/retrospective` right after correcting the agent. It also kicks in on phrases like "never do that again".

It works out what happened, what's wanted instead and why, writes one concrete rule, and files it:

| The lesson is about | It goes in |
|---|---|
| This project only | The project `CLAUDE.md` |
| One language or framework | `rules/conventions/<name>.md`, tagged `(lesson)` |
| Any code | `rules/CLAUDE.md` |
| How a skill runs | That skill's `SKILL.md` |
| Something review missed | The matching reviewer in `agents/`, plus the rule's own home |

If a regex can catch the mistake reliably, it also goes in `hooks/guard.patterns` with test cases. The edit is shown before it's applied, then committed in this repo.

Concrete rules work, vague ones don't:

- Vague: "Write cleaner code."
- Concrete: "Return early on invalid input instead of nesting the main path in an else. Flat code reads top to bottom."

## Upkeep

**Push this repo too.** `/retrospective` and `/add-language` commit here. `git log` shows how the rules changed, and `git revert` undoes a bad one.

**Prune monthly.** Read `rules/CLAUDE.md` and the conventions docs. Delete rules that never matter or that a linter now covers. Long rule files get ignored.

**Keeping docs current:**

| File | Goes stale when | Kept current by |
|---|---|---|
| A project `CLAUDE.md` | A command, folder or pattern changes | The quality reviewer flags it, and it's fixed in the same change. Re-run `/setup-project` after big restructures. |
| Conventions docs | The project moves to a newer version | `/implement` reports the gap. `/add-language <name> <version>` refreshes it and keeps `(lesson)` rules. |
| Specs and tickets | Never | They record a decision. Code and tests hold the current truth. |

**Testing the hooks after changing them:**

```powershell
powershell -ExecutionPolicy Bypass -File hooks/test.ps1   # Windows
bash hooks/test.sh                                         # Linux
```

Rules are in `*.patterns` and cases in `*.cases.json`, shared by both OSes. Edit those, not the scripts.

**Repeated review findings** mean a rule belongs earlier: in a `CLAUDE.md`, a conventions doc, or the linter.

## Fixing the setup

**Skills missing after `/`.** Re-run the installer and restart. `~/.claude/skills/<name>` should link into this repo.

**Rules not applying.** `~/.claude/CLAUDE.md` should contain `@~/.claude/shipyard/rules/CLAUDE.md` between the `shipyard` markers.

**A hook blocks something legitimate.** Add the false alarm to its `.cases.json`, fix the pattern in its `.patterns`, run the tests.

**Two skills compete,** like a plugin's `code-review` and this `review`. Turn the plugin off in `/plugin`.

**Repo moved.** Re-run the installer from the new location. It removes links whose target is gone and creates the new ones.

**Uninstall.** Remove the links in `~/.claude` and `~/.claude/skills`, with `cmd /c rmdir <path>` on Windows or `rm <path>` on Linux. Delete the `shipyard` block from `~/.claude/CLAUDE.md`, and restore `settings.json` from `~/.claude/backups`.

## Cheat sheet

| Command | When |
|---|---|
| `/setup-project` | Once per repo, again when it drifts |
| `/add-language <name> [version]` | Once per language or framework |
| `/interview-me <idea>` | Any feature with open decisions |
| `/to-spec` | Right after the interview |
| `/to-tickets <spec>` | When the spec needs more than one session |
| `/implement <spec, ticket or task>` | Fresh session per ticket |
| `/review [spec] [base ref]` | Any diff, any time |
| `/retrospective` | Right after a correction |
| `! git push` | Pushing stays manual |
