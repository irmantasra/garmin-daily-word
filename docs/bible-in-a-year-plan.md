# Bible in a Year — architecture plan

## Scope (v1)
A **tracker + prompt**, not a reader. The watch tells you what to read today, you
read it elsewhere (physical Bible / phone), then confirm. No Bible text is
bundled — the full text is too large for a Connect IQ app and renders poorly on a
watch. This app reuses Daily Word's glance+app combo, fetch/cache, JSON parser,
multi-device resources, and LT/EN localization.

## Decisions (locked)
- **Progress model:** both **sequential** and **calendar-locked**, chosen via a setting.
- **Plan data location:** bundled resource inside the app (works offline, no server).
- **Plan choice:** multiple preset plans (2–4), picked via a list menu — no text input.
- **Reading timer:** deferred to phase 2.

## Data model

### Plan files — bundled resources (`resources/plans/*.json`)
Each plan is a flat array of 365 day-entries:
```json
{
  "id": "chronological",
  "name": {"lt": "Chronologinis", "en": "Chronological"},
  "days": [
    { "refs": {"lt": "Pradžios 1–3", "en": "Genesis 1–3"} },
    { "refs": {"lt": "Pradžios 4–7", "en": "Genesis 4–7"} }
  ]
}
```
Ship **2–4 plans** (e.g. Chronological, OT+NT daily, NT-in-a-year, Gospels).
Picked via a `WatchUi.Menu2` list — no text input, works on button-only devices.

### Progress state — `Application.Storage` (survives app updates)
```
selectedPlan   : "chronological"
progressMode   : "sequential" | "calendar"
completedCount : 187            // sequential pointer
completedDays  : "0110…"        // calendar mode, bit-packed per-day done flags
lastReadDate   : "2026-07-11"
streak         : 12
```

## The two progress modes
A settings toggle (`progressMode`), same style as the existing `useLithuanian`
property:
- **Sequential:** today's reading = entry at `completedCount`. Confirm →
  `completedCount++`. Never falls behind; you resume where you stopped.
- **Calendar-locked:** today's reading = day-of-year index. `completedDays[i]`
  tracks which are done; unread past days show as a backlog.

Both modes read from the same plan array — only "which index is today" and "what
confirm does" differ. Isolate this in one helper (`currentDayIndex()` /
`markRead()`) so the two modes stay ~15 lines apart, not two codebases.

## Screens

### Glance (like `DailyWordGlanceView`)
- Line 1: progress — `187 / 365` + a thin progress bar
- Line 2: today's refs — `Genesis 1–3` (or `✓ Done today` after confirming)

### Main app (`View` + `Delegate`, scrollable like `DailyWordView`)
- Icon + progress bar + `Day 188 · 51%`
- Today's references (wrapped, reuse `drawWrapped`)
- Primary action (START/ENTER): **"Mark as read"** → advances, updates streak,
  `requestUpdate`
- Long-press or UP into a **Menu2**: Select plan · Progress mode · Language · Reset progress

## Component map (mostly renamed clones of existing files)
| New file | Based on | Job |
|---|---|---|
| `BibleYearApp.mc` | `DailyWordApp` | glance + initial view wiring |
| `PlanData.mc` | `DailyWordData` | load bundled plan resource, expose today's refs |
| `Progress.mc` | *(new, small)* | storage read/write, mode logic, streak |
| `BibleYearView.mc` | `DailyWordView` | render progress + refs + confirm hint |
| `BibleYearDelegate.mc` | `DailyWordDelegate` | ENTER = mark read, MENU = settings |
| `PlanMenu.mc` | `LanguageMenu` | Menu2 for plan/mode/language/reset |
| `Json.mc` | copy as-is | only needed if fetching; skip if fully bundled |

## Phasing
- **v1:** bundled plans, plan picker, both progress modes, confirm-to-advance,
  progress bar + streak, glance. No network needed at all.
- **v2:** reading timer (start/stop, store elapsed per day, show total time) +
  weekly stats.
- **v3 (optional):** fetch plans from GitHub Pages so plans can be added without a
  store release.

## Open design notes / risks
1. **En-dash rendering** — empty-box glyph bug hit before (commit `cc9f36c`).
   Reference strings like `Genesis 1–3` use `–`; test on real fonts or use `-`.
2. **Bit-packing `completedDays`** — 365 booleans in an array works in Storage, but
   a `"0110…"` string is lighter and easier to migrate.
3. **Plan data authoring** — build a generator script (like the existing
   `scraper/`) to produce the 365-entry JSON per plan rather than hand-writing them.
