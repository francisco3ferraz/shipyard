---
name: add-language
description: Research a language or framework and save a conventions doc Shipyard follows.
disable-model-invocation: true
argument-hint: <language or framework> [version]
---

## 1. Scope
Name the language or framework and the version. In a project, read the version from its manifest. Otherwise use the latest stable release. A framework doc builds on its language's doc. Note which one.

If `~/.claude/shipyard/rules/conventions/<name>.md` exists, this is a refresh. Keep its rules that still hold, and keep every line tagged `(lesson)`.

## 2. Research
Use WebSearch and read the pages, never memory alone. Every rule you keep needs a source.

Trust, from most to least:
1. Official docs, style guides and API guidelines, for example PEP 8, Effective Go, the Rust API Guidelines
2. Docs of the official or dominant tools: formatter, linter, type checker, test runner
3. Maintainers and well-known engineering style guides

Prefer sources from the last two years. Mark advice that depends on a version.

## 3. Filter
Keep a rule only if it changes code an agent would write. Then:
- Drop what the formatter or linter enforces. Name the tool and its settings instead.
- `~/.claude/shipyard/rules/CLAUDE.md` wins on conflict. When an official source disagrees with it, keep the core rule and note the conflict.
- Hunt for mistakes agents make in this language, and give the fix for each.

## 4. Write
Save `~/.claude/shipyard/rules/conventions/<name>.md` in this shape. Stay under 150 lines.

```markdown
# <Name> conventions

Applies to: <name> <versions>. Builds on: <language doc, or none>.
Last researched: <YYYY-MM-DD>.

## Tooling
Formatter, linter, type checker and test runner, with the default commands. Project config wins.

## Naming

## Structure
Modules, files, imports, visibility.

## Errors
How to raise, what to catch, how to fail loudly here.

## Testing
Framework, file layout, assertion style, how to fake boundaries.

## Idioms
- Use X, not Y. <one-line why>

## Agent pitfalls
- <mistake agents make> → <what to do instead>

## Sources
- [Title](url), <date read>
```

## 5. Hand off
Summarize the rules that will change code the most. Ask me to review the doc. Once I approve, commit it in the Shipyard repo.
