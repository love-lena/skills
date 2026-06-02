#!/usr/bin/env bash
# Build an editorial-format PDF from a markdown source. 13pt Georgia, double-spaced,
# 3.5in bottom margin per page. Sized for redlining on the Supernote Manta.
#
# Usage:
#   editorial.sh <input.md> [--to-manta | --to <output.pdf>]
#
# Default output: ~/Downloads/<basename> - PRINT EDITORIAL.pdf
# --to-manta:   drop into the device send inbox (Document/INBOX/For Review, created if missing).
# --to <path>:  explicit output path (good for reviewing locally before sending).
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSS="$SKILL_DIR/editorial.css"
source "$SKILL_DIR/paths.sh"

command -v pandoc >/dev/null || { echo "error: pandoc not installed (brew install pandoc)" >&2; exit 1; }

if [[ $# -lt 1 ]]; then
  echo "usage: editorial.sh <input.md> [--to-manta | --to <output.pdf>]" >&2
  exit 1
fi

SRC="$1"; shift
[[ -f "$SRC" ]] || { echo "no such file: $SRC" >&2; exit 1; }
BASE="$(basename "$SRC" .md)"

OUT_MODE="downloads"
OUT_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --to-manta) OUT_MODE="manta"; shift ;;
    --to)       [[ -n "${2:-}" ]] || { echo "error: --to needs a path" >&2; exit 1; }
                OUT_MODE="explicit"; OUT_OVERRIDE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$OUT_MODE" in
  manta)     INBOX="$(sn_resolve_inbox)" || exit 1; OUT="$INBOX/$BASE - PRINT EDITORIAL.pdf" ;;
  explicit)  OUT="$OUT_OVERRIDE" ;;
  downloads) OUT="$HOME/Downloads/$BASE - PRINT EDITORIAL.pdf" ;;
esac

# Find a Chrome/Chromium-family browser for headless PDF rendering.
CHROME=""
for c in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium" \
  "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
  "$(command -v google-chrome-stable 2>/dev/null || true)" \
  "$(command -v chromium 2>/dev/null || true)"; do
  if [[ -n "$c" && -x "$c" ]]; then CHROME="$c"; break; fi
done
[[ -n "$CHROME" ]] || { echo "error: no Chrome/Chromium-family browser found (needed for headless PDF rendering)" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pandoc "$SRC" -f markdown -t html -o "$WORK/out.html" -H "$CSS"
"$CHROME" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$WORK/out.pdf" "file://$WORK/out.html" 2>&1 | tail -1
[[ -s "$WORK/out.pdf" ]] || { echo "error: PDF render produced no output (browser: $CHROME)" >&2; exit 1; }

mkdir -p "$(dirname "$OUT")"
cp "$WORK/out.pdf" "$OUT"
echo "wrote: $OUT"
