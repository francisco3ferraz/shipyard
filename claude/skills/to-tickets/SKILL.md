---
name: to-tickets
description: Split a spec into vertical-slice tickets that can each be built and verified alone.
disable-model-invocation: true
argument-hint: <spec path>
---

## 1. Read
Read the spec from the arguments. If it has open questions or missing decisions, list them and stop.

Explore the code the work will touch. Look for prefactoring that would make later tickets simpler.

## 2. Slice
A **slice** is one end-to-end path through every layer it needs, small enough for one session to build test-first and verify.

- Each ticket is a vertical slice that works and can be verified on its own.
- Prefactoring goes first, as its own ticket.
- Each ticket lists only the tickets that truly block it.
- Every spec behavior and edge case lands in exactly one ticket.

If the whole spec is one slice, say so and stop. It can go straight to `/implement`.

## 3. Agree
Show the breakdown as a numbered list: title, blocked by, and what it delivers. Change it until I approve.

## 4. Write
Save each ticket next to the spec as `NN-<slug>.md`, numbered in build order:

```markdown
# NN: <Title>

Spec: [spec.md](spec.md)
Blocked by: None | NN, NN
Status: todo

## Delivers
The behavior that works after this ticket, from the user's side.

## Acceptance
- [ ] Behavior N from the spec, restated with its example
```

Add a `## Tickets` list to the spec linking each one.

## 5. Hand off
Name the first command to run, for example `/implement docs/specs/<slug>/01-<slug>.md`.
