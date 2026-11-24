---
name: setup-project
description: Write or refresh the project's CLAUDE.md from what the repo actually contains.
disable-model-invocation: true
---

A project `CLAUDE.md` loads in every session, so every line costs attention. It holds only what an agent can't find by looking: verified commands, where things live, this codebase's own patterns, and gotchas. Everything else stays in the code and config, where it can't go stale.

## 1. Survey
If the repo has no code yet, stop. Tell me to build the walking skeleton first: `/interview-me`, `/to-spec`, `/to-tickets`, then `/implement` ticket 01. Run this skill after that.

Read the manifests, scripts, CI config, linter and test config, `README`, `CONTRIBUTING`, the top-level layout and the last 20 commit messages. If a `CLAUDE.md` or `AGENTS.md` already exists, this is a refresh. Keep what is still true and cut the rest.

## 2. Verify the commands
Find the commands for build or typecheck, lint, all tests, one test file, and running locally. Run each one except running locally. Record only the commands that worked. List the ones that failed, with their error.

## 3. Map
Note the folders that matter and what each holds. Find where shared helpers and test fixtures live. Use the project's specs folder if it has one. Otherwise use `docs/specs/`.

## 4. Read the patterns
Read a few typical files and tests. Note only patterns that differ from common defaults or that a newcomer would get wrong: how errors flow, how tests are set up, what gets mocked, naming habits.

List the languages and frameworks in use. Name the ones with no doc in `~/.claude/shipyard/conventions/`, so I can run `/add-language`.

Where the code consistently differs from a conventions doc, the code wins. Write the code's pattern into `CLAUDE.md` and list the difference for the hand-off. Don't ask me about it.

Check whether the linter flags empty catches, swallowed errors, and skipped or focused tests. List the rules to turn on. Don't change the config.

## 5. Ask me
Assume I may be new here and know less than you about this code. Ask one numbered round, only about what the code can't tell you: the reasons behind odd code, business rules, areas agents must not touch, and mistakes agents made here before.

Format each question like this:

```
**Q1. <short title>**
Now: <what the code does, with a `path:line` link>
Why it matters: <what an agent might get wrong>
Ask: <the question>
Guess: <your best guess>
```

"Don't know" is a full answer. For those, write what the code does now as the rule, and list the question for the hand-off so I can ask a teammate.

An answer that asks the code to change is a task, not a rule. Keep `CLAUDE.md` true to the code as it is today, and list the task for the hand-off.

## 6. Write
Fill in [template.md](template.md). Keep it under 60 lines. Every line describes the code as it is now. Keep a line only if a new engineer would get it wrong without it. Don't restate config or anything one lookup in the code answers, except to name commands.

Show me the draft. Write `CLAUDE.md` at the repo root once I approve.

## 7. Hand off
Report:
- Commands that failed
- Conventions docs to add with `/add-language`
- Linter rules worth turning on
- Where the code differs from a conventions doc
- Questions I couldn't answer, to ask a teammate
- Tasks from my answers, each as a ready `/implement <task>` line, or `/interview-me <idea>` when it needs more decisions

Commit `CLAUDE.md`. From here it stays fresh in three ways. The quality reviewer flags any change that makes a line stale. `/retrospective` adds what agents trip on. Re-running this skill refreshes it after big restructures.
