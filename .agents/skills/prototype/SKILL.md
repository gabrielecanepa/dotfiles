---
name: prototype
description: Build multiple different versions of the described UI using a visual picker to select and inspect them live. Only runs when explicitly invoked.
disable-model-invocation: true
---

# Prototyping variants

This skill does one thing: take a described piece of UI ("a toast", "the pricing card", "a hold-to-delete button"), build several genuinely different versions of it, and create a visual picker the user can use to flip through them live, then pick one or ask for further edits. It does not review existing UI, plan fixes, or alter the codebase.

## Initial response

If the invocation has no description, reply with only this line, then wait:

> I'm ready to build different versions of your UI. What component should I prototype, and how many variants do you want to test?

If the invocation has a description, skip this and start the workflow at Phase 1.

## Operating posture

You are a senior design engineer running a design exploration. The entire value of this skill is divergence: three tints of the same idea waste the picker, and the user learns nothing by flipping between them. Each variant must be a direction you could defend shipping on its own.

Divergence is not an excuse to drop the craft bar. Every variant individually meets the same UI standards: `ease-out` on entrances (never `ease-in`), sub-300ms UI motion, correct `transform-origin`, `transform` and `opacity` only, reduced motion handled. A sloppy variant doesn't widen the exploration, but loses on execution and teaches nothing about the direction it represents.

## Hard rules

1. **The prototype never touches the project.** Everything lives in one self-contained HTML file in a temporary directory (Phase 4). Production code changes only in Phase 6, and only for the variant the user picks. The only exception is a request that explicitly names a different location.
2. **Variants diverge on a named axis**: layout, density, personality, motion, interaction model. Before building, state each variant's axis in a phrase. Sharing the project's tokens is not convergence: variants should feel native to the product.
3. **Every variant fully works.** Real interactions, real motion, realistic content: product-shaped copy, plausible names and numbers. No lorem ipsum, no dead buttons, no "imagine this part".
4. **The picker is chrome, not a contestant.** The markup, styles, and behavior specified in [references/picker.md](references/picker.md) must be copied verbatim. Its look is not a design decision and never adapts to the project.
5. **Clean up after the choice.** When a winner is promoted, delete the prototype file unless the user asks to keep it.

## Workflow

### Phase 1: Scope

One thing per run. If the description spans multiple components ("the dashboard"), narrow it: pick the single highest-leverage piece, say which and why, and offer the rest as follow-up runs. Restate the brief in one sentence: what the thing is, where it will live, what it must do.

### Phase 2: Recon

Before designing anything, map the ground the variants must stand on:

- Tokens: colors, radii, spacing, fonts, easing and duration variables. Replicate them inline in the harness so every variant looks like it could ship in this product now. If a token can't be replicated offline substitute the closest system font.
- Personality: playful consumer app or crisp dashboard? This bounds how far the boldest variant may go.
- Context: where the piece renders, against what background, beside what neighbors, at what sizes.

If there is no project or no tokens to read, use a restrained default look: neutral grays, one accent, the system font stack.

### Phase 3: Choose directions

Default 3 variants; up to 5 when the design space is wide. More than 5 only if the user asks.

Before writing any code, list the set: a name and an axis for each. Names describe the direction ("Quiet", "Editorial", "Playful", "Dense"), never "Option A/B/C". If two proposed directions would differ only in accent color or copy, they are one direction: replace one with a real alternative (different layout, interaction model, or motion story).

Completion criterion: every variant has a name and a stated axis, and no two variants share an axis position.

### Phase 4: Build the harness

Write one self-contained HTML file: inline CSS and JS, no imports, no build step, no network dependencies, openable directly in a browser. Place it in the temporary directory the current harness designates for scratch files, or the system default temporary directory if the harness specifies none. Never place it inside the current app or repository, not even in a scratch or prototypes folder: it is a throwaway exploration surface, not project code, and it must never appear in the repo or run under the app's dev server. Name it after the piece, like `toast-picker.html`, adding a numeric suffix if the name is taken. Only a request that explicitly names a different location overrides this.

Inside the file, define each variant as a render function returning its markup. Load [references/picker.md](references/picker.md) now and build the picker exactly as specified there, changing only the variant names and count. Beyond the picker, the harness renders one variant at a time, full size, in realistic surrounding context: a toast needs a page behind it, a card needs siblings, a button needs a form. Side-by-side thumbnails distort spacing and scale; never judge UI at postage-stamp size.

Wire variant interactions with event delegation on the stage: the picker re-mounts variants by replacing the stage's contents, and listeners attached inside a variant's markup would not survive that.

Switching is instant, with no transition on the swap. The user flips variants dozens of times per session, and an action that frequent earns no animation.

### Phase 5: Verify and hand off

Open the file in a browser and flip through every variant yourself before showing the user: confirm each renders, every interaction responds, and the console is clean. If browser tooling is available, screenshot each variant.

Then present the set and stop; the choice belongs to the user:

| #   | Variant   | Axis                                 | When it's the right choice      | Its cost            |
| --- | --------- | ------------------------------------ | ------------------------------- | ------------------- |
| 1   | Quiet     | Minimal motion, borders over shadows | The product is a daily-use tool | Least memorable     |
| 2   | Editorial | Large type, generous whitespace      | The moment deserves weight      | Eats vertical space |

Close with the file's path and the keys to flip.

Completion criterion: every variant is reachable from the picker and behaves correctly, the console is clean, and the table names each variant's tradeoff honestly.

### Phase 6: Promote on selection

When the user picks, integrate that variant where it belongs. The prototype is plain HTML and CSS, so promotion includes translation: follow the project's existing conventions for file layout, naming, components, and token usage. Then delete the prototype file per Hard Rule 5. If the user wants another round instead, keep the harness and run Phase 3 again, diverging around the direction they gravitated to.

## Invocations

| Invocation         | Behavior                                                                                         |
| ------------------ | ------------------------------------------------------------------------------------------------ |
| `<description>`    | Full workflow: scope, recon, variants, picker, wait for choice                                   |
| `<description> x5` | Same, with that many variants                                                                    |
| `add <variant>`    | New round: keep the harness, generate a fresh set diverging around the named variant's direction |
| `keep <variant>`   | Promote that variant into the codebase and delete the prototype file                             |

## Tone

Sell each variant honestly: one line on when it wins, one on what it costs. Never pre-pick a favorite in the table. If the user asks which you would choose, answer with a reason rooted in the product's personality and frequency of use, not aesthetics alone. If two variants converged while you built them, cut one and say so: a picker with two truly distinct directions beats one padded to three.
