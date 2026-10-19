---
name: questions-for
description: >-
  Turn a decision the user cannot settle alone into a markdown questionnaire for the person who holds the missing knowledge.
  Use only on an explicit /questions-for invocation, never spontaneously.
disable-model-invocation: true
argument-hint: "[recipient] [about <topic>] [in <dir>]"
---

# questions-for

Produce a markdown questionnaire the user hands to one person, to fill in asynchronously or to walk through in a meeting.

## Parse the argument

- Treat the argument as literal text.
- When a trailing `in <dir>` token starts with `~`, `/`, `.`, or `$`, or contains a `/`, it names the destination directory.
- Without a destination, write in the current directory.
- Of the rest, text before `about` names the recipient and text after it the topic; without `about`, the whole rest names the recipient.
- Without a topic, use the decision under discussion in the current context; without one there either, ask for it in the first exchange.

## Grill the send, not the subject

Interview the user only about the send, in two exchanges, through the closed-question tool (AskUserQuestion in Claude Code) or a short numbered list.

1. Who it goes to: role, expertise, and relationship to the user. Done when it is clear what the recipient knows that the user does not.
2. What the user needs back: the decisions or facts they cannot resolve alone. Done when there is a concrete list of what the answers must let the user decide.

- When the argument already names the recipient, skip the first exchange and ask only what is still missing.
- Never ask the user or the recipient for a fact the agent can look up, such as what the code or config does today.

## Write the questionnaire

- Frame it as discovery: the user lacks context and the recipient holds it.
- Aim every question at the gap between what the recipient knows and what the user needs, covering every item from the second exchange.
- Order questions most important first, because an asynchronous send may get one pass.
- Group questions under `##` headings by theme once there are more than a handful.

### Each question

- Hold one idea per question, never compound.
- Put an answer stub directly beneath each question: an empty blockquote line the recipient types into.
- Add a one-line "Why this matters" only where the question could be misread or invite a throwaway answer.
- Write in the recipient's domain language, never the codebase's.

### Structure

```markdown
# <Title>

Purpose: why this questionnaire exists and the decision riding on it.

From: <the user>. To: <the recipient>. How the answers will be used: <where they go>.

## Context

One paragraph orienting a recipient who was not in the user's head. Enough to answer well, not a page.

## How to answer

Deadline and rough effort. Partial answers and "I don't know" are useful; flag anything uncertain rather than skipping it.

## <Theme>

### <Question>

Why this matters: <one line, only where needed>.

>

## Anything else?

Anything we did not ask that we should know?
```

### Final checks

- Write the whole document unwrapped, with no em or en dash.
- Never include a secret or an internal path the recipient should not see.
- Fill `Purpose`, `From`, `To`, and the deadline only from values known in the session; leave the rest for the user.

## Emit

1. Write the file as `questions-for-<slug>.md`, slug from the topic, in the destination.
2. When that file exists, insert a numeric suffix before `.md` instead of overwriting.
3. Reply with only the `~`-relative path written.
