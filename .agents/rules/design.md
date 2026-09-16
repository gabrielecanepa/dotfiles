---
description: 'Use when building or restyling UI: interfaces, landing pages, components, redesigns. Project system first, one direction, layout caps, a11y, browser checks.'
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

# Frontend design

Applies to visual construction or restyling, not to backend logic, configuration, copy, or exact-style matching.

"The reference" below is `~/.agents/references/design-aesthetics.md`.

## Direction

- When the repository defines a visual system (docs, tokens, themes, a component library, Figma, Storybook), follow it.
- When the brief belongs to an established product family, use its official system; never import one and override it.
- When no project system exists, load the reference, choose one direction, and state it before coding.
- Plan before coding: a 4 to 6 hex palette, two or more type roles, a layout concept, and one signature element.
- When any part of the plan reads like the default for a similar page, revise it and say why.
- Spend boldness in one place, keep the rest quiet, and remove one accessory as the last pass.

## Layout caps

- Hero: headline 2 lines max, subtext 20 words and 4 lines max, at most 4 text elements, `pt-24` max, nav 64 to 72px (80px cap).
- Keep trust logos, pricing, and feature bullets below the hero; the first viewport has one focal point and a visible CTA.
- Headline scale: `text-4xl md:text-5xl lg:text-6xl`; use `text-6xl md:text-7xl` only for 3 to 5 word headlines.
- Eyebrows: at most 1 per 3 sections, hero included; spec in the reference.
- Use a layout family (3-col cards, split, bento) once per page; cap zigzag splits at 2 in a row; one bento cell per item.
- Never nest cards three deep or wrap a whole section in one rounded container.
- CTAs: 1 to 3 words on one line, one label per intent site-wide.
- Lists over 5 items: card grid, grouped chunks, or scroll-snap pills, never `divide-y` hairlines.

## Type, measure, and icons

- Paragraph measure about 65ch; container max-width 1200 to 1440px; messy real data (47.2%, not 50%).
- One icon library with a global `strokeWidth` of 1.5 or 2, from the reference list; never hand-roll SVG paths.
- Write canonical Tailwind classes (`gap-3.5`, not `gap-[14px]`); use a bracket value only when the `--spacing` scale has no token.

## UI copy

- Follow `writing.md`: active voice, plain verbs, sentence case, no filler, real content instead of lorem.
- Name controls by what users manage; keep an action's name through its flow (button "Publish", toast "Published").
- Errors state what happened and the next step; empty states invite an action.

## Redesigns

- Audit first: diagnose the current patterns against the caps above, fix surgically, and test after each change.
- Fix in this order: fonts, colors, hover and active states, layout and spacing, generic components, async states, type polish.
- Check the omissions: legal links, back navigation, custom 404, skip-to-content, cookie consent, client-side validation.
- Prefer optical alignment over math: bottom-align CTAs across cards, align list start Y across columns, nudge icons 1 to 2px.
- Never silently change URL slugs, nav labels, form field names, the logo, or legal copy.

## Images and brand marks

- Prefer project-owned assets, then generated imagery, then a licensed source; otherwise a labeled placeholder.
- Never build fake screenshots from generic divs, approximate a logo, or load icons from a remote CDN in production.
- For logo ideation, follow the method list in the reference.

## Production floor

- Responsive down to mobile, visible keyboard focus, `prefers-reduced-motion` respected, semantic HTML, axe checks passing.
- Animate only `transform` and `opacity`; never animate `width`, `height`, `top`, `left`, or `margin`.
- When measuring the DOM imperatively, batch reads before writes.
- Watch type-selector and element-selector rules canceling each other on section spacing.
- Verify visually: screenshot through `agent-browser` per `browser.md` on the running dev server, then critique it.
- For a general UI audit, fetch the Web Interface Guidelines URL from the reference and report findings as `file:line`.

## Stack integration

- Animation or motion work: `motion.md` owns easing, duration, springs, and animation review.
- shadcn/ui or Tailwind: use the project's shadcn skill or MCP when present, otherwise verify current guidance through Context7.
- After editing several React or TSX components, run the project-installed `vercel-react-best-practices` review.
