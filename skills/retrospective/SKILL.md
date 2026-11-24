---
name: retrospective
description: Improve the setup so the next session goes better. Use when I correct you, tell you to remember a rule, say never to do something again, or ask for a retro.
argument-hint: [what went wrong]
---

Fix the agent's environment, not the code. A lesson only counts if it changes what the next session does.

## 1. Gather
If I named what went wrong, work only on that. Otherwise read this whole session and list where it went wrong: my corrections, rework, review findings, failed or wasted tool calls, things you searched for and couldn't find.

For each, work out what was done, what I wanted instead and why. If any of the three is unclear, ask one question.

## 2. Pick the strongest fix
Each problem gets one fix. Take the first home that can carry it. A check runs every time. A line in `CLAUDE.md` costs attention in every session.

| The fix | Home |
|---|---|
| A regex catches it with no false alarms | `~/.claude/shipyard/hooks/guard.patterns`, with a blocked and an allowed case in `guard.cases.json` |
| The project's linter, typecheck or tests could catch it | A task for me, as a ready `/implement <task>` line |
| It can be judged from a diff | The checks in `~/.claude/shipyard/agents/quality-reviewer.md` or `spec-reviewer.md` |
| A tool call was blocked by a permission that should allow it | `~/.claude/shipyard/install/permissions.json`. Tell me to re-run the installer. |
| An agent must know it before starting: a command, where something lives, a business rule | The project `CLAUDE.md` |
| A way of working that no diff shows, for all code or one language | `~/.claude/shipyard/rules/CLAUDE.md`. Name the language in the rule if it has one. |
| It's about how a Shipyard step runs | That skill's `SKILL.md` |

Write each fix as one concrete rule. Lead with what to do. Add the why when it isn't obvious.

> Run `make db` before `go test ./...`. The integration tests need the local Postgres.

## 3. Check existing rules
Read the target files. If a rule already covers the lesson, sharpen it instead of adding one. If the lesson contradicts a rule, ask me which wins. If a rule was ignored, move it to a stronger home from step 2. Propose cutting a rule when a hook, linter or check now covers it, or when it tells the agent to do what it does anyway.

## 4. Propose
List the fixes, most costly problem first. For each: what went wrong, the home, and the exact edit or `/implement` line. Ask which to apply.

## 5. Apply
Make the approved edits. For a hook rule, run `test.ps1` on Windows or `test.sh` on Linux. List the approved `/implement` lines for me to run.

Report each file and line. Commit edits in the Shipyard repo there. Ask if I want the original code fixed now.
