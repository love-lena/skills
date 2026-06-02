#!/usr/bin/env bash
# Composite Supernote handwritten annotations (.pdf.mark sidecar) onto the original
# PDF, producing a single flattened PDF where ink appears on top of the printed
# text. Ink renders black (matches device appearance).
#
# Usage:
#   flatten.sh <name>                       # finds <name>.pdf + .pdf.mark in the sync folder
#   flatten.sh <name> --to <output.pdf>     # explicit output
#   flatten.sh /path/to/src.pdf             # explicit source path (must have sibling .mark)
#
# Auto-builds the supernotelib venv at ~/.cache/manta/.venv on first run.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SKILL_DIR/paths.sh"
VENV="$HOME/.cache/manta/.venv"

if [[ $# -lt 1 ]]; then
  echo "usage: flatten.sh <name-or-path> [--to <output.pdf>]" >&2
  exit 1
fi

INPUT="$1"; shift
OUT_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --to) [[ -n "${2:-}" ]] || { echo "error: --to needs a path" >&2; exit 1; }
          OUT_OVERRIDE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

# Resolve source PDF + mark. Pull from the EXPORT folder by default (where you
# file finished annotations), falling back to the inbox, the device root, then
# a recursive search anywhere under the device root.
if [[ -f "$INPUT" ]]; then
  SRC="$INPUT"
else
  DOC="$(sn_resolve_doc)" || exit 1
  EXPORTS="$DOC/$SN_EXPORTS_SUBPATH"
  INBOX="$DOC/$SN_INBOX_SUBPATH"
  SRC=""
  for cand in \
    "$EXPORTS/$INPUT.pdf" "$EXPORTS/$INPUT" \
    "$INBOX/$INPUT.pdf"   "$INBOX/$INPUT" \
    "$DOC/$INPUT.pdf"     "$DOC/$INPUT"; do
    [[ -f "$cand" ]] && { SRC="$cand"; break; }
  done
  if [[ -z "$SRC" ]]; then
    SRC="$(find "$DOC" -type f \( -name "$INPUT.pdf" -o -name "$INPUT" \) -print -quit 2>/dev/null || true)"
  fi
  [[ -n "$SRC" ]] || {
    echo "can't find source: $INPUT (looked in EXPORT, INBOX, and the device root). If you just finished annotating, export it to the EXPORT folder and wait for Partner.app to sync." >&2
    exit 1
  }
fi

MARK="$SRC.mark"
[[ -f "$MARK" ]] || { echo "no .mark sidecar: $MARK — sync may not be complete yet, or the page hasn't been annotated." >&2; exit 1; }

BASE="$(basename "$SRC" .pdf)"
if [[ -n "$OUT_OVERRIDE" ]]; then
  OUT="$OUT_OVERRIDE"
else
  OUT="$HOME/Downloads/$BASE annotated.pdf"
fi

# Setup venv if missing
if [[ ! -x "$VENV/bin/supernote-tool" ]]; then
  echo "[setup] building venv at $VENV (one-time, ~30s)..." >&2
  mkdir -p "$(dirname "$VENV")"
  PYBIN="$(command -v python3.11 || command -v python3 || true)"
  [[ -n "$PYBIN" ]] || { echo "error: need python3.11 or python3 on PATH to build the venv" >&2; exit 1; }
  "$PYBIN" -m venv "$VENV"
  # Version-agnostic cairo pkgconfig in case a build dep needs it. Homebrew symlinks
  # the active cairo's pkgconfig under <prefix>/lib/pkgconfig, so no version pin.
  PC=""
  command -v brew >/dev/null && PC="$(brew --prefix 2>/dev/null)/lib/pkgconfig"
  PKG_CONFIG_PATH="${PC}${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" \
    "$VENV/bin/pip" install --quiet supernotelib pymupdf
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp "$SRC" "$WORK/src.pdf"
cp "$MARK" "$WORK/src.pdf.mark"

cd "$WORK"
# Emits overlay_<page-index>.png for each annotated page (sparse — unmarked pages absent).
"$VENV/bin/supernote-tool" convert -t png -a --exclude-background src.pdf.mark overlay.png

"$VENV/bin/python" - <<'PY'
import fitz, pathlib, re, sys
doc = fitz.open('src.pdf')
npages = len(doc)
def idx(p): return int(re.search(r'overlay_(\d+)', p.stem).group(1))
overlays = sorted(pathlib.Path('.').glob('overlay_*.png'), key=idx)
if not overlays:
    sys.exit('ERROR: annotation extraction produced no overlay images — check that the '
             '.pdf.mark contains ink and the source .pdf is alongside it.')
# Supernote stores only ANNOTATED pages, in ascending order, with no recoverable
# PDF-page index — so overlay_i maps to PDF page i. This is correct when annotations
# start at page 1 and run contiguously (the usual redline pattern). If non-leading
# pages were annotated, placement shifts earlier; the Opus reading pass catches it.
maxidx = idx(overlays[-1])
if maxidx >= npages:  # device appended pages beyond the source PDF
    print(f'warning: overlay index {maxidx} exceeds the {npages}-page source; appending '
          f'blank page(s) so device-added annotations are not dropped.', file=sys.stderr)
    ref = doc[npages - 1].rect if npages else fitz.paper_rect('letter')
    while len(doc) <= maxidx:
        doc.new_page(width=ref.width, height=ref.height)
# Full-rect insert (no keep_proportion): the device maps the page to fill its screen,
# so stretching the overlay back to the full page rect restores ink alignment.
for p in overlays:
    page = doc[idx(p)]
    page.insert_image(page.rect, filename=str(p), overlay=True)
doc.save('flattened.pdf', garbage=4, deflate=True)
print(f'composited {len(overlays)} annotated page(s); {len(doc)} total pages')
PY

mkdir -p "$(dirname "$OUT")"
cp "$WORK/flattened.pdf" "$OUT"
echo "wrote: $OUT"
