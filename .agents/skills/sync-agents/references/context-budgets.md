# Agentic context budgets

Review thresholds for agent instructions, skills, references, and specs. A stricter repository budget wins.

A file inside the envelope can still be poor. The behavioral baits decide whether a rewrite holds, not the counts.

## How to apply

- Measure estimated tokens with `scripts/count_tokens.py`; the lines and bytes it reports are informational.
- Scripts, inline `!` script commands, and generated `BEGIN:`/`END:` comment blocks such as `nextjs-agent-rules` are never measured; the script skips them.
- The script infers each file's role from its path and frontmatter; pass `--role` to override it.
- Write to the target; the cap is the failure line, never the goal. Run `--strict` after a rewrite: it fails above target and is the acceptance gate.
- Count the effective startup stack after resolving includes and symlinks, memory index included; count each physical file once.
- Write markdown unwrapped: one paragraph or list item per physical line. Hard column wrapping is a finding.
- Crossing a cap needs a concrete reason and usually a split, a tighter scope, or a move to a reference.
- Keep hard behavior with baseline and candidate baits. Never optimize only for a smaller count.

## Envelope

Values are estimated tokens unless the row says otherwise.

| Surface                                            | Target | Cap   |
| -------------------------------------------------- | ------ | ----- |
| Global entrypoint (`~/.agents/AGENTS.md`)          | 800    | 1200  |
| Always-on rule                                     | 600    | 1000  |
| Always-on rules per tool (count)                   | 2      | 3     |
| Always-on total, memory index included             | 2500   | 3500  |
| Standing directives in the always-on stack (count) | 60     | 90    |
| Scoped rule                                        | 1200   | 2000  |
| Reference                                          | 3000   | 6000  |
| `SKILL.md` body                                    | 2500   | 4000  |
| Agent, command, or output-style definition         | 600    | 1000  |
| Claude memory index (`MEMORY.md`)                  | 500    | 800   |
| Repository root `AGENTS.md`                        | 1200   | 2000  |
| Nested `AGENTS.md`                                 | 500    | 1000  |
| Specification phase                                | 6000   | 10000 |
| Line length (characters)                           | 160    | 220   |
| Sentences per list item (count)                    | 2      | 3     |
| List items per section (count)                     | 8      | 12    |

The line rows are the ones that raise adherence; the token rows keep them honest.

One directive per line is the rule the line rows approximate. No script can count it, so the reviewer checks it by reading.

## Skill discovery

- Keep a description between 120 and 200 characters; 250 is the cap.
- Keep the enabled catalog under 5000 description characters; 6500 is the cap.
- A description states what the skill does and when to use it. Workflow detail belongs in the body.
- Duplicate skill names or triggers need one clear winner.
- Claude Code truncates each listing entry at 1,536 characters and the Agent Skills spec caps `description` at 1,024.
- `disable-model-invocation: true` keeps a description out of the catalog, so manual-only workflows cost no discovery budget.

Catalog size is preselection cost. It matters even when no skill is invoked.

## Specifications and plans

Split a large effort by lifecycle and audience instead of deleting detail:

1. `spec.md`: goals, constraints, acceptance criteria, and non-goals.
2. `plan.md`: architecture, sequence, risks, and verification strategy.
3. `tasks.md`: executable checklist and current status.
4. Subsystem references: contracts, schemas, or research loaded only by the phase that needs them.

Keep one phase under 6000 tokens. At 10000, split it unless it is a cohesive machine-consumed artifact whose integrity a split would harm.

## Compaction survival

- The project-root entrypoint is re-injected in full after compaction.
- Path-scoped rules and nested entrypoints are not re-injected; they reload on the next matching file read.
- Invoked skills are re-attached most recent first, 5,000 tokens per skill under a 25,000-token shared budget. Older skills can drop.
