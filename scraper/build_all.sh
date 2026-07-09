#!/bin/bash
# Compile the app for every device listed in scraper/devices.txt.
# Reports per-device SUCCESS / WARNING / FAIL. Use to smoke-test the fleet
# after changing layout or icons.
set -uo pipefail
cd "$(dirname "$0")/.."

KEY="${1:-developer_key.der}"
JUNGLE="monkey.jungle"
OUT="/tmp/dw_buildall"
mkdir -p "$OUT"

pass=0; warn=0; fail=0
while read -r dev _size; do
  case "$dev" in ""|\#*) continue;; esac
  log="$OUT/$dev.log"
  if monkeyc -o "$OUT/$dev.prg" -d "$dev" -f "$JUNGLE" -y "$KEY" -w >"$log" 2>&1; then
    if grep -q "WARNING" "$log"; then
      echo "WARN   $dev"; warn=$((warn+1))
    else
      echo "OK     $dev"; pass=$((pass+1))
    fi
  else
    echo "FAIL   $dev"; fail=$((fail+1))
    grep -E "ERROR" "$log" | head -2 | sed 's/^/         /'
  fi
done < scraper/devices.txt

echo "-----"
echo "OK=$pass WARN=$warn FAIL=$fail"
