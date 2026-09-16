---
description: 'Use for UI animation: Motion for React, CSS transitions, React View Transitions, springs, gestures, layout and scroll effects. Owns values, APIs, performance, and review.'
applyTo: '**/*.jsx, **/*.tsx, **/*.css'
paths:
  - '**/*.jsx'
  - '**/*.tsx'
  - '**/*.css'
---

# Motion and animation

The production floor in `design.md` still applies. Values, formulas, and sources live in `../references/motion-examples.md`.

## Purpose and review

- Give every animation a purpose, an easing, and a duration; keyboard-initiated actions and interactions repeated 100 or more times daily get none.
- When reviewing an animation diff, report only motion findings; the Web Interface Guidelines audit in `design.md` owns the general UI pass.
- Treat every violation as a finding; `ease-in`, `scale(0)`, `transition: all`, keyframes on rapid UI, ungated hover, and easy GPU fixes block.
- Animated keyboard or high-frequency actions and unjustified UI durations over 300ms also block.
- Fix in this order: delete, reduce, easing, origin, interruptibility, GPU, split deliberate and response timing, polish, then reduced-motion and hover gating.
- Report one Before / After / Why table with `file:line`, remaining notes ordered by impact, and a closing Block or Approve.
- When feel cannot be judged from code, ask for a slow-motion or frame-by-frame check instead of guessing.
- When asked to improve animations codebase-wide, stay read-only: map stack, tokens, and frequency, rank findings by impact, plan only what the user selects.

## Easing and duration

- Use the custom curves from the reference; built-in CSS eases are too weak.
- Use ease-out for enter and exit, ease-in-out for on-screen moves, ease for hover and color, linear for constant motion; never ease-in for UI.
- Pick durations by element from the reference; exits stay faster than entrances.
- Never animate from `scale(0)`; start at `scale(0.9)` or higher with opacity.
- Give popovers `transform-origin` from the trigger; keep modals centered.
- Use transitions or springs, with `@starting-style` for JS-free entry, on anything triggered rapidly; keyframes restart from zero.
- When a crossfade still looks off after tuning, bridge it with `filter: blur(2px)` and keep blur well under 20px.

## Springs and gestures

- Use damping 1.0 by default and about 0.8 only when the gesture carried momentum.
- Write springs in the perceptual form `{ type: "spring", duration, bounce }`, never raw stiffness and damping.
- On release, hand off velocity and project momentum with the reference formulas, snapping to the nearest snap point.
- Animate interruptions from the live presentation value, never the target, and blend velocity through re-targets.
- Honor the three reduced-motion signals and gate hover motion behind a fine pointer.
- Never stack translucent material on translucent; heavier material reads as structural, lighter as interactive.

## Motion for React

- Import from `motion/react`; never introduce the legacy `framer-motion` alias.
- Give every `AnimatePresence` child a stable `key`, put the conditional inside it, and pick `mode` deliberately.
- Use `layout` for size or position changes, `layoutId` for shared-element morphs, and `LayoutGroup` for components that do not co-render.
- Run high-frequency values (cursor follow, scroll progress, drag) through motion values, never through React state or rAF loops.
- Set app-wide defaults in `MotionConfig` (`transition`, `reducedMotion="user"`).
- On content and marketing pages, use `LazyMotion` with the `m` component to cut bundle size.
- Reach for Motion only where CSS cannot express the result; simple hover, fade, and accordion states stay CSS.
- Verify non-trivial APIs through Context7 `/websites/motion_dev`, or the Motion AI Kit MCP when the project has it.

## View Transitions and performance

- Use `<ViewTransition>` only inside `startTransition`, `useDeferredValue`, or Suspense, placed before any DOM node.
- In the Next.js App Router, never install `react@canary`; the router bundles the API.
- Use `default="none"` and directional `addTransitionType` maps per the reference; verify the API through Context7.
- Animate only compositing properties (`transform`, `opacity`, `filter`, `clip-path`); route size changes through `layout`.
- Never `transition: all`; list the animated properties and apply `will-change` only while the element animates.
- Never transition theme switches; pause looping animations offscreen.
- Pull prebuilt animated components from the shadcn MCP registries, preferring `motion-primitives`, and retune them to the project's tokens.
