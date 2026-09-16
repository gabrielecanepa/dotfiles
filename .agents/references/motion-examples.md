# Motion values and formulas

Values, formulas, and sources behind `rules/motion.md`. Read the section the current task needs.

## Easing curves

- `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)`
- `--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1)`
- `--ease-drawer: cubic-bezier(0.32, 0.72, 0, 1)` for iOS-like sheets and drawers
- By kind: enter and exit use ease-out; on-screen move or morph uses ease-in-out; hover and color use ease; constant motion (marquee, progress) uses linear.

## Durations by element

- Button press: 100 to 160ms.
- Tooltip and small popover: 125 to 200ms.
- Dropdown and select: 150 to 250ms.
- Modal and drawer: 200 to 500ms.
- Marketing pages may run longer; exits stay faster than entrances.
- Press and release asymmetry: slow and linear while the user decides (hold-to-delete: 2s linear), fast ease-out on release (about 200ms).

## Enterprise timing

- IBM Carbon token split: productive task motion 70 to 240ms, sparse expressive motion 250 to 700ms; over 400ms reads as slow.
- Carbon source: https://carbondesignsystem.com/elements/motion/overview/
- Stagger 30 to 80ms between items and cap the choreography so the last item lands within the duration bar.

## Spring values

- Damping 1.0 is the critically damped default with no overshoot; about 0.8 only when the gesture carried momentum (flick, throw, release).
- Apple's shipped values: move or reposition damping 1.0 response 0.4; rotation 0.8 and 0.4; drawer or sheet 0.8 and 0.3.
- Web form: `{ type: "spring", bounce: 0, duration: 0.4 }` by default, `bounce: 0.2` for momentum; most UI wants bounce 0 to 0.2.
- Perceptual parametrization source: https://developer.apple.com/videos/play/wwdc2023/10158/

## Gesture formulas

- Velocity handoff on release: `relativeVelocity = gestureVelocity / (target - current)`.
- Momentum projection, Apple's decay form: `project(v, d = 0.998) = (v / 1000) * d / (1 - d)`; `d = 0.99` for snappier decay.
- Snap target is the nearest snap point to `position + projection`.
- Rubber-banding at boundaries: `f(overshoot, dim, k = 0.55) = (overshoot * dim * k) / (dim + k * |overshoot|)`.
- Commit to a drag direction only after about 10px of movement; decompose 2D drag into independent X and Y springs.

## Accessibility signals

- `prefers-reduced-motion`: crossfade and drop overshoot.
- `prefers-reduced-transparency`: raise opacity and drop blur.
- `prefers-contrast: more`: solid background and defined border.
- Hover gating: `@media (hover: hover) and (pointer: fine)`; touch fires false hovers on tap.
- Avoid loops near 0.2Hz (one cycle per 5s).

## Motion for React detail

- `AnimatePresence` modes: `"wait"` for one-at-a-time, `"popLayout"` when exiting list items should release layout immediately.
- Layout distortion fix: set `borderRadius` and `boxShadow` via `style` and add `layout` to distorted children.
- `LazyMotion` with the `m` component (`motion/react-m`) cuts the 34 KB `motion` component to under 5 KB on first render.
- Imperative-only needs can use the mini `useAnimate`.
- Render-pipeline tier list: `transform`, `opacity`, `filter`, and `clip-path` composite; animating CSS variables repaints every frame.
- Tier list source: https://motion.dev/magazine/web-animation-performance-tier-list
- Motion's `x`, `y`, and `scale` shorthands run on the main thread; animate the full `transform` string when hardware acceleration matters.

## View Transitions detail

- `default="none"` on named and type-keyed boundaries stops Suspense reveals and revalidations from cross-fading.
- `default="none"` also turns off `update` and `share`; keep keyed list items and displaced siblings bare, and give a named pair an explicit `share`.
- `router.back()` and the browser back button carry no transition types, so every `addTransitionType` map needs a `default`.

## Sources

- Context7 library ID `/websites/motion_dev` is current and complete; avoid the legacy `/grx7/framer-motion` index.
- Motion page index: https://motion.dev/llms.txt (no `llms-full.txt` or per-page `.md` variants exist).
- Frequent, low-novelty actions get no extra animation: https://interfaces.rauno.me
