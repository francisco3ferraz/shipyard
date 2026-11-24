# How I use Shipyard

My notes on using this day to day. What's in the repo and why is in the [README](README.md).

1. [New machine](#new-machine)
2. [New repo](#new-repo)
3. [Picking a path](#picking-a-path)
4. [The loop](#the-loop)
5. [An example](#an-example)
6. [When things go wrong](#when-things-go-wrong)
7. [Correcting it](#correcting-it)
8. [Upkeep](#upkeep)
9. [Fixing the setup](#fixing-the-setup)
10. [Cheat sheet](#cheat-sheet)

## New machine

1. Clone this repo somewhere it can stay. The installer links to it, so moving it later breaks the links.
2. Run the installer:
   ```powershell
   powershell -ExecutionPolicy Bypass -File install.ps1   # Windows
   ```
   ```bash
   bash install.sh                                         # Linux, needs jq, git and GNU grep
   ```
3. Turn off any plugin with overlapping skills in `/plugin`.
4. Restart Claude Code. Typing `/` should list all eight skills.

Re-run the installer whenever a skill is added, renamed or removed. It's safe to run again.

## New repo

### Existing code

1. `/add-language` for each main language or framework that has no doc yet, like `/add-language go 1.27`. A framework doc builds on its language doc, so add `typescript` before `react`. I read the doc and cut anything I disagree with before approving it.
2. `/setup-project` at the repo root. It runs the build, lint and test commands, maps the layout, and asks one round of questions the code can't answer. Each question shows what the code does now and why it matters. When I'm new to a codebase, "don't know" is a fine answer: it keeps the current behavior and lists the question for me to ask someone.
3. It shows a draft `CLAUDE.md` under 60 lines, describing the code as it is today. If an answer of mine asks for a change, that becomes a task, not a line in the file. It commits the file once I approve.

Then I work through its hand-off list:

- **Failed commands.** Fix them first. Nothing gets verified if the commands don't run.
- **Linter rules.** Turn them on. Linters catch empty catches and focused tests in places the hooks can't see.
- **Code that differs from a conventions doc.** The code wins unless the team decides otherwise.
- **Open questions.** Ask someone, then add the answer with `/retrospective`.
- **Tasks.** Each comes as a ready `/implement` or `/interview-me` line.

### From scratch

`/setup-project` needs code to read, so an empty repo starts with a **walking skeleton**: the thinnest version that builds, lints, tests and runs one trivial behavior end to end.

1. `git init` and open Claude Code there.
2. `/interview-me <what I want to build>`. It also asks about stack, storage and how it runs. I go with the boring option unless there's a reason not to.
3. `/add-language` for that stack, so the skeleton follows its conventions from the first line.
4. `/to-spec`, then `/to-tickets`. Ticket 01 is always the skeleton.
5. `/implement` ticket 01 in a fresh session.
6. `/setup-project`, now that there are real commands and a layout.
7. Carry on with ticket 02.

The skeleton stays tiny. Its job is to prove the commands work, not to start on features.

## Picking a path

| Task | Path |
|---|---|
| Typo, rename, one-line fix | Just ask. The core rules still apply. |
| Small change where I've already decided everything | `/implement <task, with the decisions in it>` |
| A feature I can describe in a few sentences | `/interview-me` → `/to-spec` → `/implement <spec>` |
| A feature across layers or several sessions | `/interview-me` → `/to-spec` → `/to-tickets` → `/implement` per ticket |
| A brand-new project | [From scratch](#from-scratch) |
| A second opinion on any diff | `/review [spec path] [base ref]` |

If I can't write the decisions down in one line, I start with `/interview-me`.

## The loop

### `/interview-me <idea>`

It looks things up in the code first, then asks in rounds:

```
**Q1. Duplicate emails**
Two users sign up with the same email in different cases. Same account or two?
Recommend: same account. Compare emails lowercased.
```

I answer by number, like "Q1 yes, Q2 the second one, Q3 not sure, what would you do?". "Out of scope" is always an option, and the smaller first version is usually the right one. It keeps a **Decided** list and stops when there's nothing left to ask and I confirm the list.

### `/to-spec`

Same session, right after the interview. It writes `docs/specs/<slug>/spec.md` from the decisions without asking anything new. If a decision is missing, it says so and stops.

This is the cheapest place to catch a mistake, so I read it properly:

- Every behavior has a real example, input and expected output. Those become the tests.
- Every error case says exactly what the user sees.
- **Out of scope** lists what I said no to.

Once I approve, it tells me whether it fits one session or needs tickets. A spec is a record of a decision. After it's built I leave it alone. The code and tests are the current truth, and a later change gets its own spec.

### `/to-tickets <spec path>`

It splits the spec into slices that each work end to end:

```
1. Prefactor: extract email normalizer     Blocked by: none
2. Sign up with a new email                Blocked by: 1
3. Reject duplicate email                  Blocked by: 2
```

I push back on horizontal tickets like "add the DB table", and on anything too big for one session.

### `/implement <spec, ticket or task>`

A fresh session per ticket. Leftover context makes it sloppier.

1. **Load** the ticket, spec, project `CLAUDE.md` and conventions docs.
2. **Explore** the code it will touch and find what to reuse.
3. **Plan.** It only stops for me if the plan goes beyond the spec, like a new module or dependency. For a plain task it always stops.
4. **Build test-first.** Failing test, watch it fail, simplest code to pass, clean up. A test that has passed is frozen.
5. **Verify.** Full tests, typecheck, linter, then the change for real.
6. **Review** with both reviewers and fix the findings, two rounds at most.
7. **Close.** Tick the ticket, commit, report.

The report lists the commits, what ran, what it couldn't verify, and problems it saw but left alone.

### Reading the commits and pushing

I read each commit with `git show`. The reviewers catch a lot, but it's still my code. I look hardest at:

- Tests: do they check what the spec says, with real values?
- Errors: does anything get swallowed?
- Whatever the report says it couldn't verify.

Fixes land as new commits. When it's right, I push with `! git push`.

## An example

Making categories case-insensitive in my expense tracker. The decision was already made, so I skipped the interview:

```
> /implement lowercase categories when they're added. Old entries stay as they are.
```

It planned two tests through a real `Store` in a temp dir: `Food` gets saved as `food`, and an old `Food` entry stays as it is. I approved, adding that the real check should also run `list`. It wrote the tests, watched them fail, added one `strings.ToLower`, and ran `add 5 Food` and `list` against a file with an old entry. The quality reviewer flagged that the project `CLAUDE.md` still said the feature was missing, so that line got fixed in the same change.

## When things go wrong

**It did something I don't like.** I say so plainly, then run `/retrospective` so it sticks.

**The guard blocks an edit.** It tried to skip a test or swallow an error, and should fix the code instead. A real exception, like a best-effort cache warmup, can carry `guard-ok: <reason>` on that line, and it has to tell me why.

**A dependency install asks for approval.** I approve only if the plan said a new dependency was needed.

**It wants to change a test.** It has to stop and explain. If the test really is wrong, I say so. Otherwise it fixes the code.

**Review finds the same thing twice.** It stops after two rounds and reports what's left. I decide.

**It built the wrong thing.** The spec was vague. I fix the spec, then implement again, rather than patching around it.

**It goes in circles.** I stop it and start a fresh session on the same ticket.

## Correcting it

Every correction should only be needed once. Right after I correct something, I run `/retrospective`. It also kicks in when I say things like "never do that again".

It works out what happened, what I want instead and why, writes one concrete rule, and puts it where it belongs:

| The lesson is about | It goes in |
|---|---|
| This project only | The project `CLAUDE.md` |
| One language or framework | `claude/conventions/<name>.md`, tagged `(lesson)` |
| Any code | `claude/CLAUDE.md` |
| How a skill runs | That skill's `SKILL.md` |
| Something review missed | The matching reviewer in `claude/agents/`, plus the rule's own home |

If a regex can catch the mistake reliably, it also goes in `guard.patterns` with test cases. It shows me the edit before applying it, then commits it in this repo.

Concrete rules work, vague ones don't:

- Vague: "Write cleaner code."
- Concrete: "Return early on invalid input instead of nesting the main path in an else. Flat code reads top to bottom."

## Upkeep

**Push this repo too.** `/retrospective` and `/add-language` commit here. `git log` shows how the rules changed, and `git revert` undoes a bad one.

**Prune once a month.** Read `claude/CLAUDE.md` and the conventions docs. Delete rules that never matter or that a linter now covers. Long rule files get ignored.

**Keeping docs current:**

| File | Goes stale when | Kept current by |
|---|---|---|
| A project `CLAUDE.md` | A command, folder or pattern changes | The quality reviewer flags it, and it's fixed in the same change. `/setup-project` again after big restructures. |
| Conventions docs | The project moves to a newer version | `/implement` reports the gap. `/add-language <name> <version>` refreshes it and keeps `(lesson)` rules. |
| Specs and tickets | Never | They record a decision. Code and tests hold the current truth. |

**Testing the hooks after changing them:**

```powershell
powershell -ExecutionPolicy Bypass -File claude\hooks\test.ps1   # Windows
bash claude/hooks/test.sh                                         # Linux
```

Rules are in `*.patterns` and cases in `*.cases.json`, shared by both OSes. I edit those, not the scripts.

**Repeated review findings** mean a rule belongs earlier: in a `CLAUDE.md`, a conventions doc, or the linter.

## Fixing the setup

**Skills missing after `/`.** Re-run the installer and restart. `~/.claude/skills/<name>` should link into this repo.

**Rules not applying.** `~/.claude/CLAUDE.md` should contain `@~/.claude/shipyard/CLAUDE.md` between the `shipyard` markers.

**A hook blocks something legitimate.** Add the false alarm to its `.cases.json`, fix the pattern in its `.patterns`, run the tests.

**Two skills compete,** like a plugin's `code-review` and this `review`. Turn the plugin off in `/plugin`.

**Repo moved.** Remove the old links in `~/.claude` and `~/.claude/skills`, with `cmd /c rmdir <path>` on Windows or `rm <path>` on Linux, then re-run the installer.

**Uninstall.** Remove the links the same way, delete the `shipyard` block from `~/.claude/CLAUDE.md`, and restore `settings.json` from `~/.claude/backups`.

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
| `! git push` | Only I push |
