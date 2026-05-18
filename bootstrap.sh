#!/usr/bin/env bash
# =====================================================================
# MacBook M1 Home Lab Bootstrap
# ---------------------------------------------------------------------
# Installs: Homebrew + everything in ./Brewfile (CLI tools, agents,
#           Tailscale, RustDesk, OrbStack) + OpenChamber.
# Target  : Apple Silicon (M1/M2/M3/M4), clean macOS install
# Idempotent: re-running skips anything already installed.
# =====================================================================

set -euo pipefail

# ---------- pretty output ----------
BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GRN=$'\033[32m'
YEL=$'\033[33m'; BLU=$'\033[34m'; RST=$'\033[0m'

step()  { printf "\n${BOLD}${BLU}==>${RST} ${BOLD}%s${RST}\n" "$*"; }
ok()    { printf "    ${GRN}✓${RST} %s\n" "$*"; }
skip()  { printf "    ${DIM}·${RST} ${DIM}%s${RST}\n" "$*"; }
warn()  { printf "    ${YEL}!${RST} %s\n" "$*"; }
fail()  { printf "    ${RED}✗${RST} %s\n" "$*" >&2; exit 1; }

# add_login_item APP_PATH
# Idempotent macOS Login Item registration via System Events. Visible under
# System Settings → General → Login Items, removable there.
add_login_item() {
  local app_path="$1" app_name
  app_name="$(basename "$app_path" .app)"
  [[ -d "$app_path" ]] || { warn "${app_name}: app not found at $app_path, skipping login item"; return 0; }
  if osascript -e "tell application \"System Events\" to get the name of every login item" 2>/dev/null \
       | tr ',' '\n' | sed 's/^ *//' | grep -qx "$app_name"; then
    skip "${app_name} already a login item"
  else
    osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app_path\", hidden:false}" >/dev/null \
      && ok "${app_name} added to Login Items" \
      || warn "${app_name}: could not add login item (grant Automation permission to Terminal?)"
  fi
}

# ---------- sanity checks ----------
[[ "$(uname -s)" == "Darwin" ]]   || fail "This script is macOS-only."
[[ "$(uname -m)" == "arm64" ]]    || fail "Apple Silicon required (script pins /opt/homebrew)."
[[ "$EUID" -ne 0 ]]                || fail "Don't run as root. The script will sudo when needed."

# Resolve script dir so we can find launchd/ siblings.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- 0. Xcode CLT (Homebrew prereq) ----------
step "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
  ok "already installed"
else
  warn "installing — a dialog will pop up; click Install and wait, then re-run this script"
  xcode-select --install || true
  fail "RERUN REQUIRED: re-invoke ./bootstrap.sh after Xcode CLT install finishes."
fi

# ---------- 1. Homebrew ----------
step "Homebrew"
if command -v brew &>/dev/null; then
  ok "already installed ($(brew --version | head -1))"
else
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  fi
fi
# Apple Silicon: brew lives under /opt/homebrew. Fail loud if missing.
[[ -x /opt/homebrew/bin/brew ]] || fail "/opt/homebrew/bin/brew missing — Apple Silicon required."
eval "$(/opt/homebrew/bin/brew shellenv)"

# ---------- 2. Brewfile (CLI tools, agents, GUI apps) ----------
# Single source of truth for brew packages. `brew bundle` is idempotent —
# installs whatever's missing, skips what's present, and won't upgrade
# already-installed packages.
step "Brewfile"
brew bundle --no-upgrade --file="${SCRIPT_DIR}/Brewfile"

# ---------- 3. GUI Login Items (auto-relaunch on reboot) ----------
# Casks installed via Brewfile in §1b. Here we register the Login Items so
# the GUI apps relaunch on every reboot. Visible/removable under System
# Settings → General → Login Items.
step "Login Items"
add_login_item "/Applications/Tailscale.app"
add_login_item "/Applications/RustDesk.app"

# ---------- 4. OpenChamber (web UI for OpenCode) ----------
step "OpenChamber"
if command -v openchamber &>/dev/null; then
  ok "already installed"
