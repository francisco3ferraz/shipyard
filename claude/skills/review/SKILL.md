---
name: review
description: Review a change against its spec, ticket or prompt, and against code quality rules. Use after implementing, or when asked to review a diff, branch or PR.
argument-hint: [spec or ticket path] [base ref]
---

## 1. Pin the diff
Use the base ref from the arguments if given, with `git diff <base>...HEAD`. Otherwise, if there are uncommitted changes, use `git diff HEAD` plus untracked files from `git status`. Otherwise use `git diff main...HEAD`. Stop if the diff is empty.

## 2. Find the intent
Take the first that exists:
1. A spec or ticket path from the arguments
2. A spec under `docs/specs/` matching the branch name
3. The prompt in this conversation that asked for the change, quoted word for word

If none exists, ask me what the change was for.

## 3. Find the standards
- `~/.claude/shipyard/CLAUDE.md`
- The project `CLAUDE.md` and any coding standards doc it points to
- `~/.claude/shipyard/conventions/<name>.md` for each language and framework in the diff, if it exists

## 4. Run both reviewers
Spawn both subagents in one message, so they run in parallel:
- `spec-reviewer`, with the diff command and the intent path or quoted text
- `quality-reviewer`, with the diff command and the list of standards files

Pass each only its own inputs. Each judges the change with fresh eyes, and keeping them apart stops one axis from hiding the other.

## 5. Report
Show their findings as they returned them, under **Spec**, **Quality** and **Could delete**. Don't merge or re-rank across axes.

If I called this skill directly, ask which findings to fix. If another skill called it, hand the findings back.
