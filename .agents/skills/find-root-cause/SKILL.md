---
name: find-root-cause
description: >-
  Diagnose a bug, crash, regression, or failing test to a proven root cause before any fix. Use for /find-root-cause, broken behavior, errors, or flaky tests; excludes code review, features, design.
---

# find-root-cause

A patch aimed at a symptom moves the bug somewhere else and costs the next person the same investigation.

Nothing gets edited until the cause is stated in one testable sentence and a probe has confirmed it.

The bar: one sentence explains the cause and that sentence accounts for every reported symptom.

A regression test was also watched failing on the broken code and passing on the fixed code, and every site with the same shape was checked and reported.

## Operating contract

Hold these for the whole run.

1. Keep diagnosis read-only until a fix is requested; "why", "look into", "investigate", "diagnose", and "what is wrong" authorize reading and reporting only.
2. Run `git status --short --branch -uall` before anything else and leave the worktree as you found it; `engineering.md` owns the full boundary.
3. List every reported and observed symptom in the user's own words before forming a hypothesis.
4. Put this sentence in the reply before touching code: "The root cause is X because Y." X names a file, function, line, or condition.
5. When more than one hypothesis survives step 3, write three to five of them, each with the observation that would kill it, and put the ranking in the reply.
6. Probe top down, one hypothesis at a time, without waiting for the reporter's re-rank.
7. Check the hypothesis against every symptom; partial coverage means it is a symptom-level guess, and the symptom it cannot explain is the one that matters.
8. Never state a version, path, or symbol from memory: run the command or grep for it, and treat no result as a wrong execution path.

## Instrument before fixing

- Add the log, assertion, or minimal test that would disprove the hypothesis, and read it, before writing any fix.
- Instrumenting is mandatory for lifecycle, event ordering, focus, timer, state machine, async, and concurrency bugs, where static reading rarely settles it.
- The exceptions are pure logic bugs (wrong formula, off by one) and compositor or paint bugs: read the code or the layer tree first.
- When that reading fails on an exception case, instrument it anyway.
- Run the one probe that would fail if the hypothesis were wrong: confirm or discard, never stack.
- When the evidence contradicts the hypothesis, drop the hypothesis whole and re-orient on what the probe showed.
- Never layer a second fix on a disproven explanation.

## Targeted logging

- Write every log as a yes or no question: "if this prints X before Y the hypothesis survives, otherwise it is dead".
- Delete any log that cannot rule a hypothesis in or out, because it is noise.
- Tag every temporary log with one unique prefix such as `[DEBUG-a4f2]`, so removal is a single grep.
- Remove temporary logs before finishing and gate anything permanent behind the project's debug flag.
- When adding a log changes the behavior, treat that as evidence of a timing, lifecycle, or concurrency problem.

## Runtime evidence ladder

Climb until the rung that proves the fix, and say which rung you reached.

1. Source trace: name the exact function, line, state transition, or condition that can produce the symptom.
2. Deterministic repro: run or write the smallest command, fixture, or UI path that produces it.
3. Runtime state: inspect the logs, queues, database rows, caches, temp files, or generated output that prove the path was reached.
4. Narrow test or build: run the targeted test that exercises the fix.
5. Real runtime check: for UI, native, rendering, or generated-artifact bugs, open the thing and verify the visible result.

Follow `browser.md` for anything in a browser. Compile-only is never sufficient above rung 1 for a visual or artifact bug.

When a rung is impossible in this environment, say which one and hand off the exact command, screen, or artifact for the user to check.

### Intermittent symptoms

- Make a timing-dependent symptom (flicker, intermittent failure, race) reproduce reliably before diagnosis, not after.
- Raise the reproduction rate first: loop the trigger, run it in parallel, add load, narrow the timing window.
- A fifty percent failure is debuggable and a one percent failure is not.

### When the reporter's environment is the missing rung

- When it will not reproduce locally, the next artifact is a read-only probe they can paste and run, not another hypothesis.
- Have the probe print the environment, the disputed measurement, and the state the hypothesis turns on.
- Discover their paths and versions rather than assuming yours, and emit nothing that could carry a secret or a private path.
- Two rounds of "could you check whether" without a probe is the shape this replaces.

## Regression bisect

Use when the user says it used to work, names a good commit or version, or reports a break after an upgrade.

- Run `git status --short --branch -uall` first; any modified, staged, or untracked file means no bisect in this checkout.
- Bisect in a temporary detached worktree and remove that worktree when done; when that is impossible, stop and ask for explicit stash approval.
- When the last-good version is only a few releases back, read `git diff <last-good>..HEAD -- <suspect path>` first.
- The regression is usually visible in that diff at a fraction of a bisect's cost.
- Bisect only with a non-interactive pass/fail command defined up front.
- Keep the bookkeeping in `git bisect good/bad` even when testing a suspect commit directly, and read the culprit diff down to the line.
- Run `git bisect reset` before removing the temporary worktree.

## Sibling sweep

Run before declaring the bug done. `engineering.md` requires the sweep; this is how to execute it.

- Extract the pattern signature: the function, regex, API call, selector, lock acquisition, validation skip, or input boundary that produced the bug.
- Run `grep -rn` for it across the repository, excluding generated directories, build output, and vendored dependencies.
- For a class-of-bug pattern such as "any handler missing the lock", grep the surrounding shape rather than the literal text.
- Answer in writing for every match: same bug, safe to leave and why, or unsure and ask.
- Never silently skip a match.
- List unrelated bugs the sweep surfaces instead of fixing them, unless the user agrees.

## Stop conditions

- Same symptom after a fix: the hypothesis is unfinished, so re-read the execution path from scratch instead of adjusting the fix.
- Three failed hypotheses: hard stop, emit the handoff block below, and ask how to proceed; never attempt a fourth.
- The fix needs a refactor first: name the refactor and ask, because a bug fix that grew into a refactor is a separate change.
- The fix touches more than five files: pause and confirm the scope.
- A magic number tuned three times: the bug is structural, so replace the independent values with one named token and find the missing constraint.
- Asymmetry that survives tuning will not converge.
- A workaround growing larger than the feature it supports: the premise is wrong, so change the approach instead of building compensation machinery.

## Regression guard

For any bug that recurred, or that was previously called fixed, the work is not done until all four hold.

1. A regression test exists that fails on the unfixed code and passes on the fixed code.
2. It lives in the project's own suite, not a scratch file.
3. Red and green were run, not assumed: revert or stash the fix, watch the new test fail, restore the fix, watch it pass.
4. Any negative assertion ("output must not contain X") is paired with a positive case in the same test proving the assertion can fail at all.

State the red run in the output, because a test only ever observed passing pins nothing.

Two shapes make step 3 pass silently and both have shipped; [references/failure-modes.md](references/failure-modes.md) names them and how to tell them apart.

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

Close with a status: resolved, resolved with caveats (state them), or blocked (state what is unknown).

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

Status: blocked.

## Bundled resources

- [references/failure-modes.md](references/failure-modes.md): rationalization smells, cause-sentence examples, and the silent-pass test shapes. Load when stuck.
