# How I want code written

## Asking me
- Whenever you ask me something, use the AskUserQuestion tool. Split a larger round across calls. Put your recommendation first and add "(Recommended)" to its label. When I may pick several, use multiSelect.
- Use plain text only when the answer can't be options, or there are too many to fit.
- Show anything longer than a line or two, like a draft, plan, spec, list or diff, in chat as plain text first. Keep it out of AskUserQuestion and its previews, which cut long content. Ask only the short decision there.

## Before writing code
- Read the code you will change, its callers and its tests. Match their naming, structure, error handling and test style.
- Search for existing helpers and similar logic first. Reuse or extend them. If you write something new that looks reusable, say why the existing code didn't fit.
- If the task has more than one reasonable reading, ask.

## Writing code
- Write and edit code with the editor tools, not shell commands like `sed` or heredocs. The guard hook only sees the editor tools.
- Write the least code that fully solves the task. Use plain functions and direct control flow.
- Add an abstraction (class, interface, wrapper, factory, generic, config option) only when two real callers need it now.
- Keep related logic and data together. One clear place per behavior and per fact. Values that change together, like a reading and its time, live in one type.
- Names use the domain's words and say what a thing is or does. One concept, one name, everywhere.
- Comments say only what the code can't: why, business rules, workarounds, non-obvious constraints. One line when possible. Never narrate the code or restate a signature. A non-obvious rule or workaround always gets its why.

## Errors
- Fail loudly. Let errors propagate unless this exact spot can really handle them.
- Catch only the specific error you expect, and handle it. Never an empty catch, bare except, or catch-log-and-continue.
- Raise on missing or invalid data. Never hide it behind a fallback or default value.
- Trust the types and callers. Skip checks for states they already rule out.

## Tests
- Test each behavior through the public interface of the unit that owns it, so a change in one layer breaks only that layer's tests. A test should fail only when real behavior breaks.
- Mock only real boundaries: network, clock, filesystem, third-party services. Use the real code for everything you own.
- Assert exact expected values. "Not null", "was called" or "didn't throw" alone are not assertions.
- Take expected values from the requirement, never from running the code.
- A few tests on the important behaviors and edge cases beat many shallow ones.
- When a passing test starts failing, fix the code. Change, skip or delete a test only after I agree it's wrong.

## Scope
- Change only what the task needs. Mention other problems instead of fixing them.
- Ask before adding a dependency. Use the standard library and what the project already has.
- Delete code your change made dead. Leave no unused imports, params, files or TODOs.

## Commits
- Commit on your own once the work is verified and reviewed. Never push or publish. I do that.
- Skip review for a change that alters no behavior, like a typo, a reworded sentence or a comment fix. Still verify it.
- Size each commit to review on its own: one logical change with its tests, and the build and tests pass at it.
- Put a prefactor or a mechanical change, like a rename, move or reformat, in its own commit before the behavior change.
- Stage files by name. Leave out unrelated changes and untracked files, and tell me what you left out.
- Never amend, rebase or force anything already pushed.
- Subject: imperative, under 50 characters, no period. Say what changes, like "Add retry to invoice sync".
- Add a body only when the why isn't obvious. One or two short lines.

## Done means verified
- Before saying done: run the build or typecheck, the linter and the relevant tests, then exercise the changed behavior for real.
- Report what you ran and what happened. If you couldn't verify something, say so. Never say "should work".
