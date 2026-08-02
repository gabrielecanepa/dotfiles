---
name: find-root-cause
description: >-
  Diagnose a bug, crash, regression, or failing test down to a proven root cause before any fix is written. Use for /find-root-cause or reports of broken behavior, errors, or flaky tests; excludes code review, new features, and design questions.
---

# find-root-cause

A patch aimed at a symptom moves the bug somewhere else and costs the next person the same investigation. This skill holds one line: nothing gets edited until the cause is stated in a single testable sentence and a probe has confirmed it.

The bar to hold: when this finishes, one sentence explains the cause, that sentence accounts for every reported symptom, a regression test has been watched failing on the broken code and passing on the fixed code, and every other site with the same shape has been checked and reported.

## Operating contract

Hold these for the whole run.

- **Diagnosis is read-only until the user asks for a fix.** "Why", "look into", "investigate", "diagnose", and "what is wrong" authorize reading and reporting only. `engineering.instructions.md` owns the full boundary: check `git status --short --branch -uall` before anything else and leave the worktree as you found it.
- **State the cause before touching code.** Fill in this sentence and put it in the reply: "The root cause is X because Y." X names a file, function, line, or condition. "A state management issue" is not testable. "`useUser` at `src/hooks/user.ts:42` reads a stale cache because `userId` is missing from the dependency array" is testable. If you cannot be that specific you do not have a hypothesis, you have a guess.
- **The hypothesis must explain every symptom.** Partial coverage means it is a symptom-level guess. List each reported and observed symptom in the user's own words first, then check the hypothesis against all of them. A symptom the hypothesis cannot explain is the one that matters.
- **Instrument before fixing, not after the fix fails.** Add the log, assertion, or minimal test that would disprove the hypothesis, and read it, before writing any fix. This is mandatory for lifecycle, event ordering, focus, timer, state machine, async, and concurrency bugs, where static reading almost never settles the question. Pure logic bugs (wrong formula, off by one) and compositor or paint bugs are the exceptions: read the code or the layer tree first, and instrument only if that fails.
- **Confirm or discard, never stack.** Run the one probe that would fail if the hypothesis were wrong. If the evidence contradicts it, drop the hypothesis whole and re-orient on what the probe showed. Never layer a second fix on a disproven explanation.
- **Never state a version, path, or symbol from memory.** Run the command or grep for it. No result means the execution path is wrong, not that the tool is broken.

## Rationalization smells

Each of these means stop and do the thing on the right.

| Thought                             | What it actually means                                                  |
| ----------------------------------- | ----------------------------------------------------------------------- |
| "Let me just try this"              | There is no hypothesis yet. Write it down first.                        |
| "I'm confident it's X"              | Run the instrument that proves X.                                       |
| "Probably the same issue as before" | Re-read the execution path from scratch.                                |
| "It works on my machine"            | Enumerate the environment differences before dismissing.                |
| "One more restart and it'll clear"  | Read the last error verbatim. Never restart twice without new evidence. |
| "The build passes, so it's fixed"   | Compile-only proves nothing about runtime. Climb the ladder.            |
| "That part doesn't matter"          | The area being skipped is where these bugs live. Check it.              |

## Runtime evidence ladder

Climb until the rung that proves the fix, and say which rung you reached.

1. **Source trace.** Name the exact function, line, state transition, or condition that can produce the symptom.
2. **Deterministic repro.** Run or write the smallest command, fixture, or UI path that produces it. Timing-dependent symptoms (flicker, intermittent failure, race) must reproduce reliably before diagnosis, not after.
3. **Runtime state.** Inspect what proves the path was reached: logs, queues, database rows, caches, temp files, generated output.
4. **Narrow test or build.** Run the targeted test that exercises the fix.
5. **Real runtime check.** For UI, native, rendering, or generated-artifact bugs, open the thing and verify the visible result. Follow `browser.instructions.md` for anything in a browser.

Compile-only is never sufficient above rung 1 for a visual or artifact bug. If a rung is impossible in this environment, say which one and hand off the exact command, screen, or artifact for the user to check.

When the reporter's environment is the missing rung and it will not reproduce locally, the next artifact is a read-only probe they can paste and run, not another hypothesis. Have it print the environment, the disputed measurement, and the state the hypothesis turns on. Discover their paths and versions rather than assuming yours, and emit nothing that could carry a secret or a private path. Two rounds of "could you check whether" without a probe is the shape this replaces.

