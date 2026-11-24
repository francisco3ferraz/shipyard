---
name: implement
description: Build a spec, ticket or prompt test-first, verify it, then review it.
disable-model-invocation: true
argument-hint: <spec or ticket path | task>
---

## 1. Load
Read the spec or ticket from the arguments. For a ticket, also read its spec and check that every ticket blocking it has `Status: done`. If the argument is a plain task, that text is the spec.

Read the project `CLAUDE.md`.

## 2. Explore
Read the code you will change, its callers and its tests. Find the helpers you will reuse.

## 3. Plan
Write a short plan:
- Behaviors to build, in order, each with the seam its test goes through
- What you will reuse, by name and path
- Anything new, and why existing code doesn't cover it
- How you will verify it for real

Stop for my approval when the input is a plain task, or the plan adds anything the spec didn't decide, like a new module, a dependency or a different seam. Otherwise show the plan and continue.

## 4. Build test-first
For each behavior in order:

1. **Red.** Write one test for this behavior through its seam, before any code for it. Take the expected value from the spec's example. Run it. It must fail on the assertion, not on a typo or import. Show me the failing assertion output before you write code.
2. **Green.** Write the simplest code that passes. Run the test, then the tests near it.
3. **Refactor.** With everything green, clean the code you just wrote: names, duplication with existing helpers, dead code, comments. Run the tests again.

Once a test has passed, it is frozen. If it later fails, fix the code. If you believe the test is wrong, stop and tell me why.

## 5. Verify
Run the full test suite, the typecheck or build and the linter. Then exercise the change for real: run the command, call the endpoint or load the page. Fix the code until all of it passes.

## 6. Review
Call the Skill tool with `review`, passing the spec or ticket path, or the task text. Fix every **must fix**. Fix each **should fix** unless it grows the scope, and list the ones you leave. After fixes, repeat step 5.

Stop after two review rounds and report what is left.

## 7. Close
For a ticket, tick its acceptance boxes and set `Status: done`.

Commit the work, following the commit rules in the core rules.

Report:
- The commits, each with its subject and what it holds
- Each behavior with the failing assertion output from its red step
- Commands you ran and their results
- Anything you could not verify
- Problems you noticed but left alone

I review the commits and push.
