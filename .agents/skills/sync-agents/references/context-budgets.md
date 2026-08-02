# Agentic context budgets

Operational review thresholds for agent instructions, specs, skills, and references. They are defaults, not universal standards or success guarantees. A shorter file can still be poor, and a longer file can be necessary. Quality is preserved through scoped loading, progressive disclosure, and behavioral regression tests.

## How to apply the budgets

- Budgets are token counts, nothing else. Measure estimated tokens with `scripts/count_tokens.py`; the lines and bytes it reports are informational context, never review triggers.
- Write markdown prose unwrapped: one paragraph or list item per physical line, soft-wrapped by the editor. Hard column wrapping is a finding; it costs extra tokens and hides phrases from line-oriented search. This covers documents only: scripts and their comments are never measured against these budgets and keep the language's own wrapping conventions.
- Use stricter repository limits when they exist.
- Count the effective startup stack after resolving includes and symlinks, not merely the visible root file.
- Treat target limits as the green zone. Crossing one requires a concrete reason and usually a split, tighter scope, or rewrite.
- Preserve hard behavior with baseline and candidate baits. Never optimize only for a smaller count.

## Default envelope

| File or surface                   | Green target      | Review or split threshold                |
| --------------------------------- | ----------------- | ---------------------------------------- |
| Global `AGENTS.md` or `CLAUDE.md` | 1,500 tokens      | Target exceeded                          |
| Total always-on startup context   | 3,000 tokens      | 4,000 tokens maximum                     |
| Repository root `AGENTS.md`       | 2,000 tokens      | Target exceeded                          |
| Nested `AGENTS.md`                | 1,000 tokens      | Target exceeded                          |
| Always-on rule                    | 1,000 tokens      | Target exceeded                          |
| Scoped rule                       | 2,000 tokens      | Target exceeded                          |
| `SKILL.md` body                   | 4,000 tokens      | Mandatory quality review at 5,000 tokens |
| Specification phase               | 6,000 tokens      | Split by 10,000 tokens                   |
| Reference file                    | Keep task-focused | Split near 8,000 tokens                  |

The total always-on budget includes every physical file a tool injects at startup. Do not count one physical target twice merely because several symlinks name it, but do flag the duplicate route because a tool may load it twice.

## Skill discovery budget

- Prefer descriptions between 120 and 240 characters.
- Treat 300 characters as the soft maximum for a description.
- Target 6,000 total description characters in the enabled catalog.
- Treat 8,000 catalog characters as the maximum. Disable redundant entries, shorten triggers, or narrow discovery before crossing it.
- Description text states what the skill does and when to use it. Workflow details belong in `SKILL.md`, not metadata.
- Semantically duplicate skill names or triggers require one clear winner.

Catalog size is preselection cost. It matters even when no skill is invoked.

## Specifications and plans

A single product effort may need far more than one phase budget. Split it by lifecycle and audience rather than arbitrarily deleting detail:

1. `spec.md`: goals, constraints, acceptance criteria, and non-goals.
2. `plan.md`: architecture, sequence, risks, and verification strategy.
3. `tasks.md`: executable checklist and current status.
4. Subsystem references: detailed contracts, schemas, or research loaded only by the phase that needs them.

Keep one phase below 6,000 tokens when practical. At 10,000 tokens, split it unless the document is a cohesive machine-consumed artifact whose integrity would be harmed.

## Progressive disclosure

- Put universal, high-consequence behavior in the entrypoint.
- Put path-specific rules behind tool-supported scopes.
- Put procedural workflows in skills.
- Put examples, tables, and detailed research one link away in references.
- Add a contents list to a reference over 1,500 tokens.
- Avoid reference chains deeper than one level from `AGENTS.md` or `SKILL.md`.

## Measurement

Use `scripts/count_tokens.py` with an explicit profile when files share a role:

```sh
python scripts/count_tokens.py AGENTS.md --profile root-agents
python scripts/count_tokens.py .agents/rules/behavior.instructions.md --profile always-rule
python scripts/count_tokens.py .agents/skills/example/SKILL.md --profile skill
python scripts/count_tokens.py .agents/skills --catalog
```

Token counts are estimates. Compare candidates with the same tokenizer and settings, then use the behavior baits to protect success rate.
