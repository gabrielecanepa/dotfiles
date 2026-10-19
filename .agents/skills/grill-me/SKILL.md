---
name: grill-me
description: >-
  Interview the user in rounds until a plan, design, or decision has no branch left unexamined, then stop.
  Use only on an explicit /grill-me invocation, never spontaneously.
disable-model-invocation: true
argument-hint: "[the idea, plan, or decision to grill]"
---

# grill-me

Interview the user until the plan, design, or decision holds no silent assumption, then stop. Nothing is written or built.

## Parse the argument

- The argument is the subject; without one, the subject is the first question of round one.
- Treat an existing plan in context, such as a file the user pointed at or an earlier draft, as material to question, never a fixed starting point.

## The design tree

Model the subject as a design tree: each decision branches into the decisions that hang off it. The frontier is every decision whose prerequisites are settled.

1. Compute the frontier.
2. Ask the whole frontier in one round, each question with a recommended answer.
3. Wait for the answers; settled decisions push the frontier outward.
4. Recompute and repeat.

- When a question's answer depends on another question still open, hold it for a later round.
- When a frontier question needs an environment fact (a file, a config value, a dependency version, current behavior), look it up instead of asking.
- While a lookup runs, treat it as an unsettled prerequisite: ask the rest of the frontier now and hold only the questions downstream of it.

## Ask a round

- With a closed-question tool available (AskUserQuestion in Claude Code), deliver the round through it, up to four questions per call.
- When a round needs several calls, issue them in sequence without recomputing the frontier between them.
- Give each question concrete options with the recommended one first, and `multiSelect` when answers are not mutually exclusive.
- Rely on the tool's free-text fallback for the open case.
- Put the reasoning behind the recommendation in the option description, not in chat.
- Without such a tool, print the round as a numbered list: a bold title, the question with its options, and `Recommended:` on the next line. Then stop and wait.
- Hold one decision per question.
- When the user answers "I don't know", record the question as open and move on; it usually needs a prototype or an experiment.

## Steer the scope

- When a round would exceed roughly a dozen questions, propose a split into smaller subjects, grill one, and leave the others for a later invocation.
- When the user pushes back on a question, drop it or sharpen it.

## Stop

- The session is done when the frontier is empty: every branch visited and nothing left silently assumed.
- Close with a compact plain-text summary of the settled and open decisions that the user can paste into a spec, an issue, or /handoff.
- Ask the user to confirm the shared understanding, and act on nothing until they do.
