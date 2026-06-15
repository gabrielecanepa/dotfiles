---
description: 'Use when building or restyling UI — new interfaces, landing pages, components, redesigns, or any work where visual quality matters. Routes to the right design skill and enforces a production-quality floor. Not for backend/logic, config, or "match existing exactly" tweaks.'
applyTo: '**/*.astro, **/*.css, **/*.html, **/*.jsx, **/*.less, **/*.sass, **/*.scss, **/*.stories.*, **/*.svelte, **/*.tsx, **/*.vue'
paths:
  - '**/*.astro'
  - '**/*.css'
  - '**/*.html'
  - '**/*.jsx'
  - '**/*.less'
  - '**/*.sass'
  - '**/*.scss'
  - '**/*.stories.*'
  - '**/*.svelte'
  - '**/*.tsx'
  - '**/*.vue'
---

# Frontend Design

Engage when the task is **visual**: building new UI, reshaping or restyling existing UI, landing pages, portfolios, marketing sites, components, or design systems. Do **not** engage for pure logic/backend, config, copy-only tweaks, or when the user says "match the existing style exactly" / "don't touch the design".

## Honor the project's system first

If the repo defines a visual system — a `DESIGN.md`, design tokens, a Tailwind/theme config, a component library, or Figma/Storybook source — that system **wins** over any skill's defaults. Read it before designing and derive every choice from it (use the Figma MCP when the source is Figma). Only invent a direction when none exists.

## Pick the skill for the brief

Start from **`frontend-design`** (source: `anthropics/skills`) — the foundation for any new or reshaped UI: direction, typography, anti-templated discipline. Then layer **exactly one** flavor skill from the table below; don't stack conflicting aesthetics. `frontend-design` and `design-taste-frontend` overlap (both fight templated defaults): keep `frontend-design` as the base, and add `design-taste-frontend` only as the default flavor when the brief names no specific aesthetic.

| Context                                                                         | Skill                        |
| ------------------------------------------------------------------------------- | ---------------------------- |
| Default — no specific aesthetic named (landing page, portfolio, app UI)         | `design-taste-frontend`      |
| Premium, calm, "feels expensive" — soft contrast, whitespace, smooth motion     | `high-end-visual-design`     |
| Editorial minimalist — warm monochrome, bento grids, no gradients/heavy shadows | `minimalist-ui`              |
| Brutalist / Swiss-terminal, data-heavy dashboards                               | `industrial-brutalist-ui`    |
| Upgrading an **existing** site (audit-first, preserve behavior)                 | `redesign-existing-projects` |
| You have a mockup/reference to match, or want a design-first pass               | `image-to-code`              |
| Brand identity, logos, guideline boards (image generation, not UI code)         | `brandkit`                   |

`frontend-design` supplies the discipline; the flavor skill supplies the personality. **Tiebreaks:** explicit luxury / calm / "expensive" language → `high-end-visual-design`, otherwise the default `design-taste-frontend`; restrained monochrome / editorial → `minimalist-ui`, raw grid / terminal / high-contrast → `industrial-brutalist-ui`; matching a mockup or screenshot → `image-to-code`; upgrading a live codebase → `redesign-existing-projects` (with a reference image too, redesign wins and uses it as input); an aesthetic not in the table → run `find-skills` before defaulting. When the brief pins a direction, follow it exactly; when it leaves an axis free, don't spend it on a generic default (cream + serif + terracotta, near-black + acid accent, hairline broadsheet).

## Process

Plan before coding: a compact token system — palette (4–6 named hex), 2+ type roles (characterful display used with restraint + body + optional utility), a layout concept, and one **signature element** the page is remembered by. Review the plan against the brief; if any part reads like the default you'd produce for any similar page, revise it and say why. Then build to the plan. Spend boldness in one place and keep everything around it quiet.

## Production-quality floor (enforce regardless of skill)

- Responsive down to mobile; visible keyboard focus; `prefers-reduced-motion` respected.
- Semantic HTML over `div` soup; pass accessibility checks (axe).
- Real content, not lorem; UI copy follows `writing.instructions.md` (active voice, plain verbs, sentence case, no filler).
- **Verify visually** — screenshot via `agent-browser`/Playwright and critique your own work. A passing typecheck is not visual verification (see `engineering.instructions.md`).

## Stack integration

- **shadcn/ui or Tailwind** project → use the `vercel:shadcn` skill for component install, composition, and theming rather than hand-rolling primitives.
- After editing several React/TSX components → run the `vercel:react-best-practices` review (structure, hooks, a11y, performance).