## Targeted logging

Every log is a yes or no question: "if this prints X before Y the hypothesis survives, otherwise it is dead." A log that cannot rule a hypothesis in or out is noise, so delete it. Remove temporary logs before finishing and gate anything permanent behind the project's debug flag. If adding a log changes the behavior, that is itself evidence of a timing, lifecycle, or concurrency problem.

## Regression bisect

Use when the user says it used to work, names a good commit or version, or reports a break after an upgrade.

- Protect the worktree first. `git status --short --branch -uall`; any modified, staged, or untracked file means no bisect in this checkout. Run it in a temporary detached worktree and remove that worktree when done. If that is impossible, stop and ask for explicit stash approval.
- If the last-good version is only a few releases back, read `git diff <last-good>..HEAD -- <suspect path>` first. The regression is usually visible there at a fraction of a bisect's cost.
- Bisect only with a non-interactive pass/fail command defined up front. Keep the bookkeeping in `git bisect good/bad` even when testing a suspect commit directly, read only the culprit diff down to the line, and run `git bisect reset` before removing the temporary worktree.

## Sibling sweep

Run before declaring the bug done. `engineering.instructions.md` requires the sweep; this is how to execute it.

Extract the pattern signature: the specific function, regex, API call, selector, lock acquisition, validation skip, or input boundary that produced the bug. `grep -rn` it across the repository, excluding generated directories, build output, and vendored dependencies. For a class-of-bug pattern ("any handler missing the lock"), grep the surrounding shape rather than the literal text.

Answer in writing for every match: same bug, safe to leave and why, or unsure and ask. Never silently skip a match. Unrelated bugs the sweep surfaces get listed, not fixed, unless the user agrees.

## Stop conditions

- **Same symptom after a fix.** The hypothesis is unfinished. Re-read the execution path from scratch instead of adjusting the fix.
- **Three failed hypotheses.** Hard stop. Emit the handoff block below and ask how to proceed. Do not attempt a fourth.
- **The fix needs a refactor first.** Name the refactor and ask. A bug fix that grew into a refactor is a separate change.
- **The fix touches more than five files.** Pause and confirm the scope.
- **A magic number has been tuned three times.** The bug is structural, not numeric. Replace the independent values with one named token and look for the missing constraint. Asymmetry that survives tuning will not converge.
- **A workaround is growing larger than the feature it supports.** The premise is wrong. Change the approach instead of building compensation machinery.

## Regression guard

For any bug that recurred, or that was previously called fixed, the work is not done until all four hold.

1. A regression test exists that fails on the unfixed code and passes on the fixed code.
2. It lives in the project's own suite, not a scratch file.
3. Red and green were **run**, not assumed. Revert or stash the fix, watch the new test fail, restore the fix, watch it pass. A test only ever observed passing pins nothing. State the red run in the output.
4. Any negative assertion ("output must not contain X") is paired with a positive case in the same test proving the assertion can fail at all.

Two shapes make step 3 pass silently and both have shipped: a framework where a failing assertion mid-test does not fail the test, so only the last one gates; and an assertion that a string is absent which was never emitted under any version of the code. Confirm which by running a two-line minimal repro, not by reasoning about the framework.

## Output

Open with one plain line stating the outcome and whether anything was changed, then this block.

```text
Root cause:       what was wrong, file:line
Fix:              what changed, file:line, or none (diagnosis only)
Evidence:         ladder rung reached and the probe that confirmed it
Sibling sweep:    N sites checked, N fixed, N left safe, or not run and why
Tests:            pass/fail counts and the commands that produced them
Regression guard: test file:line and the red run, or none and why
```

Close with a status: **resolved**, **resolved with caveats** (state them), or **blocked** (state what is unknown).

### Handoff after three failed hypotheses

```text
Symptom:          one sentence, the original report

Hypotheses tested:
1. hypothesis -> how it was tested -> ruled out because
2. hypothesis -> how it was tested -> ruled out because
3. hypothesis -> how it was tested -> ruled out because

Evidence:         logs, stack traces, repro steps, versions, config
Ruled out:        causes eliminated and what eliminated them
Unknown:          what is still unclear and what information is missing
Next:             investigation directions, access or tools needed
```

Status: **blocked**.
