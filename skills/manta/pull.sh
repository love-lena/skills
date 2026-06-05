#!/usr/bin/env bash
# Pull an annotated document back from the Supernote cloud into ~/Downloads.
#
# Prefers a device "Export to PDF": that produces a *flattened* PDF in /EXPORT
# with the ink already baked in (no .pdf.mark sidecar) — so we just download it.
# Falls back to flatten.sh (composite the .pdf.mark sidecar onto the original)
# when the document was annotated in place, which is detected by the presence of
# a `<name>.pdf.mark` — in that case the matching `<name>.pdf` is the un-inked
# original and must be composited, not grabbed.
#
# Usage:
#   pull.sh <name> [--to <output.pdf>]
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SKILL_DIR/cloud.sh"

[[ $# -ge 1 ]] || { echo "usage: pull.sh <name> [--to <output.pdf>]" >&2; exit 1; }
NAME="$1"; shift
OUT_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --to) [[ -n "${2:-}" ]] || { echo "error: --to needs a path" >&2; exit 1; }
          OUT_OVERRIDE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

BASE="$(basename "${NAME%.pdf}")"
OUT="${OUT_OVERRIDE:-$HOME/Downloads/$BASE annotated.pdf}"

sn_ensure_venv || exit 1
sn_ensure_login || exit 1
CLI="$(sn_cli)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

run_flatten() {
  if [[ -n "$OUT_OVERRIDE" ]]; then
    exec "$SKILL_DIR/flatten.sh" "$BASE" --to "$OUT_OVERRIDE"
  fi
  exec "$SKILL_DIR/flatten.sh" "$BASE"
}

# Search /EXPORT (where finished work lands) first, then /INBOX (annotate in place).
for folder in "$SN_EXPORT" "$SN_INBOX"; do
  # A sidecar here means the .pdf is an un-inked original → composite it.
  if "$CLI" cloud download "$folder/$BASE.pdf.mark" "$TMP/probe.mark" >/dev/null 2>&1; then
    echo "found '$BASE.pdf.mark' in $folder — compositing annotations (flatten)" >&2
    run_flatten
  fi
  # No sidecar but a PDF here → a flattened device export; grab it directly.
  if "$CLI" cloud download "$folder/$BASE.pdf" "$TMP/src.pdf" >/dev/null 2>&1; then
    mkdir -p "$(dirname "$OUT")"
    cp "$TMP/src.pdf" "$OUT"
    echo "grabbed flattened export from $folder"
    echo "wrote: $OUT"
    exit 0
  fi
done

echo "couldn't find '$BASE' in $SN_EXPORT or $SN_INBOX (no flattened export, no .pdf.mark)." >&2
echo "If you just finished on the device, Export it to PDF (or wait for sync) and retry." >&2
exit 1
