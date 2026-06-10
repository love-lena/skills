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

# Optional local credentials file for unattended re-login (NOT in this repo;
# nothing secret ships with the skill). Create it once, chmod 600, with:
#   SN_ACCOUNT=you@your-cloud
#   SN_PASSWORD=...
#   SN_URL=http://your-cloud:8080
# Override the location with SN_CREDS.
SN_CREDS="${SN_CREDS:-$HOME/.config/manta/login.env}"

# True if the cached token currently works (cheap probe against the cloud).
sn_token_ok() { "$(sn_cli)" cloud ls / >/dev/null 2>&1; }

# Log in using the local creds file. Non-zero if it's absent or incomplete.
sn_login_from_creds() {
  [[ -f "$SN_CREDS" ]] || return 1
  # shellcheck disable=SC1090
  source "$SN_CREDS"
  [[ -n "${SN_ACCOUNT:-}" && -n "${SN_PASSWORD:-}" && -n "${SN_URL:-}" ]] || return 1
  "$(sn_cli)" cloud login "$SN_ACCOUNT" --password "$SN_PASSWORD" --url "$SN_URL" >/dev/null 2>&1
}

# Ensure a WORKING cloud session. Probes the cached token; if it's missing or
# expired, transparently re-logs in from $SN_CREDS. Falls back to one-time
# manual-login instructions only when no creds file is present.
sn_ensure_login() {
  if [[ -f "$HOME/.cache/supernote.pkl" ]] && sn_token_ok; then
    return 0
  fi
  if [[ -f "$SN_CREDS" ]]; then
    echo "manta: cloud session missing/expired — re-logging in from $SN_CREDS" >&2
    if sn_login_from_creds && sn_token_ok; then
      return 0
    fi
    echo "manta: auto re-login failed (check $SN_CREDS and that the cloud is reachable)" >&2
    return 1
  fi
  cat >&2 <<EOF
manta: no working Supernote session (token missing/expired, no auto-login creds).
Log in once:
  $SN_VENV/bin/supernote cloud login <your-account> --url <your-cloud-url>
or create $SN_CREDS (chmod 600) with SN_ACCOUNT / SN_PASSWORD / SN_URL for
unattended re-login.
EOF
  return 1
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
