# Connect IQ Store submission guide

Everything needed to publish **Daily Word** to the Connect IQ Store.

## 1. The package to upload

Build the release package (already done — regenerate anytime):

```bash
monkeyc -e -r -o bin/DailyWord.iq -f monkey.jungle -y developer_key.der -w
```

Upload **`bin/DailyWord.iq`** (≈1.25 MB, covers all 64 supported devices).

> Keep `developer_key.der` safe and back it up. Every future update **must**
> be signed with the same key or the store will reject it as a different app.

## 2. Where to upload

1. Go to <https://apps.garmin.com/en-US/developer/dashboard>
2. Sign in with your Garmin developer account.
3. **Upload an App** → select `bin/DailyWord.iq`.

## 3. Listing copy

**App name:** Daily Word

**Category:** Widgets

**Short description (1 line):**
> Today's Catholic Mass reading references at a glance, in Lithuanian or English.

**Full description:**
> Daily Word shows the day's Catholic Mass reading references — First Reading,
> Psalm, and Gospel — right in your watch's glance carousel. Open the app for
> the full list plus the liturgical day or feast.
>
> • Glance shows the day's Gospel reference at a glance.
> • Full view lists all readings with the liturgical event.
> • Switch between Lithuanian (LT) and English (EN) in the app or in the
>   Connect IQ app settings.
> • Updates automatically each day.
>
> Reading references are sourced from public liturgical calendars
> (lk.katalikai.lt for Lithuanian, bible.usccb.org for English).
>
> Not affiliated with Garmin, the USCCB, or Katalikai.lt.

**Permissions to explain (Communications):**
> The app downloads a small public JSON file with the day's reading references.
> No personal data is collected or transmitted.

**Privacy policy URL:**
> https://irmantasra.github.io/garmin-daily-word/privacy.html

## 4. Screenshots (required)

Garmin requires at least one screenshot per listing. Capture from the
simulator (device screen only, not the whole window):

- Glance view (icon + Gospel reference)
- Full readings view
- Language menu (optional)

Recommended: one from a round device (e.g. fr965) and one from an
AMOLED/rectangular device (e.g. venux1).

## 5. Review notes

- **Supported devices:** 64 watches (see DEVICES.md). 16 older models
  (API < 3.5) run as a full app without the glance — this is expected.
- **Data source:** static JSON on GitHub Pages, refreshed daily by a GitHub
  Action. No backend server.
