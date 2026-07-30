---
description: 'Use when building or restyling UI: interfaces, landing pages, components, redesigns, or other visual work. Enforces project-system precedence, deliberate direction, layout discipline, accessibility, and real-browser verification.'
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

Engage for visual construction or restyling. Do not engage for backend logic, configuration, copy-only edits, or exact-style matching.

## Honor the project's system first

If the repository defines a visual system through design documentation, tokens, themes, a component library, Figma, or Storybook, it wins. Read the source first and use the configured Figma integration when relevant. Only invent a direction when none exists. If the brief belongs to an established product family, use its official system. Choose one system rather than importing one and overriding most of it.

## Visual direction

When no project system exists, load `~/.agents/references/design-aesthetics.md`, choose one coherent direction, and state it before coding. Do not load that reference for exact-style matching or non-visual work.

## Layout and rhythm caps

- Hero: headline 2 lines max; subtext 20 words and 4 lines max; at most 4 text elements (eyebrow or brand strip, headline, subtext, 1-2 CTAs); top padding `pt-24` max on desktop; nav 64-72px (80px hard cap). Trust logos, pricing, and feature bullets live below the hero, never inside it. The first viewport must read cleanly on a small laptop: one focal point, visible CTA, no crowding.
- Headline scale: `text-4xl md:text-5xl lg:text-6xl` default; `text-6xl md:text-7xl` only for 3-5 word headlines.
- Eyebrows: max 1 per 3 sections (hero counts); spec: `rounded-full px-3 py-1 text-[10px] uppercase tracking-[0.2em]`.
- A layout family (3-col cards, split text/image, bento) appears at most once per page; zigzag splits cap at 2 consecutive sections; bento grids have exactly as many cells as content items.
- No cards inside cards inside cards; no giant rounded wrapper around a whole section.
- CTAs: 1-3 words on one line; one label per intent site-wide (never both "Contact us" and "Let's talk").
- Lists over 5 items: card grid, grouped chunks, or scroll-snap pills, never a `divide-y` hairline per row.
- Paragraph measure ~65ch; container max-width 1200-1440px; messy real data (47.2%, not 50%).
- Icons: one library with a global `strokeWidth` (1.5 or 2); prefer Phosphor, HugeIcons, Radix Icons, or Tabler over `lucide-react`; never hand-roll SVG icon paths.

## Process

Plan before coding: a compact token system, palette (4 to 6 named hex), 2+ type roles (characterful display used with restraint + body + optional utility), a layout concept, and one **signature element** the page is remembered by. Review the plan against the brief; if any part reads like the default you'd produce for any similar page, revise it and say why. Then build to the plan. Spend boldness in one place and keep everything around it quiet, and before shipping remove one accessory (the Chanel rule) as the last restraint pass.

## UI copy

Follows `writing.instructions.md` (active voice, plain verbs, sentence case, no filler). Name controls by what users manage, never system internals (a person manages notifications, not webhook config). An action's name persists through its flow (button "Publish" → toast "Published"). Errors state what happened and the next step, never a vague apology. Empty states invite an action. Real content, not lorem.

## Redesigns (audit first)

- Scan the stack and current patterns, diagnose against the caps above, fix surgically (never rewrite wholesale), test after each change.
- Fix in this order: font swap → color cleanup → hover/active states → layout and spacing → replace generic components → loading/empty/error states → typography polish.
- Check the strategic omissions: legal links, back navigation, custom 404, skip-to-content, cookie consent, client-side form validation.
- Optical alignment over math: bottom-align CTAs across card groups, align feature-list start Y across columns, nudge icon and text centering 1-2px by eye.
- Never silently change URL slugs, nav labels, form field names, the logo, or legal copy.

## Images and brand marks

- Prefer user-provided or project-owned assets, then generated imagery when appropriate, then a licensed source with provenance. Use an explicit labeled placeholder when no real asset is available. Never build fake screenshots from generic divs.
- Use official brand assets or an installed, versioned icon package. Do not approximate a logo or depend on a remote icon CDN in production.
- Logo and brand ideation: pick 1 method, max 2 combined (monogram with meaning, product-action symbol, metaphor fusion, negative-space mark, construction geometry); ground the mark in category symbol logic (dev tool: cursor, frame, bolt; security: shield, eye, seal; luxury: monogram, seal, vessel). Tagline under 6 words, no corporate slogan filler.

## Production-quality floor (enforce regardless of direction)

- Responsive down to mobile; visible keyboard focus; `prefers-reduced-motion` respected.
- **Animate compositor properties only**: `transform` and `opacity` (GPU, no reflow). Never animate `width`/`height`/`top`/`left`/`margin`; those hit layout every frame. When measuring the DOM imperatively, batch reads before writes so a read-write-read pattern can't force synchronous reflows.
- Semantic HTML over `div` soup; pass accessibility checks (axe).
- Watch type-selector vs element-selector rules canceling each other on section padding and margin (silent specificity bugs).
- **Verify visually**: screenshot via `agent-browser`/Playwright and critique your own work, reusing the already-running dev server and Chrome window (verification and reuse rules in `engineering.instructions.md`).

## Stack integration

- **Animation or motion work** → `motion.instructions.md` owns the animation layer: easing and duration values, springs, review-skill routing, and timing tokens.
- **shadcn/ui or Tailwind** project → use a project-configured shadcn skill or MCP when available. Otherwise verify current shadcn and Tailwind guidance through Context7 before installing or composing primitives.
- **Canonical Tailwind classes, never hardcoded arbitrary values.** When a value maps exactly to a scale token, write the token, not the bracket form: `gap-3.5` not `gap-[14px]`, `p-0.5` not `p-[2px]`. Only reach for an arbitrary value (`gap-[13px]`) when the design system has no exact token for it. This is what the Tailwind VS Code plugin (`suggestCanonicalClasses`) and the oxlint `enforce-canonical` rule flag; resolve those hints against the project's own `--spacing` scale, don't assume `1rem = 16px`.
- After editing several React/TSX components → run the `vercel-react-best-practices` review (structure, hooks, a11y, performance).
