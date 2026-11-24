# Shipyard

A Claude Code workflow: skills, two reviewer subagents, hooks and core rules that push agents toward simple, reused, verified code. This file is for working on Shipyard itself. `rules/CLAUDE.md` holds the rules Shipyard ships to every project.

## Commands
- Hook tests on Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File hooks/test.ps1`
- Hook tests on Linux, from Git Bash through WSL: `MSYS_NO_PATHCONV=1 wsl.exe -d Ubuntu --cd "<repo path under /mnt/c>" --exec bash hooks/test.sh`
- Try an installer without touching the real config: pass a temp dir, `install/install.ps1 -ClaudeDir <dir>` or `install/install.sh <dir>`. Run it twice to check re-runs. On Windows, remove the temp junctions with `cmd /c rmdir` before deleting the dir.

## Where things live
- The repo root is what gets installed. `~/.claude/shipyard` links here.
- `rules/CLAUDE.md`: the core rules every session loads.
- `skills/<name>/SKILL.md`: one folder per skill. `agents/`: `spec-reviewer` and `quality-reviewer`, run in parallel by `review`.
- `hooks/`: `*.patterns` hold the rules and `*.cases.json` the tests. The `.ps1` and `.sh` files are thin runners per OS.
- `install/permissions.json`: `ask` and `deny` rules both installers add.
- `rules/conventions/`: per-language docs written by `/add-language`. They are the user's content.
- `README.md` explains what and why. `docs/GUIDE.md` explains how to use it. Both document a personal setup: proper docs in a neutral voice, no first person, no selling.

## Conventions
- Write skills the way the core rules ask for code: short, plain, concrete. Steps in order, each with a clear finish line. Say what to do, not what to avoid.
- Each fact lives in one place. Skills point to `rules/CLAUDE.md` instead of repeating its rules.
- Only `review` and `retrospective` are model-invoked. Every other skill sets `disable-model-invocation: true`, so it costs no context.
- Windows and Linux stay equal. A hook rule goes in `*.patterns` with a blocked and an allowed case in `*.cases.json`, then both test runners must pass. An installer change goes in both installers.
- Installers stay safe to re-run, back up before writing, and never overwrite a path that isn't their own link.
- When a skill is added, renamed or changes behavior, update every table and list that names it in `README.md` and `docs/GUIDE.md` in the same change.
- Use the skill names as written: `interview-me`, `to-spec`, `to-tickets`, `implement`, `review`, `retrospective`, `add-language`, `setup-project`.

## Gotchas
- Edits to `rules/`, `skills/`, `agents/` and `hooks/` are live at once in every Claude Code session on this machine, because of the links. A broken hook or rule hits all of them.
- The `no-push` hook blocks any shell command whose text mentions pushing, even inside a heredoc. Write such files with the editor tools.
- The guard hook skips `*.patterns` and `*.cases.json` on purpose, since they hold the very code it blocks.
- New skill folders only appear after re-running the installer. Edits to existing ones don't need it.
- Plan mode is denied in the user's settings. Plans stop in chat.
