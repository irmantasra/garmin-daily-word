#!/usr/bin/env python3
"""Scrape Catholic daily Mass reading references (LT + EN) into a compact JSON.

LT source: https://lk.katalikai.lt/_dls/ss/ss_MMDD.html   (windows-1257)
EN source: https://bible.usccb.org/bible/readings/MMDDYY.cfm (utf-8)

Output (data/YYYY-MM-DD.json):
{
  "date": "2026-07-03",
  "lt": {"reading1": "Ef 2, 19-22", "psalm": "Ps 116, 1-2",
          "gospel": "Jn 20, 24-29", "line": "..."},
  "en": {"reading1": "Ephesians 2:19-22", "psalm": "Psalm 117:1bc, 2",
          "gospel": "John 20:24-29", "line": "..."}
}
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
import time
import urllib.error
import urllib.request
from html import unescape
from pathlib import Path

UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/125.0 Safari/537.36"
)
LT_BASE = "https://lk.katalikai.lt"
LT_INDEX = LT_BASE + "/{yyyy}/{mm}/{dd}"
EN_URL = "https://bible.usccb.org/bible/readings/{mmddyy}.cfm"


def fetch(url: str, encoding: str) -> str:
    headers = {
        "User-Agent": UA,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9,lt;q=0.8",
    }
    req = urllib.request.Request(url, headers=headers)
    last: Exception | None = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return resp.read().decode(encoding, errors="replace")
        except urllib.error.HTTPError as e:
            last = e
            if e.code in (403, 429, 503) and attempt < 2:
                time.sleep(2 * (attempt + 1))
                continue
            raise
    raise last  # pragma: no cover


def strip_tags(s: str) -> str:
    return re.sub(r"\s+", " ", unescape(re.sub(r"<[^>]+>", " ", s))).strip()


def norm_ref(ref: str) -> str:
    """katalikai uses '.' as verse separator: 'Ef 2, 19.22' -> 'Ef 2, 19-22'."""
    ref = ref.strip()
    ref = re.sub(r"(\d)\.(\d)", r"\1-\2", ref)
    ref = ref.replace("–", "-").replace("—", "-")  # en/em dash -> hyphen
    return re.sub(r"\s+", " ", ref)


def clean_line(s: str) -> str:
    """Trim stray quote glyphs the sources wrap sentences in."""
    return s.strip(" “”„“\"'‟").strip()


# --- Lithuanian -------------------------------------------------------------

# The daily index page links to that day's readings, e.g.
#   /_dls/ss/ss_0703.html      (Sundays / feasts)
#   /_dls/e2/e2_14eil_1.html   (weekdays, by liturgical cycle)
# The bare ss_MMDD.html guess only works for some days, so we resolve the
# real link from the index instead.
LT_LINK = re.compile(r'href="(/_dls/[^"]+\.html)"', re.IGNORECASE)


def resolve_lt_url(date: dt.date) -> str:
    index = LT_INDEX.format(
        yyyy=date.strftime("%Y"), mm=date.strftime("%m"), dd=date.strftime("%d")
    )
    html = fetch(index, "windows-1257")
    for path in LT_LINK.findall(html):
        if "ivadas" in path.lower():  # skip the "readings order / intro" link
            continue
        return LT_BASE + path
    raise ValueError("no readings link on index page " + index)


# <p class="rubrika">Pirmasis skaitinys (Ef 2, 19.22) ...
LT_RUBRIC = re.compile(
    r'class="rubrika"[^>]*>\s*([^(<]+?)\s*\(([^)]+)\)', re.IGNORECASE
)

# Header spans naming the liturgical day/feast, e.g.
#   <span class="savaites_nr"> XIV eilinė savaitė</span>
#   <span class="savaites_d"> Pirmadienis</span>
#   <span class="iskilme">šv. apaštalas Tomas (F)</span>
LT_EVENT = re.compile(
    r'class="(savaites_nr|savaites_d|iskilme)"[^>]*>([^<]+)', re.IGNORECASE
)


def parse_lt_event(html: str) -> str:
    parts = []
    for _cls, text in LT_EVENT.findall(html):
        t = re.sub(r"\s+", " ", unescape(text)).strip()
        if t and t not in parts:
            parts.append(t)
    return ", ".join(parts)


def parse_lt(html: str) -> dict:
    out: dict[str, str] = {}
    event = parse_lt_event(html)
    if event:
        out["event"] = event
    for label, ref in LT_RUBRIC.findall(html):
        label = label.lower()
        ref = norm_ref(ref)
        if "pirmasis" in label or "skaitinys" in label and "reading1" not in out:
            out.setdefault("reading1", ref)
        if "psalm" in label:
            out["psalm"] = ref
        if "evangelija" in label:
            out["gospel"] = ref
    # Daily line: last sentence of the gospel block (after the final <br>).
    body = html.split('class="rubrika">Evangelija', 1)
    if len(body) == 2:
        text = strip_tags(body[1])
        # take the closing sentence(s) inside quotes if present, else last sentence
        sentences = re.split(r"(?<=[.!?])\s+", text)
        tail = [s for s in sentences if s][-1:] or [""]
        out["line"] = clean_line(tail[0])[:180]
    return out


# --- English (USCCB) --------------------------------------------------------

EN_BLOCK = re.compile(
    r'<h3[^>]*class="name"[^>]*>(.*?)</h3>.*?class="address"[^>]*>(.*?)</',
    re.IGNORECASE | re.DOTALL,
)


def parse_en(html: str) -> dict:
    out: dict[str, str] = {}
    m = re.search(r"<title>(.*?)</title>", html, re.IGNORECASE | re.DOTALL)
    if m:
        title = strip_tags(m.group(1))
        title = re.sub(r"\s*\|\s*USCCB\s*$", "", title).strip()
        if title:
            out["event"] = title
    for name, addr in EN_BLOCK.findall(html):
        name = strip_tags(name).lower()
        addr = strip_tags(addr)
        if name.startswith("reading 1") or name == "reading i":
            out["reading1"] = addr
        elif name.startswith("reading 2") or name == "reading ii":
            out["reading2"] = addr
        elif "responsorial psalm" in name:
            out["psalm"] = addr
        elif name == "gospel":
            out["gospel"] = addr
    # Daily line: closing sentence of the Gospel body.
    tail = html[html.lower().rfind("gospel"):]
    m = re.search(r'class="content-body"[^>]*>(.*?)</div>', tail, re.DOTALL)
    if m:
        text = strip_tags(m.group(1))
        sentences = re.split(r"(?<=[.!?])\s+", text)
        sentences = [s for s in sentences if s]
        if sentences:
            out["line"] = clean_line(sentences[-1])[:180]
    return out


def scrape(date: dt.date) -> dict:
    mmddyy = date.strftime("%m%d%y")
    result: dict = {"date": date.isoformat()}
    try:
        result["lt"] = parse_lt(fetch(resolve_lt_url(date), "windows-1257"))
    except Exception as e:  # noqa: BLE001 - record failure, keep other lang
        result["lt"] = {"error": str(e)}
    try:
        result["en"] = parse_en(fetch(EN_URL.format(mmddyy=mmddyy), "utf-8"))
    except Exception as e:  # noqa: BLE001
        result["en"] = {"error": str(e)}
    return result


def main() -> int:
    p = argparse.ArgumentParser(description="Scrape daily Mass reading refs.")
    p.add_argument("--date", help="YYYY-MM-DD (default: today)")
    p.add_argument("--out", default="data", help="output directory")
    p.add_argument("--stdout", action="store_true", help="print instead of writing")
    args = p.parse_args()

    date = dt.date.fromisoformat(args.date) if args.date else dt.date.today()
    data = scrape(date)
    text = json.dumps(data, ensure_ascii=False, indent=2)

    if args.stdout:
        print(text)
        return 0

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / f"{date.isoformat()}.json").write_text(text + "\n", encoding="utf-8")
    (out_dir / "today.json").write_text(text + "\n", encoding="utf-8")
    print(f"wrote {out_dir}/{date.isoformat()}.json", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
