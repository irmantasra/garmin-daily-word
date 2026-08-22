# Prayer Tree — architecture plan

A colorful, pixel-art Christian prayer tracker. Every logged prayer grows a tree;
finished days plant into a forest that fills up over time. Reuses Daily Word's
glance+app combo, `Application.Storage` persistence, multi-device resources, and
LT/EN localization.

## Decisions (locked)
- **Metaphor:** one growing foreground tree **+** a forest that accumulates behind it.
- **Rendering:** procedural pixels (virtual low-res grid scaled to any screen).
- **Logging:** one-tap "I prayed" (+1 growth); prayer types deferred to a later version.
- **Decay:** grow-only — growth is never lost; the tree visually "thirsts" after a
  lapse and perks up on return.

## Core metaphor & reward loop
- **Foreground tree** = *today*. Each tap grows today's tree through stages.
- At day rollover, today's tree is "planted" into the **forest** (background) and a
  fresh sapling starts for the new day.
- The forest fills left-to-right / back-to-front over weeks and months — the
  long-term arc, viewable by scrolling/zooming out.
- **Thirst, not decay:** growth is permanent. After a missed day the tree droops
  and colors dull; the next prayer perks it back up. Encouraging, fits "faith,"
  still nudges the habit.

## Rendering: procedural pixels
A `PixelCanvas` helper maps a virtual grid (e.g. 32×32 or 48×48 "pixels") to
`dc.fillRectangle` calls, with `cell = min(screenW, screenH) / gridSize`.
- One code path renders on all ~60 devices — no per-resolution sprite re-exports.
- Tiny memory footprint; colorful is just palette choice.
- Growth = revealing more cells (trunk height, branch spread, leaf/blossom count).
- Animatable: interpolate revealed-cell count between frames for a "growing" pop.

Palette: warm sky gradient, brown trunk, layered greens, seasonal accent colors
(blossoms pink, fruit red/gold). Keep to ~8–12 colors for a clean pixel look.

## Growth model
```
prayersToday      : Number      // taps today -> foreground tree stage
totalPrayers      : Number      // lifetime, never decreases
forest            : [ {day:"2026-07-11", stage:5}, … ]  // planted past days
lastPrayerDate    : "2026-07-11"
streak            : Number
thirsting         : Boolean     // derived: today > lastPrayerDate + 1
```
Growth stages for the foreground tree (mapped from `prayersToday`):
`seed → sprout → sapling → young tree → full tree → blossoming → fruit`.
Each stage reveals more of the pixel grid; extra taps past the last stage add
blossoms/fruit rather than height (so it never "maxes out" flatly).

## Screens

### Glance (like `DailyWordGlanceView`)
- Tiny pixel tree at current stage + `🙏 3 today · 7-day streak`.

### Main app (`View` + `Delegate`)
- Full pixel scene: sky, foreground tree, forest behind.
- Stats line: `today · streak · total`.
- Primary action (START/ENTER): **"I prayed"** → +1 growth, grow animation,
  update streak, `requestUpdate`.
- UP / long-press → **Menu2**: View forest · Language · Reset garden.
- Optional: DOWN zooms out to the full forest view.

## Component map (based on existing files)
| New file | Based on | Job |
|---|---|---|
| `PrayerApp.mc` | `DailyWordApp` | glance + initial view wiring |
| `Garden.mc` | *(new, small)* | storage read/write, growth/stage logic, streak, thirst |
| `PixelCanvas.mc` | *(new)* | virtual grid → `fillRectangle`, palette, scaling |
| `TreeSprite.mc` | *(new)* | maps growth stage → set of lit cells (tree shape) |
| `PrayerView.mc` | `DailyWordView` | render scene, handle grow animation |
| `PrayerDelegate.mc` | `DailyWordDelegate` | ENTER = log prayer, MENU = settings, DOWN = forest |
| `GardenMenu.mc` | `LanguageMenu` | Menu2 for forest/language/reset |

## Phasing
- **v1:** foreground tree with stages, one-tap logging, streak + thirst, glance,
  procedural rendering, basic forest.
- **v2:** prayer types (thanks / ask / confess / praise) → different colored
  branches or flowers; richer forest zoom/scroll.
- **v3 (optional):** timed prayer sessions (start/stop, growth ∝ minutes); seasons
  (tree changes with real month); shareable forest screenshot.

## Open design notes / risks
1. **Animation cost** — Garmin redraws are not free. Keep grow animations short
   (a few frames) and only when the view is active; don't animate in the glance.
2. **Forest growth unbounded** — cap the stored forest array (e.g. last 90 days) or
   summarize older days into a denser "distant forest" band so Storage/render stay small.
3. **Grid size vs. small screens** — test the virtual grid on the smallest device
   (e.g. instinct2s / fr55) so the tree stays legible; may need a smaller grid there.
4. **Color on MIP vs AMOLED** — pick a palette that reads well on both memory-in-pixel
   and AMOLED devices; verify contrast in the simulator.
