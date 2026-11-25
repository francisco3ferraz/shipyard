---
name: setup-project
description: Set up the project's CLAUDE.md with the basics, before any other skill runs in a repo.
disable-model-invocation: true
---

A project `CLAUDE.md` loads in every session, so every line costs attention. It holds only what an agent can't find by looking: verified commands, where things live, this codebase's own patterns, and gotchas. This skill writes the basics. The rest is added as the work shows it.

Run it first in any repo, empty or not.

## 1. Look
Read the manifests, scripts, CI config, linter and test config, `README` and the top-level layout. If a `CLAUDE.md` or `AGENTS.md` already exists, this is a refresh. Keep what is still true and cut the rest. Note the top-level folders and what each holds.

If the repo has no code yet, skip to step 3.

## 2. Verify commands and linter
Find the commands for build or typecheck, lint, all tests, one test file, and running locally. Run each one except running locally. Record only the commands that worked. List the ones that failed, with their error.

Check whether the linter flags empty catches, swallowed errors, and skipped or focused tests. List the rules to turn on. Don't change the config.

## 3. Ask me
Ask with the AskUserQuestion tool, as the core rules say:
- Should `CLAUDE.md` and the specs folder be committed, or stay local to this clone? Recommend committed for a personal repo, local for a shared one.
- For an empty repo, what is this project, in one line? Offer your best guess from the folder name and any files.

## 4. Write
Fill in [template.md](template.md). Leave a section empty when nothing is known yet. Every line describes the repo as it is now. Use the project's specs folder if it has one. Otherwise use `docs/specs/`.

Show me the draft. Write `CLAUDE.md` at the repo root once I approve. If I chose local, add `CLAUDE.md` and the specs folder to `.git/info/exclude`, so git ignores them without a tracked change. If either is already tracked, exclude has no effect. Say so, and ask before running `git rm -r --cached` on it. Commit that removal on its own.

Unless I chose local, commit `CLAUDE.md`, then any uncommitted specs in their own commit.

## 5. Hand off
Report:
- Commands that failed
- Linter rules worth turning on
- The next step: `/interview-me <idea>`, or `/implement <task>` when every decision is already made
