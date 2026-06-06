#!/usr/bin/env bash
# Build an editorial reading version of a markdown doc for the Supernote Manta.
#
# Default: a reflowable editorial EPUB (serif body, sans ruled headings, sans
# emphasis, styled quotes/lists/code). Size, line spacing, and margins are set
# on the device (its Display Settings), so reading comfort + annotation room are
# yours to dial there.
#
# --pdf gives the fixed print-redline PDF instead (13pt Georgia, double-spaced,
# 3.5in bottom margin per page) — use it when you specifically want that layout.
#
# Usage:
#   editorial.sh <input.md> [--pdf] [--to-manta | --to <output>]
#
# Default output: ~/Downloads/<name>.epub  (or .pdf with --pdf)
# --to-manta : upload to the cloud /INBOX (the device pulls it on its next sync)
# --to <path>: explicit output path (review locally before sending)
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SKILL_DIR/cloud.sh"

command -v pandoc >/dev/null || { echo "error: pandoc not installed (brew install pandoc)" >&2; exit 1; }

if [[ $# -lt 1 ]]; then
  echo "usage: editorial.sh <input.md> [--pdf] [--to-manta | --to <output>]" >&2
  exit 1
fi
SRC="$1"; shift
[[ -f "$SRC" ]] || { echo "no such file: $SRC" >&2; exit 1; }
BASE="$(basename "$SRC" .md)"

FORMAT="epub"; OUT_MODE="downloads"; OUT_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pdf)      FORMAT="pdf"; shift ;;
    --epub)     FORMAT="epub"; shift ;;
    --to-manta) OUT_MODE="manta"; shift ;;
    --to)       [[ -n "${2:-}" ]] || { echo "error: --to needs a path" >&2; exit 1; }
                OUT_MODE="explicit"; OUT_OVERRIDE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

if [[ "$FORMAT" == "epub" ]]; then
  # Title page: keep pandoc's when the title lives in YAML frontmatter (web
  # clippings); suppress it when the title is a body '# ' heading (ADRs, plain
  # md) so it doesn't render as an "UNTITLED" page or duplicate the heading.
  TP_FLAG=""
  if ! awk 'NR==1 && $0!="---"{exit 1} /^---$/{c++} c==1 && /^title:/{f=1} c>=2{exit} END{exit !f}' "$SRC"; then
    TP_FLAG="--epub-title-page=false"
  fi
  # TP_FLAG is a single space-free flag (or empty); unquoted expansion is safe and
  # avoids bash 3.2 + `set -u` empty-array errors.
  pandoc "$SRC" --css "$SKILL_DIR/epub.css" $TP_FLAG -o "$WORK/out.epub"
  PRODUCT="$WORK/out.epub"
else
  # Fixed editorial redline PDF, rendered headless via a Chrome-family browser.
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
  [[ -n "$CHROME" ]] || { echo "error: no Chrome/Chromium-family browser found (needed for the --pdf redline render)" >&2; exit 1; }
  pandoc "$SRC" -f markdown -t html -o "$WORK/out.html" -H "$SKILL_DIR/editorial.css"
  "$CHROME" --headless --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$WORK/out.pdf" "file://$WORK/out.html" 2>&1 | tail -1
  [[ -s "$WORK/out.pdf" ]] || { echo "error: PDF render produced no output (browser: $CHROME)" >&2; exit 1; }
  PRODUCT="$WORK/out.pdf"
fi

case "$OUT_MODE" in
  manta)
    sn_ensure_venv || exit 1
    sn_ensure_login || exit 1
    "$(sn_cli)" cloud upload "$PRODUCT" "$SN_INBOX/$BASE.$FORMAT"
    echo "uploaded: $SN_INBOX/$BASE.$FORMAT (the device pulls it on its next sync)" ;;
  explicit)
    mkdir -p "$(dirname "$OUT_OVERRIDE")"; cp "$PRODUCT" "$OUT_OVERRIDE"; echo "wrote: $OUT_OVERRIDE" ;;
  downloads)
    OUT="$HOME/Downloads/$BASE.$FORMAT"; mkdir -p "$(dirname "$OUT")"; cp "$PRODUCT" "$OUT"; echo "wrote: $OUT" ;;
esac
