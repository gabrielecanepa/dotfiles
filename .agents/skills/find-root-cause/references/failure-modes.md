# Diagnosis failure modes

Worked examples for the find-root-cause skill. Load when a hypothesis feels stuck or a regression test passes too easily.

## Rationalization smells

Each thought below means stop and do the thing on the right.

| Thought                             | What it actually means                                                  |
| ----------------------------------- | ----------------------------------------------------------------------- |
| "Let me just try this"              | There is no hypothesis yet. Write it down first.                        |
| "I'm confident it's X"              | Run the instrument that proves X.                                       |
| "Probably the same issue as before" | Re-read the execution path from scratch.                                |
| "It works on my machine"            | Enumerate the environment differences before dismissing.                |
| "One more restart and it'll clear"  | Read the last error verbatim. Never restart twice without new evidence. |
| "The build passes, so it's fixed"   | Compile-only proves nothing about runtime. Climb the ladder.            |
| "That part doesn't matter"          | The area being skipped is where these bugs live. Check it.              |

## Stating the cause

The sentence is "The root cause is X because Y", where X names a file, function, line, or condition.

Not testable: "a state management issue". It names no file, no line, and no condition, so no probe can fail against it.

Testable: "`useUser` at `src/hooks/user.ts:42` reads a stale cache because `userId` is missing from the dependency array".

When you cannot be that specific, you do not have a hypothesis, you have a guess.

## Why the ranking exists

A single hypothesis anchors the whole investigation on the first plausible idea.

The reporter often re-ranks from what they already know, which is why the ranking goes in the reply rather than staying in your head.

Probing top down while the re-rank is outstanding costs nothing, so never wait for it.

## Two shapes that make a red run pass silently

Both of these have shipped as false green, so confirm which one applies by running a two-line minimal repro rather than reasoning about the framework.

- A framework where a failing assertion mid-test does not fail the test, so only the last assertion actually gates the result.
- An assertion that a string is absent, where that string was never emitted under any version of the code, so the test cannot fail.
