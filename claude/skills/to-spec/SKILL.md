---
name: to-spec
description: Turn the idea from the interview into a clear, testable spec.
disable-model-invocation: true
argument-hint: [notes path]
---

Write down what we already decided. Do not interview me. If a decision the spec needs is missing, list the missing decisions and stop, so I can run `/interview-me`.

## 1. Gather
Use this conversation, plus the file in the arguments if one was given. Explore the code the work will touch. Note what can be reused and where tests already live.

## 2. Write
Save it to `docs/specs/<slug>/spec.md`, or the project's own spec folder if it has one. Use this template:

```markdown
# <Title>

Status: draft

## Problem
What the user can't do today, from their side.

## Solution
What changes for them, in a few sentences.

## Behaviors
1. When <situation>, then <result>. Example: <concrete input and expected output>.

## Edge cases and errors
- When <bad or unusual situation>, then <exactly what happens and what the user sees>.

## Decisions
Modules touched, interfaces, data changes, reuse, dependencies. No file paths or code.

## Testing
The seams tests go through, what gets mocked and why, and existing tests to copy the style of.

## Out of scope
- <what we chose not to do>
```

Every behavior and edge case must be testable and carry a concrete example. They are the acceptance criteria.

## 3. Hand off
Show me the spec for review. Once I approve, set `Status: approved`.

Then judge its size. If one session can build and verify it all, suggest `/implement <spec path>`. Otherwise suggest `/to-tickets <spec path>`.
