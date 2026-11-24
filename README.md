# Shipyard

A Claude Code workflow for shipping simple, reused, verified code with agents. It grills the idea, specs it, builds it test-first, reviews it, and learns from your corrections.

New here? Read the [usage guide](GUIDE.md).

## The loop

```
/interview-me <idea> → /to-spec → [/to-tickets <spec>] → /implement <ticket> → review → you commit and push
                                                         ↑                                 │
                                                         └────────── next ticket ──────────┘
/retrospective         any time the agent does something you don't like
/add-language <name>   once per language or framework
/setup-project         once per repo, refresh when it drifts
```

1. **`/interview-me`** interviews you in rounds. Each question comes with a recommended answer. It digs for gaps, edge cases and decisions you haven't made, and ends with a **Decided** list you confirm.
2. **`/to-spec`** turns that into `docs/specs/<slug>/spec.md`. Every behavior has a concrete example, which becomes a test. It tells you whether the spec fits one session.
3. **`/to-tickets`** splits a spec that's too big into vertical-slice tickets you approve. Each can be built and verified alone.
4. **`/implement`** loads the ticket or spec, plus the conventions docs. It plans, then runs red, green, refactor per behavior. Passing tests are frozen. It verifies for real, then calls `review`.
5. **`review`** sends the diff, the intent and the standards to the `reviewer` subagent. It reports two axes separately: **Spec** and **Quality**. `/implement` fixes the findings. You can also run `/review` by hand on any diff.
6. **`/retrospective`** turns a correction into one rule and files it where it belongs. It also fires when you say "don't do that again".
7. **`/add-language`** researches primary sources and writes `conventions/<name>.md`. Implement and review both read it.

You decide at five points: the interview answers, the spec, the ticket split, the final diff, and the push.

## Commits and pushing

Agents commit only when you ask, in a lean style:

```
Add retry to invoice sync

Provider drops ~1% of calls under load.
```

An imperative subject under 50 characters, with no period. Add a body only when the why isn't obvious. One logical change per commit.

Agents can never push or publish. `deny` rules block `git push`, `gh pr create` and `gh pr merge`. The `no-push` hook also catches chained commands, PowerShell, and `publish` commands. Run `git push` yourself with `! git push`.

## What blocks each problem

| Problem | Where it's handled |
|---|---|
| Hard to read | Core rules, conventions docs, refactor step, reviewer check 1 |
| Too many comments | Core rules, reviewer check 2 |
| Duplicated logic | Explore step, refactor step, reviewer greps for existing helpers |
| Over-engineering | Core rules, `/interview-me` pushes for the smallest version, reviewer check 4 |
| Low-value tests | Spec examples become expected values, frozen tests, `guard` hook, reviewer check 5 |
| Hidden failures | Core rules, `guard` hook, spec lists every error case, reviewer check 6 |
| Scope creep, unverified | Spec axis flags unrequested behavior, dependency installs ask you, verify step |

## Files

| File | Role |
|---|---|
| [claude/CLAUDE.md](claude/CLAUDE.md) | Core rules, loaded in every session |
| [claude/skills/](claude/skills/) | `interview-me`, `to-spec`, `to-tickets`, `implement`, `review`, `retrospective`, `add-language`, `setup-project` |
| [claude/agents/reviewer.md](claude/agents/reviewer.md) | Read-only two-axis reviewer |
| [claude/conventions/](claude/conventions/) | One doc per language or framework, from `/add-language` |
| [claude/hooks/guard.patterns](claude/hooks/guard.patterns) | Blocks edits that skip tests or swallow errors |
| [claude/hooks/no-push.patterns](claude/hooks/no-push.patterns) | Blocks push, PR and publish commands |
| `claude/hooks/*.ps1`, `*.sh` | Thin hook runners for Windows and Linux that read the patterns |
| `claude/hooks/*.cases.json`, `test.*` | Shared test cases and a runner per OS |
| [claude/permissions.json](claude/permissions.json) | `ask` and `deny` rules both installers add |
| [install.ps1](install.ps1), [install.sh](install.sh) | Link it all into `~/.claude` on Windows or Linux |

