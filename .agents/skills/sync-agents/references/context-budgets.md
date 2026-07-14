# Agentic context budgets

Operational review thresholds for agent instructions, specs, skills, and
references. They are defaults, not universal standards or success guarantees.
A shorter file can still be poor, and a longer file can be necessary. Quality
is preserved through scoped loading, progressive disclosure, and behavioral
regression tests.

## How to apply the budgets

- Measure lines, estimated tokens, and UTF-8 bytes. Whichever threshold arrives
  first triggers review.
- Use stricter repository limits when they exist.
- Count the effective startup stack after resolving includes and symlinks, not
  merely the visible root file.
- Treat target limits as the green zone. Crossing one requires a concrete reason
  and usually a split, tighter scope, or rewrite.
- Preserve hard behavior with baseline and candidate baits. Never optimize only
  for a smaller count.

## Default envelope

| File or surface                   | Green target                  | Review or split threshold                             |
| --------------------------------- | ----------------------------- | ----------------------------------------------------- |
| Global `AGENTS.md` or `CLAUDE.md` | 120 lines, 1,500 tokens, 6 KB | Any target exceeded                                   |
| Total always-on startup context   | 3,000 tokens                  | 4,000 tokens maximum                                  |
| Repository root `AGENTS.md`       | 150 lines, 2,000 tokens       | Any target exceeded                                   |
| Nested `AGENTS.md`                | 80 lines, 1,000 tokens        | Any target exceeded                                   |
| Always-on rule                    | 60 lines, 1,000 tokens        | Any target exceeded                                   |
| Scoped rule                       | 200 lines, 2,000 tokens       | Any target exceeded                                   |
| `SKILL.md` body                   | 300 lines, 4,000 tokens       | Mandatory quality review at 500 lines or 5,000 tokens |
| Specification phase               | 300 lines, 6,000 tokens       | Split by 500 lines or 10,000 tokens                   |
| Reference file                    | Keep task-focused             | Split near 500 lines or 8,000 tokens                  |

The total always-on budget includes every physical file a tool injects at
startup. Do not count one physical target twice merely because several symlinks
name it, but do flag the duplicate route because a tool may load it twice.

## Skill discovery budget

- Prefer descriptions between 120 and 240 characters.
- Treat 300 characters as the soft maximum for a description.
- Target 6,000 total description characters in the enabled catalog.
- Treat 8,000 catalog characters as the maximum. Disable redundant entries,
  shorten triggers, or narrow discovery before crossing it.
- Description text states what the skill does and when to use it. Workflow
  details belong in `SKILL.md`, not metadata.
- Semantically duplicate skill names or triggers require one clear winner.

Catalog size is preselection cost. It matters even when no skill is invoked.

## Specifications and plans

A single product effort may need far more than 500 lines. Split it by lifecycle
and audience rather than arbitrarily deleting detail:

1. `spec.md`: goals, constraints, acceptance criteria, and non-goals.
2. `plan.md`: architecture, sequence, risks, and verification strategy.
3. `tasks.md`: executable checklist and current status.
4. Subsystem references: detailed contracts, schemas, or research loaded only
   by the phase that needs them.

Keep one phase below 300 lines or 6,000 tokens when practical. At 500 lines or
10,000 tokens, split it unless the document is a cohesive machine-consumed
artifact whose integrity would be harmed.

## Progressive disclosure

- Put universal, high-consequence behavior in the entrypoint.
- Put path-specific rules behind tool-supported scopes.
- Put procedural workflows in skills.
- Put examples, tables, and detailed research one link away in references.
- Add a contents list to a reference over 100 lines.
- Avoid reference chains deeper than one level from `AGENTS.md` or `SKILL.md`.

## Measurement

Use `scripts/count_tokens.py` with an explicit profile when files share a role:

```sh
python scripts/count_tokens.py AGENTS.md --profile root-agents
python scripts/count_tokens.py .agents/rules/behavior.instructions.md --profile always-rule
python scripts/count_tokens.py .agents/skills/example/SKILL.md --profile skill
python scripts/count_tokens.py .agents/skills --catalog
```

Token counts are estimates. Compare candidates with the same tokenizer and
settings, then use the behavior baits to protect success rate.