else
  curl -fsSL https://raw.githubusercontent.com/openchamber/openchamber/main/scripts/install.sh | bash
fi

# Upstream installer picks pnpm > bun > yarn > npm. pnpm/bun globals land in
# dirs (~/Library/pnpm, ~/.bun/bin) that may not be on PATH, and the launchd
# plist hardcodes /opt/homebrew/bin/openchamber. Symlink the real binary there
# so PATH lookup and the plist both resolve.
ensure_openchamber_symlink() {
  local target="/opt/homebrew/bin/openchamber"
  if [[ -L "$target" || -x "$target" ]]; then
    skip "openchamber already at $target"
    return
  fi

  local src=""
  for cand in \
    "$(pnpm bin -g 2>/dev/null)/openchamber" \
    "$HOME/Library/pnpm/openchamber" \
    "$HOME/.bun/bin/openchamber" \
    "$(npm prefix -g 2>/dev/null)/bin/openchamber" \
    "$(yarn global bin 2>/dev/null)/openchamber"; do
    if [[ -x "$cand" ]]; then
      src="$cand"
      break
    fi
  done

  [[ -z "$src" ]] && fail "openchamber binary not found after install"
  ln -sfn "$src" "$target"
  ok "openchamber symlinked: $target → $src"
}
ensure_openchamber_symlink

# ---------- 5. launchd services (auto-start on boot) ----------
step "launchd services"
LAUNCH_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_DIR"

# Stored OpenChamber UI password — gitignored location, mode 600. Survives
# re-runs so bootstrap stays idempotent. Rotate with `rm` + re-run.
OPENCHAMBER_PWFILE="$HOME/.config/homelab/openchamber.password"

# Sets $OPENCHAMBER_UI_PASSWORD by, in order: env var, stored file, interactive
# prompt. Reads from /dev/tty so `curl | bash` invocations still get a TTY.
ensure_openchamber_password() {
  mkdir -p "$(dirname "$OPENCHAMBER_PWFILE")"
  chmod 700 "$(dirname "$OPENCHAMBER_PWFILE")"

  if [[ -n "${OPENCHAMBER_UI_PASSWORD:-}" ]]; then
    printf '%s' "$OPENCHAMBER_UI_PASSWORD" > "$OPENCHAMBER_PWFILE"
    chmod 600 "$OPENCHAMBER_PWFILE"
    ok "OpenChamber UI password from \$OPENCHAMBER_UI_PASSWORD → $OPENCHAMBER_PWFILE"
    return
  fi

  if [[ -f "$OPENCHAMBER_PWFILE" ]]; then
    OPENCHAMBER_UI_PASSWORD="$(cat "$OPENCHAMBER_PWFILE")"
    skip "OpenChamber UI password loaded from $OPENCHAMBER_PWFILE"
    return
  fi

  [[ -r /dev/tty ]] || fail "no TTY for OpenChamber password prompt — set \$OPENCHAMBER_UI_PASSWORD or pre-create $OPENCHAMBER_PWFILE"

  local pw pw2
  while :; do
    read -r -s -p "    Set OpenChamber UI password: " pw < /dev/tty; echo
    [[ -n "$pw" ]] || { warn "empty — try again"; continue; }
    read -r -s -p "    Confirm: " pw2 < /dev/tty; echo
    [[ "$pw" == "$pw2" ]] || { warn "mismatch — try again"; continue; }
    break
  done
  printf '%s' "$pw" > "$OPENCHAMBER_PWFILE"
  chmod 600 "$OPENCHAMBER_PWFILE"
  OPENCHAMBER_UI_PASSWORD="$pw"
  ok "OpenChamber UI password saved to $OPENCHAMBER_PWFILE (mode 600)"
}

# install_plist NAME [EXTRA_SED_EXPR ...]
# Substitutes __HOME__ plus any extra `-e` sed exprs the caller passes.
install_plist() {
  local name="$1"; shift
  local src="${SCRIPT_DIR}/launchd/${name}.plist"
  local dst="${LAUNCH_DIR}/${name}.plist"

  [[ -f "$src" ]] || { warn "missing template: $src"; return; }

  sed -e "s|__HOME__|${HOME}|g" "$@" "$src" > "$dst"

  # Reload cleanly: unload (ignore errors), then load.
  launchctl unload "$dst" 2>/dev/null || true
  launchctl load   "$dst"
  ok "$name → ${dst}"
}

