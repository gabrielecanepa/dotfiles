---
description: 'Use when building or restyling UI: new interfaces, landing pages, components, redesigns, or any work where visual quality matters. Carries the design discipline and the aesthetic flavors inline and enforces a production-quality floor. Not for backend/logic, config, or "match existing exactly" tweaks.'
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

If the repo defines a visual system (a `DESIGN.md`, design tokens, a Tailwind/theme config, a component library, or Figma/Storybook source), that system **wins** over every default below. Read it before designing and derive every choice from it (use the Figma MCP when the source is Figma). Only invent a direction when none exists. When the brief implies an established product family, adopt its official system instead of inventing: Fluent (Microsoft-style enterprise), Material Web (Google-adjacent), Carbon (IBM-style B2B), Polaris (Shopify), Atlaskit (Atlassian), Primer (GitHub-style), govuk-frontend / uswds (public sector), Radix Themes / shadcn (modern SaaS). One system per project; never import a system's tokens and override most of them.

## Avoid the AI-default fingerprints

Never default into these; use one only when the brief names it:

- Warm cream (#F4F1EA family) + high-contrast serif + terracotta accent, and the wider beige-and-brass premium-consumer palette (backgrounds #f5f1ea / #efeae0 / #ece6db, accents #b08947 / #b6553a / #9a2436, espresso text #1a1714) for cookware, wellness, artisan, or luxury briefs. Rotate instead: cold luxury (silver, chrome, smoke), forest (deep green, bone, amber), black and tan, cobalt + cream, terracotta + slate, olive + brick + paper, monochrome + one pop.
- Near-black + a single acid-green or vermilion accent.
- Broadsheet hairline rules, zero radius, dense newspaper columns.
- Display serifs `Fraunces` and `Instrument Serif`. A sans display is the correct default (Geist + Geist Mono, Satoshi + JetBrains Mono, Cabinet Grotesk + Inter Tight, GT America + IBM Plex Mono); when a serif is earned, pick from a real pool (PP Editorial New, GT Sectra, Tiempos, Recoleta, Canela, Domaine Display, EB Garamond, Cormorant Garamond). Kinetic emphasis uses italic or bold of the same family, never a second family injected into a headline.
- AI tells to strip on sight: version or section-number eyebrows (`V0.6`, `00 / INDEX`), decorative status dots, locale/weather strips, scroll cues, vertical rotated portfolio text, div-built fake product screenshots with fake version footers, performative-craftsman copy ("Quietly in use at", "Field notes"), pill New/Beta badges, 3-card testimonial carousels with dots, 3-tower pricing tables, sun/moon toggle theater, 4-column footer link farms, rocketship and shield cliche icons.

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

## Flavors (layer exactly one)

Tiebreaks: explicit luxury, calm, or "expensive" language → premium; restrained monochrome or editorial → minimalist; raw grid, terminal, or data-heavy dashboard → brutalist; an aesthetic outside these → run `find-skills` before defaulting. When no aesthetic is named, spend the free axes deliberately and state the direction in one line before coding; don't stack conflicting flavors.

**Premium** (soft contrast, whitespace, feels expensive):

- Double-bezel cards: outer shell `p-1.5`/`p-2` + `ring-1 ring-black/5` + `rounded-[2rem]`; inner core `rounded-[calc(2rem-0.375rem)]` + inset highlight `shadow-[inset_0_1px_1px_rgba(255,255,255,0.15)]`.
- Button-in-button trailing icon: nested `w-8 h-8 rounded-full bg-black/5 dark:bg-white/10` flush with the button's padding; hover `translate-x-1 -translate-y-[1px] scale-105`; press `active:scale-[0.98]`.
- Pick one hex-anchored vibe: ethereal glass (#050505 OLED black, `backdrop-blur-2xl`, white/10 hairlines), editorial luxury (#FDFBF7 cream, variable serif display, film grain `opacity-[0.03]`), soft structuralism (silver-grey, diffused ambient shadows).
- Section whitespace `py-24` to `py-40`. Characterful display faces over Inter/Roboto/Arial/Open Sans. No generic 1px gray borders, no harsh `shadow-md`.

**Editorial minimalist** (warm monochrome, Notion-like):

- Palette: bg #FFFFFF / #F7F6F3 / #FBFBFA; border #EAEAEA; text #111111 or #2F3437 (never pure black); secondary #787774.
- Pastel accent pairs (bg/text): red #FDEBEC/#9F2F2D, blue #E1F3FE/#1F6C9F, green #EDF3EC/#346538, yellow #FBF3DB/#956400.
- Type: serif display (tracking -0.02em to -0.04em, leading 1.1) + sans body (leading 1.6) + mono for data and kbd.
- Cards: 1px #EAEAEA, radius 8-12px, padding 24-40px; shadow opacity under 0.05; CTA solid #111111, radius 4-6px, hover #333333 or scale(0.98). No gradients, no rounded-full containers, stagger reveals `calc(var(--index) * 80ms)`.

**Brutalist / Swiss terminal** (data-heavy, print or military):

- One mode only, never mixed. Swiss print: bg #F4F4F0 / #EAE8E3, fg #050505-#111111. Tactical dark: bg #0A0A0A / #121212 (never #000000), fg #EAEAEA. Sole accent red #E61919 / #FF2A2A; optional single-use terminal green #4AF626.
- Macro type `clamp(4rem, 10vw, 15rem)`, tracking -0.03em to -0.06em, leading 0.85-0.95, uppercase; data type 10-14px mono, tracking +0.05em to +0.1em.
- Zero border-radius. Hairline grids via `display: grid; gap: 1px` with contrasting parent/child backgrounds, not border declarations. CRT scanlines: `repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,0,0,.1) 2px, rgba(0,0,0,.1) 4px)`. Semantic `<data>`, `<samp>`, `<kbd>`, `<output>` for telemetry content.

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

- Sourcing order: generate with an available image tool; else `picsum.photos/seed/<descriptive-seed>/<w>/<h>`; else an explicit labeled placeholder. Never div-built fake screenshots.
- Real logos via Simple Icons (`cdn.simpleicons.org/<slug>`) or devicon; logo only, no category label under it.
- Logo and brand ideation: pick 1 method, max 2 combined (monogram with meaning, product-action symbol, metaphor fusion, negative-space mark, construction geometry); ground the mark in category symbol logic (dev tool: cursor, frame, bolt; security: shield, eye, seal; luxury: monogram, seal, vessel). Tagline under 6 words, no corporate slogan filler.

## Production-quality floor (enforce regardless of flavor)

- Responsive down to mobile; visible keyboard focus; `prefers-reduced-motion` respected.
- **Animate compositor properties only**: `transform` and `opacity` (GPU, no reflow). Never animate `width`/`height`/`top`/`left`/`margin`; those hit layout every frame. When measuring the DOM imperatively, batch reads before writes so a read-write-read pattern can't force synchronous reflows.
- Semantic HTML over `div` soup; pass accessibility checks (axe).
- Watch type-selector vs element-selector rules canceling each other on section padding and margin (silent specificity bugs).
- **Verify visually**: screenshot via `agent-browser`/Playwright and critique your own work, reusing the already-running dev server and Chrome window (verification and reuse rules in `engineering.instructions.md`).

## Stack integration

- **Animation or motion work** → `motion.instructions.md` owns the animation layer: easing and duration values, springs, review-skill routing, and timing tokens.
- **shadcn/ui or Tailwind** project → use the `vercel:shadcn` skill (Vercel plugin, enabled per project) for component install, composition, and theming rather than hand-rolling primitives.
- **Canonical Tailwind classes, never hardcoded arbitrary values.** When a value maps exactly to a scale token, write the token, not the bracket form: `gap-3.5` not `gap-[14px]`, `p-0.5` not `p-[2px]`. Only reach for an arbitrary value (`gap-[13px]`) when the design system has no exact token for it. This is what the Tailwind VS Code plugin (`suggestCanonicalClasses`) and the oxlint `enforce-canonical` rule flag; resolve those hints against the project's own `--spacing` scale, don't assume `1rem = 16px`.
- After editing several React/TSX components → run the `vercel-react-best-practices` review (structure, hooks, a11y, performance).
