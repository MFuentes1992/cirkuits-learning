# Level Select — Design Concepts

**Status:** Draft for review
**Date:** 2026-07-24
**Scope:** Visual + interaction concepts for a new `LevelSelectScene`, sitting between `MenuScene` and `CountDownScene`.

---

## 1. Style audit — what we must adhere to

Derived from `IgniterPalette.swift`, `MenuScene.swift`, `GameOver.swift`, `ProgressDotsView.swift`, `screen-assets/`, and the Igniter Compendium reference frames.

### Colour

| Role | Token | Hex |
|---|---|---|
| Light surface (primary) | `cream` | `#FFF4CF` |
| Light surface pattern lines | `creamPattern` | `#FCE9B8` |
| Dark surface | `navy` | `#1D1C3C` |
| Dark surface pattern lines | `navyPattern` | `#27286F` |
| Ink / text on light | `navyInk` | `#363851` |
| Primary accent (CTA, score, dots) | `pink` | `#FD6D7D` |
| Success / positive | `teal` | `#2DDFD0` |
| Secondary accent | `bracketYellow` | `#FBC629` |
| Progression ramp (5 steps) | `streakBars` | magenta `#CF6ED8` → lavender `#9376E4` → blue `#02B9F2` → teal `#2DDFD0` → lime `#D1F267` |

The game has exactly **two canvases**: cream (early / calm) and navy (late / intense) — see Compendium frames 1 vs 5. Level select should pick one and commit; **cream** is the right call, since it reads as "lobby / between rounds" and the navy is earned by being in a hot streak.

### Type

- `.system(design: .rounded)`, weights `.bold` / `.heavy` only. No light or regular weights anywhere in the product.
- Numerals are large, `%03d`-padded, and treated as graphics (score `108pt`, "TIME'S UP" `52pt`).
- Labels are short, uppercase, tracked `+1` (`MAX STREAK`, `STREAK`, `Best`).
- The `IGNITER` logo wordmark is a stencilled/chamfered display face — **do not** try to reproduce it with system font. Use the PNG asset when the wordmark is needed.

### Shape & surface

- Rounded rects, corner radius **14** (GameOver buttons, Best pill). Circles for icon buttons (mic, pause, back, medal — 62pt diameter on menu).
- Flat fills, **no gradients on surfaces**. The only gradient-like element is the discrete 5-step streak funnel.
- Chamfered / parallelogram silhouettes for progression bars (`ParallelogramBar`).
- Offset outline stacks (the "Nice!" checkmark: cyan/purple/lime/blue outlines offset behind a teal solid) — the signature "sticker" treatment.
- Full-bleed generative pattern behind everything (`IgniterCBG` swirl), always low-contrast against its own base.
- Zigzag banding + scrolling `IGNITER///` ticker at the bottom edge (`Igniter_BGP1/2/3`).

### Motion

- Entrance: `.spring(response: 0.55–0.6, dampingFraction: 0.7)`, staggered, `scaleEffect 0.6 → 1` + `opacity 0 → 1`.
- Press: `scaleEffect 0.85`, `.spring(response: 0.3, dampingFraction: 0.45)` — bouncy, overshoots.
- Ambient: infinite `repeatForever` loops — ripples (1.8s easeOut), arrow nudge (0.75s easeInOut autoreverse), ticker (9s linear).
- Every interactive element has an idle animation. Nothing on screen is fully static.

### Existing hooks

- `GameScenes` enum needs a `.LevelSelect` case; `SceneManager.setCurrentScene` already routes by enum.
- `LevelConfig` (`timeToLive`, `timeToAnswer`, `levelDuration`, `lives`, `levelCountDown`, `stage`) is the payload each level card selects. Currently hardcoded in `SceneManager` — level select is the natural place to source it.
- `MenuScene` already renders `Igniter_LeftArrow` / `Igniter_RightArrow` flanking Play, commented *"decorative for now — there is no stage selection yet."* **Those arrows are the intended entry point.** Concept A honours that literally.

---

## 2. Concept A — "Stage Carousel" *(recommended)*

**One level fills the screen at a time; the menu arrows page between them.**

### Layout (top → bottom)

1. **Progress dots** — reuse `ProgressDotsView`, one dot per level, current level filled pink, locked levels at 35% alpha. Directly reuses an existing component and matches the Compendium header exactly.
2. **Stage card** — large cream card, radius 14, on the swirl background, held between yellow + pink brackets *(the `((HE))` bracket motif from the in-game word display, reused as a frame)*. Card contains:
   - `STAGE 01` — heavy rounded, tracked, navyInk
   - Level name — e.g. `FIRST SPARKS`
   - The level's difficulty read as a **5-step streak funnel** rendered in `streakBars`, filled to the level's difficulty (1–5 bars). Reuses `ParallelogramStack`.
   - `BEST 042` in a teal pill (radius 14) — the exact `Best` treatment from GameOver.
3. **Left / right arrows** flanking the card, using `Igniter_LeftArrow` / `Igniter_RightArrow`, keeping their existing ±7pt nudge loop. Arrow dims to 30% at the ends of the list.
4. **Play button** — `Igniter_Play` asset, unchanged.
5. **Bottom decoration** — `BottomDecoration` reused verbatim.

### Locked state

