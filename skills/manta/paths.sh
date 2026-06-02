#!/usr/bin/env bash
# Shared path resolution for the manta skill. Sourced by editorial.sh and flatten.sh.
#
# Provides sn_resolve_doc, which prints the Supernote Partner.app device sync
# root (the `.../Supernote` folder). The numeric path segment under the container
# is a per-account/registration id that changes on re-pair or reinstall, so we
# glob for it rather than hardcoding.
#
# Two device folders define the round trip:
#   INBOX   -> where Claude DROPS documents (you review/annotate from here)
#   EXPORT  -> where you PUT finished annotated files for Claude to pull
#
# Run directly to print a resolved folder — handy for raw `cp`:
#   paths.sh            -> the device root  (.../Supernote)
#   paths.sh --inbox    -> the send target  (.../Supernote/INBOX)
#   paths.sh --exports  -> the pull source  (.../Supernote/EXPORT)

SN_INBOX_SUBPATH="INBOX"
SN_EXPORTS_SUBPATH="EXPORT"

sn_resolve_doc() {
  local container="$HOME/Library/Containers/com.ratta.supernote/Data/Library/Application Support/com.ratta.supernote"
  local docs=() d
  for d in "$container"/*/Supernote; do
    [[ -d "$d" ]] && docs+=("$d")
  done
  if ((${#docs[@]} == 0)); then
    echo "manta: no Supernote folder under the Partner.app container — is Supernote Partner.app installed and the device paired?" >&2
    return 1
  fi
  if ((${#docs[@]} > 1)); then
    # More than one registration dir present; use the most recently modified.
    local newest
    newest="$(for d in "${docs[@]}"; do echo "$(stat -f '%m' "$d") $d"; done | sort -rn | head -1 | cut -d' ' -f2-)"
    echo "manta: multiple Supernote registrations found; using most recent: $newest" >&2
    printf '%s\n' "$newest"
    return 0
  fi
  printf '%s\n' "${docs[0]}"
}

sn_resolve_inbox()   { local doc; doc="$(sn_resolve_doc)" || return 1; printf '%s\n' "$doc/$SN_INBOX_SUBPATH"; }
sn_resolve_exports() { local doc; doc="$(sn_resolve_doc)" || return 1; printf '%s\n' "$doc/$SN_EXPORTS_SUBPATH"; }

# When executed directly (not sourced), print the requested folder.
if [[ "${BASH_SOURCE[0]}" == "${0:-}" ]]; then
  case "${1:-}" in
    --inbox)   sn_resolve_inbox ;;
    --exports) sn_resolve_exports ;;
    "")        sn_resolve_doc ;;
    *) echo "usage: paths.sh [--inbox | --exports]" >&2; exit 1 ;;
  esac
fi
