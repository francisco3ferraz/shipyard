---
name: setup-project
description: Write or refresh the project's CLAUDE.md from what the repo actually contains.
disable-model-invocation: true
---

A project `CLAUDE.md` loads in every session, so every line costs attention. It holds only what an agent can't find by looking: verified commands, where things live, this codebase's own patterns, and gotchas. Everything else stays in the code and config, where it can't go stale.

## 1. Survey
Read the manifests, scripts, CI config, linter and test config, `README`, `CONTRIBUTING`, the top-level layout and the last 20 commit messages. If a `CLAUDE.md` or `AGENTS.md` already exists, this is a refresh. Keep what is still true and cut the rest.

## 2. Verify the commands
Find the commands for build or typecheck, lint, all tests, one test file, and running locally. Run each one except running locally. Record only the commands that worked. List the ones that failed, with their error.

## 3. Map
Note the folders that matter and what each holds. Find where shared helpers and test fixtures live. Use the project's specs folder if it has one. Otherwise use `docs/specs/`.

## 4. Read the patterns
Read a few typical files and tests. Note only patterns that differ from common defaults or that a newcomer would get wrong: how errors flow, how tests are set up, what gets mocked, naming habits.

List the languages and frameworks in use. Name the ones with no doc in `~/.claude/workflow/conventions/`, so I can run `/add-language`.

Check whether the linter flags empty catches, swallowed errors, and skipped or focused tests. List the rules to turn on. Don't change the config.

## 5. Ask me
Ask one numbered round, with your best guess for each. Ask only what the code can't tell you:
- Gotchas and their reasons
- Areas agents must not touch
- Business rules that aren't obvious from the code
- Mistakes agents have made here before

## 6. Write
Fill in [template.md](template.md). Keep it under 60 lines. Keep a line only if a new engineer would get it wrong without it. Don't restate config, except to name commands.

Show me the draft. Write `CLAUDE.md` at the repo root once I approve.

## 7. Hand off
Report:
- Commands that failed
- Conventions docs to add with `/add-language`
- Linter rules worth turning on

Suggest committing `CLAUDE.md`. When an agent trips on something project-specific later, `/retrospective` adds it here.
