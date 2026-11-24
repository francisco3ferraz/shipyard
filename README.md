# Shipyard

My setup for working with Claude Code.

Agent code usually worked, but it kept going wrong in the same ways: hard to read, too many comments, helpers rewritten instead of reused, too many layers, tests that tested nothing, errors swallowed, unrelated changes, and "done" without running anything. Shipyard is the skills, rules and hooks I use to stop that.

Day-to-day notes are in [docs/GUIDE.md](docs/GUIDE.md).

## How I work

```
/interview-me <idea> → /to-spec → [/to-tickets <spec>] → /implement <ticket> → review → commit → I push
                                                         ↑                                 │
                                                         └────────── next ticket ──────────┘
/retrospective         when the agent does something I don't like
/add-language <name>   once per language or framework
/setup-project         once per repo, again when it drifts
```

1. **`/interview-me`** asks me questions in rounds until every decision is made. Each question comes with its recommended answer, so most of the time I just say yes.
2. **`/to-spec`** writes down what we decided. Every behavior gets a concrete example, which later becomes a test.
3. **`/to-tickets`** splits a spec that's too big for one session into slices I can build and check one at a time.
4. **`/implement`** builds a ticket test-first: red, green, refactor. It verifies the change for real, runs `review`, fixes what it finds and commits.
5. **`review`** runs two subagents side by side. `spec-reviewer` checks the change against what was asked. `quality-reviewer` checks how it's written. I keep them apart so a good-looking diff can't hide a missing behavior, and the other way round.
6. **`/retrospective`** turns a correction into one rule and puts it in the right file, so I only have to say it once.
7. **`/add-language`** researches current, official sources for a language or framework and writes a conventions doc that implement and review both follow.
8. **`/setup-project`** writes a short `CLAUDE.md` for a repo, holding only what an agent can't find by reading the code.

I decide at five points: the interview answers, the spec, the ticket split, the commits, and the push.

## Commits

Agents commit on their own once the work is verified and reviewed. I want commits I can review one at a time: one logical change with its tests, passing on its own, with renames and prefactors in their own commit first. The style is short:

```
Add retry to invoice sync

Provider drops ~1% of calls under load.
```

Agents never push. `deny` rules and the `no-push` hook block it, so pushing stays my call.

## Why each piece exists

| What kept going wrong | What handles it now |
|---|---|
| Hard to read | Core rules, conventions docs, the refactor step, quality check 1 |
| Too many comments | Core rules, quality check 2 |
| Duplicated logic | Searching before writing, the refactor step, quality check 3 |
| Over-engineering | Core rules, the interview asks for the smallest version, quality check 4 |
| Low-value tests | Spec examples become expected values, passing tests are frozen, the `guard` hook, quality check 5 |
| Hidden failures | Core rules, the `guard` hook, every error case in the spec, quality check 6 |
| Scope creep, unverified work | The spec reviewer flags unasked changes, dependency installs ask me, the verify step |

## What's in here

| Path | What it is |
|---|---|
| [rules/CLAUDE.md](rules/CLAUDE.md) | My core coding rules, loaded in every session |
| [skills/](skills/) | The eight skills above |
| [agents/](agents/) | `spec-reviewer` and `quality-reviewer`, both read-only |
| [rules/conventions/](rules/conventions/) | One doc per language or framework |
| [hooks/](hooks/) | `guard` blocks skipped tests and swallowed errors. `no-push` blocks pushes. Rules in `*.patterns`, tests in `*.cases.json` |
| [install/](install/) | Installers for Windows and Linux, and the permission rules they add |

Rules live at four levels. The narrower one wins:

| Applies to | File |
|---|---|
| All code | `rules/CLAUDE.md` |
| One language or framework | `rules/conventions/<name>.md` |
| One project | That repo's `CLAUDE.md` |
| Must never happen | A pattern in `hooks/guard.patterns` |

## Install

```powershell
powershell -ExecutionPolicy Bypass -File install/install.ps1   # Windows
```
```bash
bash install/install.sh                                       # Linux, needs jq, git and GNU grep
```

Both back up `settings.json` and `CLAUDE.md` to `~/.claude/backups` first. Then they link `~/.claude/shipyard` to this repo, link each skill and the agents into `~/.claude`, import the core rules into `~/.claude/CLAUDE.md`, and add the hooks and permission rules.

Because it's linked, not copied, `/retrospective` and `/add-language` edit this repo directly and every session picks the change up. Restart Claude Code after installing.

I turned off the `mattpocock-skills` plugin, since its `tdd`, `grilling` and `code-review` overlap with these.

## Known gaps

- The guard only sees `Write`, `Edit` and `MultiEdit`. Code written through shell commands skips it, though the quality reviewer still looks.
- The no-push hook reads the whole command text, so a command that only mentions a push, like a heredoc, is blocked too.
- Plain `npm install` asks for approval too, since the rule can't tell restoring from adding.
- Plan mode is off in my settings, so plans stop in chat instead.

## Where the ideas came from

- [Matt Pocock's skills](https://github.com/mattpocock/skills), the starting point for the interview, spec, tickets, TDD and two-axis review
- [Claude Code workflow best practices that ship code](https://dev.to/galian/claude-code-workflow-best-practices-that-ship-code-na)
- [Claude Code hooks and subagents guide 2026](https://dev.to/vibehackers/claude-code-hooks-subagents-power-features-the-complete-guide-2026-c71)
- [Claude Code advanced best practices 2026](https://smartscope.blog/en/generative-ai/claude/claude-code-best-practices-advanced-2026/)
- [The core agentic workflow: task, plan, review, approve, PR](https://dev.to/sahil_kat/the-core-agentic-workflow-task-plan-review-approve-pr-1odj)
- [Agentic workflow best practices, UW-Madison](https://uw-madison-dsi.github.io/FEAST_educational_materials/docs/guides/13-agentic-workflow-best-practices)
- [Agentic SDLC coordinator pattern](https://www.augmentcode.com/guides/agentic-sdlc-coordinator)