Only `/review` and `/retrospective` are model-invoked. The rest only run when you type them, so they cost no context.

## Where rules live

| Scope | File |
|---|---|
| All code | `claude/CLAUDE.md` |
| One language or framework | `claude/conventions/<name>.md` |
| One project | That repo's `CLAUDE.md` |
| Must never break | A pattern in `guard.patterns` |

The project file wins over a conventions doc. Rules added by `/retrospective` to a conventions doc carry `(lesson)`, so a refresh keeps them.

## Install

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1   # Windows
```
```bash
bash install.sh                                         # Linux, needs jq, git and GNU grep
```

Both installers do the same thing. Each backs up `settings.json` and `CLAUDE.md` to `~/.claude/backups` first. Then it:

- Links `~/.claude/workflow` to `claude/`, and each skill and the `agents` folder into `~/.claude`
- Adds `@~/.claude/workflow/CLAUDE.md` to your `~/.claude/CLAUDE.md`
- Adds both hooks, `deny` rules for pushing, and `ask` rules for dependency installs and manifest edits

Links mean `/retrospective` and `/add-language` edit this repo directly. Commit their changes here. Restart Claude Code after installing.

Then disable the `mattpocock-skills` plugin with `/plugin`. Its `tdd`, `grilling` and `code-review` overlap with these and would compete.

## Per project

Empty repo? Follow [Starting from scratch](GUIDE.md#starting-from-scratch) first.

Run `/setup-project` in the repo. It writes a short `CLAUDE.md` holding only what an agent can't find by looking:

| Section | Holds | Example |
|---|---|---|
| Commands | Build, lint and test commands it ran and saw work | `pnpm test -- path/to/file` |
| Where things live | Folders that matter, shared helpers, specs | Shared helpers: `src/lib/` |
| Conventions | This codebase's own patterns | Errors bubble to `handleRequest` and nowhere else |
| Gotchas | Traps and the reason for each | Never edit `generated/`. `pnpm codegen` overwrites it |

It also lists failed commands, languages missing a conventions doc, and linter rules worth turning on. Keep it under 60 lines. Add to it later with `/retrospective`. Re-run `/setup-project` when it drifts.

The commands matter most. The agent can't verify what it can't run.

## Known gaps

- The guard only sees `Write`, `Edit` and `MultiEdit`. Code written through shell commands skips it. The reviewer still checks.
- The no-push hook reads the whole command text. A command that only mentions a push, like a heredoc writing one into a file, is blocked too. Write such files with the editor tools instead.
- Plain `npm install` also asks, since the rule can't tell restoring from adding.
- Plan mode is denied in your settings, so plans stop in chat.

## Sources

- [Matt Pocock's skills](https://github.com/mattpocock/skills), the starting point for the interview, spec, tickets, TDD and two-axis review
- [Claude Code workflow best practices that ship code](https://dev.to/galian/claude-code-workflow-best-practices-that-ship-code-na)
- [Claude Code hooks and subagents guide 2026](https://dev.to/vibehackers/claude-code-hooks-subagents-power-features-the-complete-guide-2026-c71)
- [Claude Code advanced best practices 2026](https://smartscope.blog/en/generative-ai/claude/claude-code-best-practices-advanced-2026/)
- [The core agentic workflow: task, plan, review, approve, PR](https://dev.to/sahil_kat/the-core-agentic-workflow-task-plan-review-approve-pr-1odj)
- [Agentic workflow best practices, UW-Madison](https://uw-madison-dsi.github.io/FEAST_educational_materials/docs/guides/13-agentic-workflow-best-practices)
- [Agentic SDLC coordinator pattern](https://www.augmentcode.com/guides/agentic-sdlc-coordinator)