install_plist "dev.openchamber.opencode"

ensure_openchamber_password
# Escape sed metacharacters (\, &, |) in the password before substitution.
esc_pw=$(printf '%s' "$OPENCHAMBER_UI_PASSWORD" | sed -e 's/[\\&|]/\\&/g')
install_plist "dev.openchamber.openchamber" -e "s|__OPENCHAMBER_UI_PASSWORD__|${esc_pw}|g"
unset esc_pw

# Hermes runs interactively from the CLI/gateway by default; no plist by default.
# Uncomment to auto-start the messaging gateway:
# install_plist "com.nousresearch.hermes-gateway"

# ---------- 6. headless-server polish (optional but recommended) ----------
step "Headless server tweaks"
if [[ "${HOMELAB_HEADLESS:-0}" == "1" ]]; then
  displaysleep="${HOMELAB_DISPLAYSLEEP:-2}"
  if ! [[ "$displaysleep" =~ ^[0-9]+$ ]]; then
    fail "HOMELAB_DISPLAYSLEEP must be a non-negative integer (minutes; 0 = never), got: $displaysleep"
  fi
  sudo pmset -a \
    sleep 0 displaysleep "$displaysleep" disksleep 0 powernap 1 \
    lidwake 1 acwake 1 disablesleep 1
  sudo systemsetup -setrestartfreeze on 2>/dev/null || true
  if [[ "$displaysleep" == "0" ]]; then
    ok "sleep disabled (incl. clamshell), display never sleeps, wake-on-AC enabled, freeze-restart on"
  else
    ok "sleep disabled (incl. clamshell), display sleeps after ${displaysleep} min, wake-on-AC enabled, freeze-restart on"
  fi
  warn "lid-closed-awake uses pmset disablesleep — Apple-unsupported but stable on M1"
else
  skip "set HOMELAB_HEADLESS=1 to disable sleep (incl. lid-closed) and configure auto-wake"
fi

# ---------- 7. Claude Code skill packs ----------
# Installed via the `skills` CLI (npx, no global install needed). The CLI is
# itself idempotent — re-runs no-op or pick up upstream updates, mirroring
# how §2 `brew bundle` is trusted to handle re-runs.
# `-g` installs into ~/.claude/skills so packs are available to every agent
# session, not just this repo (the CLI defaults to project scope inside a git
# checkout, which is the wrong default for a personal bootstrapper).
step "Claude Code skill packs"
SKILL_PACKS=(
  "obra/superpowers"
)
if command -v npx &>/dev/null; then
  for pack in "${SKILL_PACKS[@]}"; do
    if npx -y skills add "$pack" -g --all; then
      ok "$pack"
    else
      warn "$pack — install failed (continuing)"
    fi
  done
else
  warn "npx missing — Brewfile should have installed node; skipping skill packs"
fi

# ---------- done ----------
cat <<EOF

${GRN}${BOLD}Done.${RST} Next steps:

  ${BOLD}1.${RST} Open Tailscale.app and sign in. Note your machine's 100.x.x.x address.
  ${BOLD}2.${RST} Open RustDesk → Settings → Security → enable ${BOLD}Direct IP Access${RST}
     and set a permanent password. (See README §RustDesk over Tailscale)
  ${BOLD}3.${RST} Run ${BOLD}hermes setup${RST} to pick a model provider and configure gateways.
  ${BOLD}4.${RST} OpenChamber is running on ${BOLD}http://localhost:3000${RST}
     (or http://<tailscale-ip>:3000 from anywhere on your tailnet).
  ${BOLD}5.${RST} For headless Mac mode: re-run with ${BOLD}HOMELAB_HEADLESS=1 ./bootstrap.sh${RST}

Logs for the launchd services live in ${DIM}~/Library/Logs/homelab/${RST}.

EOF
