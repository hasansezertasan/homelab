#!/usr/bin/env bash
# =====================================================================
# homelab one-liner installer
# ---------------------------------------------------------------------
# For fresh Macs with no git. Triggers Xcode CLT install (which brings
# git), clones the repo, runs bootstrap.sh.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/hasansezertasan/homelab/main/install.sh | bash
# =====================================================================

set -euo pipefail

REPO_URL="${HOMELAB_REPO_URL:-https://github.com/hasansezertasan/homelab}"
CLONE_DIR="${HOMELAB_CLONE_DIR:-$HOME/homelab}"

BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GRN=$'\033[32m'
YEL=$'\033[33m'; BLU=$'\033[34m'; RST=$'\033[0m'
step() { printf "\n${BOLD}${BLU}==>${RST} ${BOLD}%s${RST}\n" "$*"; }
ok()   { printf "    ${GRN}✓${RST} %s\n" "$*"; }
warn() { printf "    ${YEL}!${RST} %s\n" "$*"; }
fail() { printf "    ${RED}✗${RST} %s\n" "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || fail "macOS only."
[[ "$EUID" -ne 0 ]]             || fail "Don't run as root."

# ---------- 1. Xcode CLT (provides git) ----------
step "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
  ok "already installed"
else
  warn "triggering install dialog — click Install, wait for completion, then re-run this command"
  xcode-select --install || true
  # Poll until CLT finishes (user clicks through GUI). Bound the wait so a
  # cancelled dialog doesn't loop forever — 30 min covers a slow download.
  printf "    ${DIM}waiting for install to finish (up to 30 min)...${RST}\n"
  for _ in $(seq 1 180); do
    xcode-select -p &>/dev/null && break
    sleep 10
  done
  xcode-select -p &>/dev/null || fail "Xcode CLT not installed after 30 min. Re-run when ready."
  ok "installed"
fi

command -v git &>/dev/null || fail "git still missing after CLT install."

# ---------- 2. Clone repo ----------
step "Cloning $REPO_URL → $CLONE_DIR"
if [[ -d "$CLONE_DIR/.git" ]]; then
  ok "already cloned; pulling latest"
  git -C "$CLONE_DIR" pull --ff-only
else
  [[ -e "$CLONE_DIR" ]] && fail "$CLONE_DIR exists but is not a git repo. Move it or set HOMELAB_CLONE_DIR."
  git clone "$REPO_URL" "$CLONE_DIR"
fi

# ---------- 3. Hand off to bootstrap.sh ----------
step "Running bootstrap.sh"
cd "$CLONE_DIR"
exec ./bootstrap.sh "$@"
