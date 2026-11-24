---
name: retrospective
description: Record a correction so future sessions follow it. Use when I say I don't like something you did, tell you to remember a rule, or say never to do something again.
argument-hint: [what went wrong]
---

## 1. Pin the lesson
Work out what was done, what I want instead and why. If any of the three is unclear, ask one question.

Write it as one rule. Lead with what to do. Make it concrete. Add the why when it isn't obvious.

> Return early on invalid input instead of nesting the main path in an else. Flat code reads top to bottom.

## 2. Pick its home
Shipyard files live in `~/.claude/shipyard/`, which links to the Shipyard git repo.

| The lesson is about | Home |
|---|---|
| This project only | The project `CLAUDE.md` |
| One language or framework | `~/.claude/shipyard/conventions/<name>.md`, in the matching section |
| Any code anywhere | `~/.claude/shipyard/CLAUDE.md` |
| How a Shipyard step runs | That skill's `SKILL.md` |
| Something review should have caught | `~/.claude/shipyard/agents/spec-reviewer.md` or `quality-reviewer.md`, plus the rule's own home |

In a conventions doc, end the rule with `(lesson)` so `/add-language` keeps it on refresh.

If a regex can catch it with no false alarms, also add a rule to `~/.claude/shipyard/hooks/guard.patterns`, and a blocked and an allowed case to `guard.cases.json` beside it. Both the Windows and Linux hooks read these files. Run `test.ps1` on Windows or `test.sh` on Linux.

If a conventions doc for the language doesn't exist yet, suggest `/add-language`.

## 3. Fit it in
Read the target file. If a rule already covers the lesson, sharpen that rule instead of adding one. If the lesson contradicts a rule, ask me which wins. Keep `CLAUDE.md` files short. Long ones get ignored.

## 4. Apply
Show me the exact edit. Apply it once I agree.

## 5. Report
Name the file and line. If the edit is in the Shipyard repo, commit it there. Ask if I want the original code fixed now.
