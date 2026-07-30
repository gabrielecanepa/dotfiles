---
description: 'Use when writing, reviewing, or auditing UI animations: Motion for React (motion.dev), CSS transitions and keyframes, springs, gestures, layout or shared-element transitions, scroll-linked effects. Owns easing, duration, and spring values, routes the animation review skills, pins current Motion docs sources, and enforces Motion API correctness.'
applyTo: '**/*.jsx, **/*.tsx, **/*.css'
paths:
  - '**/*.jsx'
  - '**/*.tsx'
  - '**/*.css'
---

# Motion and animation

Engage when the task involves animation: Motion for React, CSS transitions or keyframes, springs, gestures, layout or shared-element transitions, scroll-linked effects. The production floor in `design.instructions.md` (compositor-only properties, `prefers-reduced-motion`) still applies; this file owns everything animation-specific on top of it. For the React View Transition API with no library (`<ViewTransition>`, `addTransitionType`, view-transition pseudo-elements), verify against current React docs through Context7 before writing it; training data predates the stable API.

## Skills

- **Reviewing animation code** -> `review-animations` with its bundled `STANDARDS.md`. Keep it to motion findings; `web-design-guidelines` owns the general UI audit, so do not report the same file through both.
- **Codebase-wide "improve the animations" requests** -> `improve-animations` (read-only; produces a prioritized plan).
- **Naming an effect from a vague description** -> `animation-vocabulary`.

Authoring values live inline below, distilled from `emilkowalski/skills` (`emil-design-eng`, `apple-design`; both retired as skills). The gate for every animation you add: does it have a purpose, which easing, which duration. Keyboard-initiated actions and 100+ times-a-day interactions get no animation.

## Easing and duration

- Custom curves; built-in CSS eases are too weak: `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)`; `--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1)`; `--ease-drawer: cubic-bezier(0.32, 0.72, 0, 1)` (iOS-like sheet/drawer).
- By kind: enter and exit -> ease-out; on-screen move or morph -> ease-in-out; hover and color -> ease; constant motion (marquee, progress) -> linear. Never ease-in for UI; it delays the moment being watched most.
- By element: button press 100-160ms; tooltip and small popover 125-200ms; dropdown and select 150-250ms; modal and drawer 200-500ms; marketing pages may go longer. Exits faster than entrances.
- Never animate from `scale(0)`; start at `scale(0.9)` or higher with opacity. Popovers take `transform-origin` from the trigger (`var(--radix-popover-content-transform-origin)`); modals stay centered.
- Press/release asymmetry: slow and linear while the user decides (hold-to-delete: 2s linear), fast ease-out on release (~200ms).
- A crossfade that still looks off after easing and duration tuning: bridge it with `filter: blur(2px)` (keep well under 20px; blur is costly in Safari).

## Springs and gestures

- Damping 1.0 is the critically damped default (no overshoot); ~0.8 (bounce) only when the gesture itself carried momentum (flick, throw, release). Apple's shipped values: move or reposition damping 1.0 response 0.4; rotation 0.8/0.4; drawer or sheet 0.8/0.3. Web form: `{ type: "spring", bounce: 0, duration: 0.4 }` default, `bounce: 0.2` for momentum; most UI wants bounce 0 to 0.2.
- Velocity handoff on release: relativeVelocity = gestureVelocity / (target - current).
- Momentum projection (Apple's decay form, not the v^2/2a textbook form): project(v, d = 0.998) = (v / 1000) * d / (1 - d); d = 0.99 for snappier decay; snap target = nearest snap point to position + projection.
- Rubber-banding at boundaries: f(overshoot, dim, k = 0.55) = (overshoot * dim * k) / (dim + k * |overshoot|).
- Interruption: animate from the live presentation value, never the target, and blend velocity through re-targets instead of hard-cutting. Decompose 2D drag into independent X and Y springs. Commit to a drag direction only after ~10px of movement.
- Reduced motion is three independent signals: `prefers-reduced-motion` (crossfade, drop overshoot), `prefers-reduced-transparency` (raise opacity, drop blur), `prefers-contrast: more` (solid background, defined border). Avoid loops near 0.2Hz (one cycle per 5s).
- Materials: never stack translucent on translucent; heavier material reads as structural, lighter as interactive.

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
- Springs: use the perceptual form `{ type: "spring", duration, bounce }` rather than raw stiffness/damping (Apple's WWDC23 parametrization, https://developer.apple.com/videos/play/wwdc2023/10158/). Values live in "Springs and gestures" above.
- App-wide defaults live in `MotionConfig` (`transition`, `reducedMotion="user"`).
- Bundle size: content and marketing pages use `LazyMotion` with the `m` component (`motion/react-m`), cutting the 34 KB `motion` component to under 5 KB on first render; imperative-only needs can use the mini `useAnimate`.
- Reach for Motion only where CSS cannot express the result: springs, gestures, layout and shared-element transitions, orchestration, scroll-linked values. Simple hover, fade, and accordion states stay CSS.

## Enterprise timing

On top of the easing and duration values above:

- When the product needs a motion token system, adopt IBM Carbon's split (https://carbondesignsystem.com/elements/motion/overview/): productive motion for task flows at 70-240ms, expressive motion for brand or celebratory moments at 250-700ms, used sparingly. Scale duration with distance and element size; past 400ms a standard transition reads as slow.
- Keep ease-out on exits. Material and Carbon accelerate exits; follow their curves only when the project's design system explicitly adopts those tokens.
- Stagger 30-80ms between items, and cap the choreography so the last item still lands within the duration bar above.
- Theme switches never transition. Looping animations pause when offscreen. Frequent, low-novelty actions get no extra animation. (https://interfaces.rauno.me)

## Performance

- Rank properties by Motion's render-pipeline tier list (https://motion.dev/magazine/web-animation-performance-tier-list): `transform`, `opacity`, `filter`, and `clip-path` composite; animating CSS variables repaints every frame; size and position changes go through Motion's `layout` FLIP, never direct `width`/`height` animation.
- `will-change` surgically and only while the element animates.
- Motion's `x`/`y`/`scale` shorthands run on the main thread (rAF loop), not the compositor; animate the full `transform` string when hardware acceleration matters.

## Prebuilt components

Pull animated components through the shadcn MCP registries instead of hand-rolling: prefer `motion-primitives` (restrained, product UI) over Magic UI or Aceternity (marketing-flavored, heavier DOM). After install, retune easing and duration to the project's tokens; never ship registry defaults unreviewed.
