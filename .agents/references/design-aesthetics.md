# Design direction reference

Load this reference only when inventing a visual direction because the project has no established system. Choose one direction and adapt it to the product rather than treating these examples as templates.

## Defaults to avoid

- Do not automatically pair warm cream, a high-contrast serif, terracotta, and brass for premium consumer work: the #f4f1ea cream family (backgrounds #f5f1ea, #efeae0, #ece6db; accents #b08947, #b6553a, #9a2436; espresso text #1a1714) is the most common default. Rotate instead: cold luxury (silver, chrome, smoke), forest (deep green, bone, amber), black and tan, cobalt with cream, terracotta with slate, olive with brick and paper, or monochrome with one deliberate accent.
- Avoid near-black with a single acid-green or vermilion accent unless the brief supports it.
- Avoid dense newspaper grids, hairline rules everywhere, and zero radius as a generic editorial shortcut.
- Do not default to `Fraunces` or `Instrument Serif`. A sans display pairing is the correct default: Geist + Geist Mono, Satoshi + JetBrains Mono, Cabinet Grotesk + Inter Tight, or GT America + IBM Plex Mono. When a serif is earned, pick from PP Editorial New, GT Sectra, Tiempos, Recoleta, Canela, Domaine Display, EB Garamond, or Cormorant Garamond. Select type for the product's voice and actual language coverage, and use weight, width, or italics within one display family before introducing another headline family.
- Remove decorative status dots, fake version labels, weather strips, scroll cues, rotated portfolio text, fake product screenshots, generic Beta pills, decorative theme toggles, formulaic testimonial carousels, pricing towers, footer farms, and stock rocket or shield metaphors unless they serve real content.

## Choose one coherent direction

Use explicit language in the brief as the tiebreaker. Calm, tactile, or expensive work may support premium restraint. Monochrome or editorial work may support minimalism. Raw grids, terminals, and dense telemetry may support a Swiss or brutalist direction. For a materially different aesthetic, use `find-skills` rather than forcing one of these.

### Premium restraint

- Use soft contrast, generous whitespace (section padding `py-24` to `py-40`), one characterful display face, and restrained depth. Avoid generic 1px gray borders and stock `shadow-md`.
- Pick one hex-anchored material vocabulary and do not mix them: ethereal glass (#050505 OLED black, `backdrop-blur-2xl`, white/10 hairlines), editorial luxury (#FDFBF7 cream, variable serif display, film grain at `opacity-[0.03]`), or soft structuralism (silver-grey surfaces, diffused ambient shadows).
- Double bezels and nested button icons are accents, not defaults; use them only when they reinforce hierarchy and interaction. Double-bezel card: outer shell `p-1.5` or `p-2` with `ring-1 ring-black/5` and `rounded-[2rem]`; inner core `rounded-[calc(2rem-0.375rem)]` with inset highlight `shadow-[inset_0_1px_1px_rgba(255,255,255,0.15)]`. Button-in-button trailing icon: nested `w-8 h-8 rounded-full bg-black/5 dark:bg-white/10` flush with the button padding; hover `translate-x-1 -translate-y-[1px] scale-105`; press `active:scale-[0.98]`.

### Editorial minimalism

- Palette: backgrounds #FFFFFF, #F7F6F3, #FBFBFA; border #EAEAEA; text #111111 or #2F3437, never pure black; secondary #787774.
- Pastel accent pairs (background and text), for semantic emphasis only: red #FDEBEC/#9F2F2D, blue #E1F3FE/#1F6C9F, green #EDF3EC/#346538, yellow #FBF3DB/#956400. Avoid gradients and pill containers as default structure.
- Type roles: serif display (tracking -0.02em to -0.04em, leading 1.1), sans body (leading 1.6), mono for data and `kbd`. Let spacing and type create hierarchy before adding cards or rules.
- Cards: 1px #EAEAEA border, radius 8-12px, padding 24-40px, shadow opacity under 0.05. CTA: solid #111111, radius 4-6px, hover #333333 or `scale(0.98)`. Stagger reveals with `calc(var(--index) * 80ms)`.

### Swiss or terminal brutalism

- Choose print light or tactical dark, never both. Swiss print: backgrounds #F4F4F0 and #EAE8E3, foreground #050505 to #111111. Tactical dark: backgrounds #0A0A0A and #121212, never #000000, foreground #EAEAEA. Sole accent red #E61919 or #FF2A2A; reserve a single-use terminal green #4AF626 for real status.
- Macro display type `clamp(4rem, 10vw, 15rem)`, tracking -0.03em to -0.06em, leading 0.85-0.95, uppercase; data type 10-14px mono with tracking +0.05em to +0.1em. Use semantic `<data>`, `<samp>`, `<kbd>`, and `<output>` for telemetry.
- Zero radius. Hairline grids via `display: grid; gap: 1px` with contrasting parent and child backgrounds, not border declarations. CRT scanlines: `repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,0,0,.1) 2px, rgba(0,0,0,.1) 4px)`. Apply these signals consistently and only when the product context earns them.
