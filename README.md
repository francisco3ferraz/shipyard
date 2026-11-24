# Shipyard

A personal Claude Code setup: skills, rules, subagents and hooks for building software with agents.

It targets the ways agent code tends to go wrong even when it works: hard to read, too many comments, helpers rewritten instead of reused, needless layers, tests that test nothing, swallowed errors, unrelated changes, and work called done without being run.

Usage notes are in [docs/GUIDE.md](docs/GUIDE.md).

## The loop

```
/interview-me <idea> → /to-spec → [/to-tickets <spec>] → /implement <ticket> → review → commit → push
                                                         ↑                                 │
                                                         └────────── next ticket ──────────┘
/retrospective         after a correction or a rough session
/setup-project         once per repo, again when it drifts
```

1. **`/interview-me`** asks questions in rounds until every decision is made. Each question comes with a recommended answer.
2. **`/to-spec`** writes down the decisions. Every behavior gets a concrete example, which later becomes a test.
3. **`/to-tickets`** splits a spec that's too big for one session into slices that can each be built and verified alone.
4. **`/implement`** builds a spec, ticket or task test-first: red, green, refactor. It verifies the change for real, runs `review`, fixes the findings and commits.
5. **`review`** runs two subagents in parallel. `spec-reviewer` checks the change against what was asked. `quality-reviewer` checks how it's written. Keeping them apart stops a clean diff from hiding a missing behavior, and the other way round.
6. **`/retrospective`** turns a correction, or a whole session, into fixes to the setup. Each fix goes in the strongest home that can carry it, preferring checks over lines in a `CLAUDE.md`.
7. **`/setup-project`** writes a short `CLAUDE.md` for a repo, holding only what an agent can't learn from the code.

Human decisions happen at five points: the interview answers, the spec, the ticket split, the commits, and the push.

## Commits

Agents commit once the work is verified and reviewed. Each commit holds one logical change with its tests and passes on its own, with renames and prefactors in their own commit first. The style is short:

```
Add retry to invoice sync

Provider drops ~1% of calls under load.
```

Agents never push. `deny` rules and the `no-push` hook block it.

## What handles each problem

| Problem | Handled by |
|---|---|
| Hard to read | Core rules, the refactor step, quality check 1 |
| Too many comments | Core rules, quality check 2 |
| Duplicated logic | Searching before writing, the refactor step, quality check 3 |
| Over-engineering | Core rules, the interview asks for the smallest version, quality check 4 |
| Low-value tests | Spec examples become expected values, passing tests are frozen, the `guard` hook, quality check 5 |
| Hidden failures | Core rules, the `guard` hook, every error case in the spec, quality check 6 |
| Scope creep, unverified work | The spec reviewer flags unasked changes, dependency installs need approval, the verify step |

## Layout

| Path | Contents |
|---|---|
| [rules/CLAUDE.md](rules/CLAUDE.md) | Core coding rules, loaded in every session |
| [skills/](skills/) | The seven skills above |
| [agents/](agents/) | `spec-reviewer` and `quality-reviewer`, both read-only |
| [hooks/](hooks/) | `guard` blocks skipped tests and swallowed errors. `no-push` blocks pushes. Rules in `*.patterns`, tests in `*.cases.json` |
| [install/](install/) | Installers for Windows and Linux, and the permission rules they add |
| [docs/](docs/) | Usage guide |

Rules live at three levels. The narrower one wins:

| Applies to | File |
|---|---|
| All code | `rules/CLAUDE.md` |
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

The install links rather than copies, so `/retrospective` edits this repo directly and every session sees the change. Restart Claude Code after installing.

Plugins with overlapping skills, like `mattpocock-skills` with its `tdd`, `grilling` and `code-review`, should be turned off.

## Known gaps

- The guard only sees `Write`, `Edit` and `MultiEdit`. Code written through shell commands skips it, though the quality reviewer still checks.
- The no-push hook reads the whole command text, so a command that only mentions a push, like a heredoc, is blocked too.
- Plain `npm install` also needs approval, since the rule can't tell restoring from adding.
- Plan mode is assumed off, so plans stop in chat.

## Sources

- [Matt Pocock's skills](https://github.com/mattpocock/skills), the starting point for the interview, spec, tickets, TDD, two-axis review and retrospective
- [Claude Code workflow best practices that ship code](https://dev.to/galian/claude-code-workflow-best-practices-that-ship-code-na)
- [Claude Code hooks and subagents guide 2026](https://dev.to/vibehackers/claude-code-hooks-subagents-power-features-the-complete-guide-2026-c71)
- [Claude Code advanced best practices 2026](https://smartscope.blog/en/generative-ai/claude/claude-code-best-practices-advanced-2026/)
- [The core agentic workflow: task, plan, review, approve, PR](https://dev.to/sahil_kat/the-core-agentic-workflow-task-plan-review-approve-pr-1odj)
- [Agentic workflow best practices, UW-Madison](https://uw-madison-dsi.github.io/FEAST_educational_materials/docs/guides/13-agentic-workflow-best-practices)
- [Agentic SDLC coordinator pattern](https://www.augmentcode.com/guides/agentic-sdlc-coordinator)
