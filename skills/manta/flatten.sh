#!/usr/bin/env bash
# Composite Supernote handwritten annotations (.pdf.mark sidecar) onto the original
# PDF, producing a single flattened PDF where ink appears on top of the printed
# text. Ink renders black (matches device appearance).
#
# Usage:
#   flatten.sh <name>                    # download <name>.pdf + .pdf.mark from the cloud
#   flatten.sh <name> --to <output.pdf>  # explicit output
#   flatten.sh /path/to/src.pdf          # local source path (must have a sibling .mark)
#
# Cloud files are pulled from /EXPORT first (where you file finished annotations),
# then /INBOX (if you annotated in place). Auto-builds the skill venv on first run.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SKILL_DIR/cloud.sh"

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

BASE="$(basename "${INPUT%.pdf}")"
if [[ -n "$OUT_OVERRIDE" ]]; then OUT="$OUT_OVERRIDE"; else OUT="$HOME/Downloads/$BASE annotated.pdf"; fi

sn_ensure_venv || exit 1

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Stage the source PDF + its .mark sidecar into $WORK as src.pdf / src.pdf.mark.
if [[ -f "$INPUT" ]]; then
  [[ -f "$INPUT.mark" ]] || { echo "no .mark sidecar next to: $INPUT" >&2; exit 1; }
  cp "$INPUT" "$WORK/src.pdf"
  cp "$INPUT.mark" "$WORK/src.pdf.mark"
else
  sn_ensure_login || exit 1
  CLI="$(sn_cli)"
  found=""
  for folder in "$SN_EXPORT" "$SN_INBOX"; do
    if "$CLI" cloud download "$folder/$BASE.pdf.mark" "$WORK/src.pdf.mark" >/dev/null 2>&1; then
      "$CLI" cloud download "$folder/$BASE.pdf" "$WORK/src.pdf" >/dev/null 2>&1 || true
      found="$folder"; break
    fi
  done
  [[ -n "$found" && -s "$WORK/src.pdf.mark" ]] || {
    echo "couldn't find '$BASE.pdf.mark' in $SN_EXPORT or $SN_INBOX." >&2
    echo "If you just annotated, file it to EXPORT (or annotate in INBOX) and wait for sync." >&2
    exit 1
  }
  [[ -s "$WORK/src.pdf" ]] || {
    echo "found annotations but not the source '$BASE.pdf' in $found." >&2
    exit 1
  }
fi

cd "$WORK"
# Emits overlay_<page-index>.png for each annotated page (sparse — unmarked pages absent).
"$SN_VENV/bin/supernote-tool" convert -t png -a --exclude-background src.pdf.mark overlay.png

"$SN_VENV/bin/python" - <<'PY'
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
