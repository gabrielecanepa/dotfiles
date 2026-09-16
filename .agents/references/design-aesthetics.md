# Design direction reference

Load this reference only when inventing a visual direction because the project has no established system.

Choose one direction and adapt it to the product; these are not templates.

## Defaults to avoid

- Do not pair warm cream, a high-contrast serif, terracotta, and brass for premium consumer work by default.
- The #f4f1ea cream family (#f5f1ea, #efeae0, #ece6db with #b08947, #b6553a, #9a2436 accents and #1a1714 text) is the most common default.
- Rotate instead: cold luxury (silver, chrome, smoke), forest (deep green, bone, amber), black and tan, cobalt with cream, or terracotta with slate.
- Olive with brick and paper, or monochrome with one deliberate accent, also work.
- Avoid near-black with a single acid-green or vermilion accent unless the brief supports it.
- Avoid dense newspaper grids, hairline rules everywhere, and zero radius as a generic editorial shortcut.

## Type

- Do not default to `Fraunces` or `Instrument Serif`; a sans display pairing is the correct default.
- Sans pairings: Geist + Geist Mono, Satoshi + JetBrains Mono, Cabinet Grotesk + Inter Tight, or GT America + IBM Plex Mono.
- When a serif is earned: PP Editorial New, GT Sectra, Tiempos, Recoleta, Canela, Domaine Display, EB Garamond, or Cormorant Garamond.
- Select type for the product's voice and language coverage.
- Use weight, width, or italics within one display family before adding another headline family.

## Component specs and audits

- Eyebrow: `rounded-full px-3 py-1 text-[10px] uppercase tracking-[0.2em]`.
- Icon libraries: prefer Phosphor, HugeIcons, Radix Icons, or Tabler over `lucide-react`.
- General UI audit source: `https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md`.

## Accessories to remove

- Decorative status dots, fake version labels, weather strips, scroll cues, rotated portfolio text, and fake product screenshots.
- Generic Beta pills, decorative theme toggles, formulaic testimonial carousels, pricing towers, and footer farms.
- Stock rocket or shield metaphors, unless they serve real content.

## Choose one coherent direction

- Use explicit language in the brief as the tiebreaker.
- Calm, tactile, or expensive work may support premium restraint; monochrome or editorial work may support minimalism.
- Raw grids, terminals, and dense telemetry may support a Swiss or brutalist direction.
- For a materially different aesthetic, use `find-skills` instead of forcing one of these.

### Premium restraint

- Use soft contrast, generous whitespace (section padding `py-24` to `py-40`), one characterful display face, and restrained depth.
- Avoid generic 1px gray borders and stock `shadow-md`.
- Pick one hex-anchored material vocabulary and do not mix them: ethereal glass, editorial luxury, or soft structuralism.
- Ethereal glass: #050505 OLED black, `backdrop-blur-2xl`, white/10 hairlines.
- Editorial luxury: #FDFBF7 cream, variable serif display, film grain at `opacity-[0.03]`.
- Soft structuralism: silver-grey surfaces, diffused ambient shadows.
- Double bezels and nested button icons are accents, not defaults; use them only when they reinforce hierarchy and interaction.

Double-bezel card: outer shell `p-1.5` or `p-2` with `ring-1 ring-black/5` and `rounded-[2rem]`.

Inner core: `rounded-[calc(2rem-0.375rem)]` with `shadow-[inset_0_1px_1px_rgba(255,255,255,0.15)]`.

Button-in-button trailing icon: nested `w-8 h-8 rounded-full bg-black/5 dark:bg-white/10` flush with the padding.

Icon motion: hover `translate-x-1 -translate-y-[1px] scale-105`; press `active:scale-[0.98]`.

### Editorial minimalism

- Palette: backgrounds #FFFFFF, #F7F6F3, #FBFBFA; border #EAEAEA; text #111111 or #2F3437, never pure black; secondary #787774.
- Pastel accent pairs for semantic emphasis only: red #FDEBEC/#9F2F2D, blue #E1F3FE/#1F6C9F, green #EDF3EC/#346538, yellow #FBF3DB/#956400.
- Avoid gradients and pill containers as default structure.
- Type roles: serif display (tracking -0.02em to -0.04em, leading 1.1), sans body (leading 1.6), mono for data and `kbd`.
- Let spacing and type create hierarchy before adding cards or rules.
- Cards: 1px #EAEAEA border, radius 8 to 12px, padding 24 to 40px, shadow opacity under 0.05.
- CTA: solid #111111, radius 4 to 6px, hover #333333 or `scale(0.98)`; stagger reveals with `calc(var(--index) * 80ms)`.

### Swiss or terminal brutalism

- Choose print light or tactical dark, never both.
- Swiss print: backgrounds #F4F4F0 and #EAE8E3, foreground #050505 to #111111.
- Tactical dark: backgrounds #0A0A0A and #121212, never #000000, foreground #EAEAEA.
- Sole accent red #E61919 or #FF2A2A; reserve a single-use terminal green #4AF626 for real status.
- Macro display type `clamp(4rem, 10vw, 15rem)`, tracking -0.03em to -0.06em, leading 0.85 to 0.95, uppercase.
- Data type 10 to 14px mono with tracking +0.05em to +0.1em; use semantic `<data>`, `<samp>`, `<kbd>`, and `<output>` for telemetry.
- Zero radius; hairline grids via `display: grid; gap: 1px` with contrasting parent and child backgrounds, not border declarations.
- CRT scanlines only when the product context earns them.

CRT scanline value: `repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,0,0,.1) 2px, rgba(0,0,0,.1) 4px)`.

## Logo and brand marks

- Pick one method, at most two combined: monogram with meaning, product-action symbol, metaphor fusion, negative-space mark, or construction geometry.
- Ground the mark in category symbol logic: dev tool (cursor, frame, bolt), security (shield, eye, seal), luxury (monogram, seal, vessel).
- Keep the tagline under 6 words with no corporate slogan filler.
