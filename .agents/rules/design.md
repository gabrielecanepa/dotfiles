---
description: "Use for UI construction and redesign: project systems, visual direction, layout, accessibility, copy, and browser checks."
applyTo: "**/*.astro, **/*.css, **/*.html, **/*.jsx, **/*.less, **/*.sass, **/*.scss, **/*.stories.*, **/*.svelte, **/*.tsx, **/*.vue"
paths:
  - "**/*.astro"
  - "**/*.css"
  - "**/*.html"
  - "**/*.jsx"
  - "**/*.less"
  - "**/*.sass"
  - "**/*.scss"
  - "**/*.stories.*"
  - "**/*.svelte"
  - "**/*.tsx"
  - "**/*.vue"
---

# Frontend design

Applies to UI construction and restyling, not backend, config, copy-only, or exact-style tasks.

Reference: `~/.agents/references/design-aesthetics.md`.

## Direction

- Follow the repository's visual system: tokens, themes, component library, Figma, or Storybook.
- For an established product family, use its official system; never import one and override it.
- Without a project system, load the reference and state one direction before coding.
- When defining a new visual direction, plan a 4 to 6 hex palette, two or more type roles, a layout concept, and one signature element.
- If the plan repeats a familiar page pattern, revise it and state why.
- Spend boldness in one place, keep the rest quiet, and remove one accessory as the last pass.

## Layout caps

These defaults apply to new marketing pages where the brief and project system are silent, not existing app layouts.

- Hero: headline 2 lines max, subtext 20 words and 4 lines max, at most 4 text elements, `pt-24` max, nav 64 to 72px (80px cap).
- Keep trust logos, pricing, and feature bullets below the hero; the first viewport has one focal point and a visible CTA.
- Headline scale: `text-4xl md:text-5xl lg:text-6xl`; use `text-6xl md:text-7xl` only for 3 to 5 word headlines.
- Eyebrows: at most 1 per 3 sections, hero included; spec in the reference.
- Use a layout family (3-col cards, split, bento) once per page; cap zigzag splits at 2 in a row; one bento cell per item.
- Never nest cards three deep or wrap a whole section in one rounded container.
- CTAs: 1 to 3 words on one line, one label per intent site-wide.
- Lists over 5 items: card grid, grouped chunks, or scroll-snap pills, never `divide-y` hairlines.

## Type, measure, and icons

- Without project layout tokens, use paragraph measure about 65ch and container max-width 1200 to 1440px.
- Preserve actual data values; use clearly labeled sample data when real data is unavailable.
- One icon library with a global `strokeWidth` of 1.5 or 2, from the reference list; never hand-roll SVG paths.
- In Tailwind projects, use canonical classes (`gap-3.5`, not `gap-[14px]`) where the configured scale provides a matching value.

## UI copy

- Follow `writing.md`: active voice, plain verbs, sentence case, no filler, real content instead of lorem.
- Name controls by what users manage; keep an action's name through its flow (button "Publish", toast "Published").
- Errors state what happened and the next step; empty states invite an action.

## Redesigns

- Audit first: diagnose the current patterns against the caps above, fix surgically, and test after each change.
- Fix in this order: fonts, colors, hover and active states, layout and spacing, generic components, async states, type polish.
- Flag relevant missing navigation, error, accessibility, validation, or legal states; do not add features or legal copy unasked.
- Prefer optical alignment over math: bottom-align CTAs across cards, align list start Y across columns, nudge icons 1 to 2px.
- Never silently change URL slugs, nav labels, form field names, the logo, or legal copy.

## Images and brand marks

- Prefer project-owned assets, then generated imagery, then a licensed source; otherwise a labeled placeholder.
- Never build fake screenshots from generic divs, approximate a logo, or load icons from a remote CDN in production.
- For logos, use the reference methods.

## Production floor

- Responsive down to mobile, visible keyboard focus, `prefers-reduced-motion` respected, semantic HTML, axe checks passing.
- Default to `transform` and `opacity`; `motion.md` owns measured exceptions, and layout properties must not animate directly.
- When measuring the DOM imperatively, batch reads before writes.
- Check conflicting CSS selectors when section spacing differs from the tokens.
- Verify screenshots with `agent-browser` on the running dev server per `browser.md`.
- For a general UI audit, fetch the Web Interface Guidelines URL from the reference and report findings as `file:line`.

## Stack integration

- `motion.md` owns easing, duration, springs, and animation review.
- shadcn/ui or Tailwind: use the project's shadcn skill or MCP when present, otherwise verify current guidance through Context7.
- After several React component edits, run the installed `vercel-react-best-practices` review.
