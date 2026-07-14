---
description: 'Use when writing, reviewing, or auditing UI animations: Motion for React (motion.dev), CSS transitions and keyframes, springs, gestures, layout or shared-element transitions, scroll-linked effects. Routes the animation skills, pins current Motion docs sources, and enforces Motion API correctness.'
applyTo: '**/*.jsx, **/*.tsx, **/*.css'
paths:
  - '**/*.jsx'
  - '**/*.tsx'
  - '**/*.css'
---

# Motion and animation

Engage when the task involves animation: Motion for React, CSS transitions or keyframes, springs, gestures, layout or shared-element transitions, scroll-linked effects. The production floor in `design.instructions.md` (compositor-only properties, `prefers-reduced-motion`) still applies; this file owns everything animation-specific on top of it. For the React View Transition API with no library, `vercel-react-view-transitions` remains the route.

## Skills

- **Authoring any animation** -> `emil-design-eng` (source: `emilkowalski/skills`), the taste layer. Its decision framework (should it animate, purpose, easing, duration) gates every animation you add. Keyboard-initiated actions and 100+ times-a-day interactions get no animation.
- **Reviewing animation code** -> `review-animations` with its bundled `STANDARDS.md`. Keep it to motion findings; `web-design-guidelines` owns the general UI audit, so do not report the same file through both.
- **Codebase-wide "improve the animations" requests** -> `improve-animations` (read-only; produces a prioritized plan).
- **Naming an effect from a vague description** -> `animation-vocabulary`.
- **Gesture-driven, drag/swipe/sheet, iOS-feel work** -> add `apple-design`.

## Current docs, not training data

The framer-motion to motion rebrand outdated training data. Verify any non-trivial API against current docs before writing it:

- Context7 library ID `/websites/motion_dev` (current and complete). Avoid the legacy `/grx7/framer-motion` index.
- Full page index: https://motion.dev/llms.txt (no `llms-full.txt` or per-page `.md` variants exist).
- If the project has the official Motion AI Kit MCP configured (`npx motion-ai`, requires Motion+), prefer its docs search and `/motion` skill, and finish significant work with its MotionScore audit.

## Motion for React API rules

- Import from `motion/react`. `framer-motion` is a legacy alias; never introduce it in new code.
- `AnimatePresence`: every child needs a stable `key`; the conditional goes inside it, never around it; pick `mode` deliberately (`"wait"` for one-at-a-time, `"popLayout"` when exiting list items should release layout immediately).
- Layout and shared elements: `layout` for size or position changes (FLIP on transforms, no paint), `layoutId` for shared-element morphs, `LayoutGroup` to coordinate components that do not co-render. Fix scale distortion by setting `borderRadius` and `boxShadow` via `style` and adding `layout` to distorted children.
- High-frequency values (cursor follow, scroll progress, drag) run through motion values (`useMotionValue`, `useTransform`, `useSpring`, `useScroll`), never through React state or rAF loops; motion values bypass re-renders.
- Springs: use the perceptual form `{ type: "spring", duration, bounce }` rather than raw stiffness/damping (Apple's WWDC23 parametrization, https://developer.apple.com/videos/play/wwdc2023/10158/). `emil-design-eng` owns the values; most UI wants bounce 0 to 0.2.
- App-wide defaults live in `MotionConfig` (`transition`, `reducedMotion="user"`).
- Bundle size: content and marketing pages use `LazyMotion` with the `m` component (`motion/react-m`), cutting the 34 KB `motion` component to under 5 KB on first render; imperative-only needs can use the mini `useAnimate`.
- Reach for Motion only where CSS cannot express the result: springs, gestures, layout and shared-element transitions, orchestration, scroll-linked values. Simple hover, fade, and accordion states stay CSS.

## Enterprise timing

`emil-design-eng` owns easing and duration per interaction (ease-out family, UI under 300ms, exits faster than entrances). On top of it:

- When the product needs a motion token system, adopt IBM Carbon's split (https://carbondesignsystem.com/elements/motion/overview/): productive motion for task flows at 70-240ms, expressive motion for brand or celebratory moments at 250-700ms, used sparingly. Scale duration with distance and element size; past 400ms a standard transition reads as slow.
- Keep ease-out on exits. Material and Carbon accelerate exits; follow their curves only when the project's design system explicitly adopts those tokens.
- Stagger 30-80ms between items, and cap the choreography so the last item still lands within the duration bar above.
- Theme switches never transition. Looping animations pause when offscreen. Frequent, low-novelty actions get no extra animation. (https://interfaces.rauno.me)

## Performance

- Rank properties by Motion's render-pipeline tier list (https://motion.dev/magazine/web-animation-performance-tier-list): `transform`, `opacity`, `filter`, and `clip-path` composite; animating CSS variables repaints every frame; size and position changes go through Motion's `layout` FLIP, never direct `width`/`height` animation.
- `will-change` surgically and only while the element animates.

## Prebuilt components

Pull animated components through the shadcn MCP registries instead of hand-rolling: prefer `motion-primitives` (restrained, product UI) over Magic UI or Aceternity (marketing-flavored, heavier DOM). After install, retune easing and duration to the project's tokens; never ship registry defaults unreviewed.
