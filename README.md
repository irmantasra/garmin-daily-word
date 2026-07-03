# Garmin Daily Word

A Garmin Connect IQ **glance** that shows today's Catholic Mass reading
references (First reading · Psalm · Gospel) plus one short scripture line,
in **Lithuanian** or **English**.

Because a watch glance can't parse HTML (and the LT source is
`windows-1257`), the data pipeline is split:

```
  katalikai.lt (LT) ─┐
                      ├─► scraper/scrape.py ─► docs/data/YYYY-MM-DD.json ─► GitHub Pages ─► watch glance
  bible.usccb.org (EN)┘        (daily GitHub Action)
```

## Components

| Path | What it is |
|------|-----------|
| `scraper/scrape.py` | Scrapes both sources → compact JSON. No dependencies (stdlib only). |
| `.github/workflows/daily.yml` | Cron (05:10 UTC) runs the scraper, commits `docs/data/`. |
| `docs/data/` | Published JSON, served by GitHub Pages. |
| `source/` | Monkey C glance app. |
| `resources/` | Strings, properties, settings, launcher icon. |
| `manifest.xml`, `monkey.jungle` | Connect IQ build config. |

## Data format

`docs/data/2026-07-03.json`:

```json
{
  "date": "2026-07-03",
  "lt": { "reading1": "Ef 2, 19-22", "psalm": "Ps 116, 1-2",
          "gospel": "Jn 20, 24-29", "line": "Palaiminti, kurie tiki nematę!" },
  "en": { "reading1": "Ephesians 2:19-22", "psalm": "Psalm 117:1bc, 2",
          "gospel": "John 20:24-29", "line": "Blessed are those who have not seen and have believed." }
}
```

`today.json` is always the latest day (handy fallback).

## Setup

### 1. Publish the data

1. Push this repo to GitHub.
2. Settings → Pages → Source: **Deploy from a branch**, branch `main`, folder `/docs`.
3. Your data URL becomes: `https://<user>.github.io/<repo>/data`
4. Run the workflow once manually (Actions → *Scrape daily readings* → Run workflow).

### 2. Point the app at your data

Edit the default in two places (or set it in Garmin Connect app settings after install):

- `resources/properties.xml` → `dataBaseUrl`
- Or leave default and override per-user via the phone app settings screen.

### 3. Build & run

```bash
# One-time: generate a developer key (do NOT commit it)
openssl genrsa -out developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt

# Compile for Forerunner 255
monkeyc -o bin/DailyWord.prg -d fr255 -f monkey.jungle -y developer_key.der -w

# Run in the simulator
connectiq            # starts the simulator
monkeydo bin/DailyWord.prg fr255
```

To add more watch models, add `<iq:product>` entries in `manifest.xml`.

## Settings (in Garmin Connect phone app)

- **Lithuanian (off = English)** — language toggle.
- **Data base URL** — where the glance fetches JSON.

## Notes / caveats

- USCCB is behind a CDN that rate-limits aggressive scraping; the workflow
  fetches once/day from GitHub's runners, which is fine. Local repeated runs
  may hit `403` temporarily.
- The "daily line" is the closing sentence of the Gospel — a pragmatic choice
  since neither source has a dedicated verse-of-the-day.
- Reading references are the *citations* (book chapter:verse), not full text,
  to keep the glance readable and the payload tiny.
