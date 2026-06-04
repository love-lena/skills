#!/usr/bin/env bash
# Shared cloud helpers for the manta skill. Sourced by editorial.sh and flatten.sh.
#
# The manta workflow round-trips documents through a self-hosted Supernote
# private cloud via the `supernote cloud` CLI — not a local desktop sync folder.
# Two standard device folders define the trip:
#   /INBOX   -> where Claude UPLOADS documents for you to review / annotate
#   /EXPORT  -> where you FILE finished annotations for Claude to pull back
#
# Prerequisites (one-time):
#   - a Supernote private cloud you can reach (e.g. allenporter/supernote self-host)
#   - a login, cached at ~/.cache/supernote.pkl:
#       <venv>/bin/supernote cloud login <your-account> --url <your-cloud-url>
# Nothing secret lives in this skill; the host + token live only in that cache.

SN_INBOX="/INBOX"
SN_EXPORT="/EXPORT"
SN_VENV="${SN_VENV:-$HOME/.cache/manta/.venv}"

# Build the skill's venv if missing: the cloud client (`supernote`) plus the
# notebook tooling flatten.sh needs (`supernote-tool` from supernotelib, pymupdf).
sn_ensure_venv() {
  if [[ -x "$SN_VENV/bin/supernote" && -x "$SN_VENV/bin/supernote-tool" ]]; then
    return 0
  fi
  echo "[setup] building manta venv at $SN_VENV (one-time)..." >&2
  mkdir -p "$(dirname "$SN_VENV")"
  # supernote requires Python >=3.13; pick a compatible interpreter.
  local pybin
  pybin="$(command -v python3.13 || command -v python3.14 || true)"
  if [[ -z "$pybin" ]] && command -v python3 >/dev/null \
     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info>=(3,13) else 1)'; then
    pybin="$(command -v python3)"
  fi
  [[ -n "$pybin" ]] || { echo "error: need Python >=3.13 (supernote requires it) on PATH" >&2; return 1; }
  [[ -d "$SN_VENV" ]] || "$pybin" -m venv "$SN_VENV"
  # Version-agnostic cairo pkgconfig in case a build dep needs it (Homebrew
  # symlinks the active cairo's pkgconfig under <prefix>/lib/pkgconfig).
  local pc=""
  command -v brew >/dev/null && pc="$(brew --prefix 2>/dev/null)/lib/pkgconfig"
  # NOTE: the supernote `[client]` extra omits mashumaro, but the `cloud`
  # subcommand needs it (without it the subcommand is silently disabled), so
  # install it explicitly. pkg-config + cairo are needed to build pycairo
  # (a supernotelib dep) from source on Pythons without a prebuilt wheel.
  PKG_CONFIG_PATH="${pc}${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" \
    "$SN_VENV/bin/pip" install --quiet supernotelib pymupdf "supernote[client]" mashumaro || {
      echo "error: failed to install supernote client + tooling into $SN_VENV" >&2
      return 1
    }
}

# Print the cloud CLI path. Call sn_ensure_venv first.
sn_cli() { printf '%s\n' "$SN_VENV/bin/supernote"; }

# Fail with setup instructions if there is no cached cloud login.
sn_ensure_login() {
  if [[ ! -f "$HOME/.cache/supernote.pkl" ]]; then
    cat >&2 <<EOF
manta: not logged in to a Supernote cloud. Run once (your account + cloud URL):
  $SN_VENV/bin/supernote cloud login <your-account> --url <your-cloud-url>
EOF
    return 1
  fi
}

# When executed directly (not sourced): build the venv and report login status.
if [[ "${BASH_SOURCE[0]}" == "${0:-}" ]]; then
  sn_ensure_venv || exit 1
  if [[ -f "$HOME/.cache/supernote.pkl" ]]; then
    echo "manta: venv ready at $SN_VENV; logged in."
  else
    echo "manta: venv ready at $SN_VENV; not logged in." >&2
    echo "  run: $SN_VENV/bin/supernote cloud login <your-account> --url <your-cloud-url>" >&2
  fi
fi
