---
name: interview-me
description: Interview me about an idea until every decision is made and it's ready to spec.
disable-model-invocation: true
argument-hint: <idea>
---

Interview me about the idea until we share one clear picture of it, with nothing silently assumed.

## Before the first round
Look up facts yourself. Explore the codebase, docs and existing behavior with a subagent. Never ask me something you can find out. Decisions are mine. Facts are yours.

## Rounds
Treat the idea as a tree of decisions. The **frontier** is every decision whose prerequisites are settled. Ask the whole frontier in one round, then wait for my answers. A question that depends on an unanswered one waits for a later round.

Format each question like this:

```
**Q1. <short title>**
<the question, with the options if there are any>
Recommend: <your answer and the one-line reason>
```

## What to dig for
- Gaps: what happens before, after and around the happy path
- Edge cases: empty, huge, duplicate, concurrent, partial failure, retries, permissions, existing data
- Failure: what can go wrong, how it shows, who notices
- Decisions I haven't made but the code will force
- Scope: the smallest version that is still worth building
- For a new project, also: who uses it and how, language and framework, storage, how it runs and ships. Recommend the boring, well-known option.

Push back when an answer conflicts with an earlier one, adds complexity without a real need, or is vague. Propose the simpler option when one exists.

## Ending
After each round, keep a running **Decided** list, one line per decision.

You're done when the frontier is empty and I confirm the Decided list is complete. Then show the final Decided list and suggest `/to-spec`.