Locked cards render the card fill in `creamPattern` instead of `cream`, name replaced with `????`, and the Play button swaps to a pink `LOCKED` pill. Tapping it shakes the card (±8pt, 0.25s) and pulses a one-line requirement: `Clear Stage 02 to unlock`.

### Why this one

- Zero new visual vocabulary — every element already exists in the codebase.
- Completes an interaction the menu already advertises.
- One level on screen means the difficulty funnel and best score can be shown at full sticker scale, which is where this art style is strongest.
- Cheapest to build: it's the menu with a swapped centre section.

### Cost

Small. New `LevelSelectScene` + `LevelSelectView`, reusing `ProgressDotsView`, `ParallelogramStack`, `BottomDecoration`, and the arrow/play assets.

---

## 3. Concept B — "Ignition Trail"

**A vertical path of stage nodes that visually catches fire as you progress.**

### Layout

- Full-screen vertical scroll on cream. A thick pink line runs bottom → top connecting circular stage nodes, alternating left/right of centre.
- **Node states:**
  - *Locked* — hollow circle, 4pt pink stroke at 35%, cream fill, no number.
  - *Unlocked* — solid pink circle, cream numeral, the `12`-in-a-circle score treatment from the Compendium HUD.
  - *Cleared* — the offset-outline "Nice!" checkmark sticker, scaled down to node size (teal solid + cyan/purple/lime offsets).
  - *Current* — pink circle with the menu's ripple rings pulsing outward (1.8s easeOut, staggered pair), plus a small `x03` white satellite badge showing stars/medals earned.
- The connecting line is **cream/pattern-coloured ahead of you and pink behind you** — the trail literally ignites as you clear stages.
- Scroll position past the last cleared node reveals the pixel-fire band (`fireRamp`) creeping up from the bottom edge, echoing the streak-fire in Compendium frame 5.
- Selecting a node expands it into a compact detail sheet: name, difficulty funnel, `BEST 042` teal pill, `PLAY`.

### Why consider it

- Scales gracefully to 20+ levels; Concept A gets tedious past ~8.
- Gives the game a sense of a journey and makes progression legible at a glance — strong for an educational product where parents/teachers want to see progress.
- Reuses the fire, checkmark, and ripple motifs in a new context without inventing anything.

### Cost

Medium. New scroll layout, node state machine, detail sheet. The fire band is the only genuinely new drawing work (pixel ramp already specified in `IgniterPalette.fireRamp`).

---

## 4. Concept C — "Compendium Grid"

**A 2-column grid of stage tiles, styled as pages of the Igniter Compendium.**

### Layout

- Navy background with `navyPattern` swirl — the one concept that uses the dark canvas, framing level select as the "index" of the book.
- Tiles are cream rounded rects (radius 14) in a 2-up grid, each with a slight rotation (±1.5°) so the grid reads as scattered cards, not a spreadsheet.
- Each tile: big `%02d` stage numeral in navyInk, level name below, a 5-dot difficulty row in `pink`, and a corner ribbon in the level's `streakBars` colour — so stage 1 is magenta, stage 2 lavender, and so on down the ramp. Gives the grid a rainbow rhythm without gradients.
- Cleared tiles get a small teal checkmark sticker in the top-right, overhanging the tile edge.
- Locked tiles drop to `navyPattern` fill with a cream padlock glyph, no rotation.
- Header: `SELECT STAGE` in heavy rounded cream, with the `Igniter_Back` circle button top-left.
- Tap: tile scales to 0.85 then springs, then transitions.

### Why consider it

- Densest — shows 8–10 levels without scrolling. Best if levels are meant to be freely replayable rather than strictly sequential.
- Strongest "collection" feeling; pairs well with a future medal/achievement system (the `Igniter_Medal` button is already sitting unused on the menu).

### Risks

- Dark canvas conflicts with the current menu's cream, so the menu → select transition gets a full value flip. Either accept it as a deliberate beat or move this to cream.
- Tile rotation is a new convention; keep it subtle or drop it.

### Cost

Medium. New grid, tile component, lock/clear states, plus a navy background variant of the pattern asset.

---

## 5. Recommendation

Ship **Concept A** first. It closes a loop the menu already promises, introduces no new visual language, and reuses four existing components — so it can land quickly and prove out the `LevelConfig`-per-level plumbing.

Once level count grows past ~8, migrate to **Concept B**. It's the natural next step and reuses everything A establishes (difficulty funnel, best pill, lock rules) inside a structure that scales.

Hold **Concept C** for a future replay/medal mode, where a browsable grid earns its density.

---

## 6. Open questions

1. **How many levels at launch?** Under 8 → A is clearly right. Over 15 → skip straight to B.
2. **Strictly sequential, or free replay?** Sequential favours A/B; free replay favours C.
3. **What varies per level?** `LevelConfig` exposes five knobs. Does difficulty mean less time, fewer lives, or a harder word set? The difficulty funnel needs one honest number behind it, not a vibe.
4. **Is progress persisted?** `GameState` currently holds `HighScore` in memory only. Per-level bests and unlock state need storage before any of these concepts is truthful.
5. **Does the `Igniter_Medal` button lead anywhere?** If a medal screen is coming, C's collection framing may be worth reserving for it.
6. **Does level select replace the menu's Play, or sit behind it?** Concept A implies replacing it (arrows become live). B and C imply Play → Level Select → Countdown.
