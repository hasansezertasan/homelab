#!/usr/bin/env bash
# =====================================================================
# MacBook M1 Home Lab Bootstrap
# ---------------------------------------------------------------------
# Installs: Homebrew + CLI tools (git, gh, mise, uv, bun, jq, ripgrep, fd, bat),
#           OrbStack, Tailscale, RustDesk, OpenCode, OpenChamber, Hermes
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

# install_cask APP_NAME CASK [POST_INSTALL_NOTE]
# Idempotent cask install — guards on /Applications/${APP_NAME}.app presence.
install_cask() {
  local app="$1" cask="$2" note="${3:-}"
  if [[ -d "/Applications/${app}.app" ]]; then
    ok "${app} already installed"
  else
    brew install --cask "$cask"
    ok "${app} installed${note:+ — $note}"
  fi
}

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

# ---------- 1b. CLI tools (agent staples + runtimes) ----------
step "CLI tools"
BREW_FORMULAE=(git gh mise uv node jq ripgrep fd bat)
for pkg in "${BREW_FORMULAE[@]}"; do
  if brew list --formula "$pkg" &>/dev/null; then
    skip "$pkg already installed"
  else
    brew install "$pkg"
    ok "$pkg installed"
  fi
done

if command -v bun &>/dev/null; then
  skip "bun already installed"
else
  brew install oven-sh/bun/bun
  ok "bun installed"
fi

# ---------- 1c. OrbStack (Docker runtime — lighter than Docker Desktop) ----------
step "OrbStack"
install_cask "OrbStack" "orbstack" "launch OrbStack.app once to start the Docker engine"

# ---------- 2. Tailscale (mesh VPN — must be first) ----------
step "Tailscale"
# tailscale-app is the new cask name; older Homebrew uses `tailscale`.
if brew info --cask tailscale-app &>/dev/null; then
  tailscale_cask="tailscale-app"
else
  tailscale_cask="tailscale"
fi
install_cask "Tailscale" "$tailscale_cask" "open Tailscale.app and sign in before the next reboot"
add_login_item "/Applications/Tailscale.app"

# ---------- 3. RustDesk (remote desktop over the tailnet) ----------
step "RustDesk"
install_cask "RustDesk" "rustdesk" "see README §RustDesk over Tailscale for the Direct-IP-access config"
add_login_item "/Applications/RustDesk.app"

# ---------- 4. OpenCode (headless AI coding agent) ----------
step "OpenCode"
if command -v opencode &>/dev/null; then
  ok "already installed ($(opencode --version 2>/dev/null || echo present))"
else
  curl -fsSL https://opencode.ai/install | bash
  # installer drops the binary in ~/.opencode/bin
  if ! grep -q 'opencode/bin' ~/.zshrc 2>/dev/null; then
    echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.zshrc
  fi
  export PATH="$HOME/.opencode/bin:$PATH"
fi

# ---------- 5. OpenChamber (web UI for OpenCode) ----------
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

# ---------- 6. Hermes Agent (Nous Research) ----------
step "Hermes Agent"
if command -v hermes &>/dev/null; then
  ok "already installed"
else
  # --skip-setup keeps bootstrap non-interactive; user runs `hermes setup` manually.
  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash -s -- --skip-setup
  warn "run \`hermes setup\` after this script finishes to pick a model + gateway"
fi

# ---------- 7. launchd services (auto-start on boot) ----------
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

# ---------- 8. headless-server polish (optional but recommended) ----------
step "Headless server tweaks"
if [[ "${HOMELAB_HEADLESS:-0}" == "1" ]]; then
  sudo pmset -a \
    sleep 0 displaysleep 10 disksleep 0 powernap 1 \
    lidwake 1 acwake 1 disablesleep 1
  sudo systemsetup -setrestartfreeze on 2>/dev/null || true
  ok "sleep disabled (incl. clamshell), wake-on-AC enabled, freeze-restart on"
  warn "lid-closed-awake uses pmset disablesleep — Apple-unsupported but stable on M1"
else
  skip "set HOMELAB_HEADLESS=1 to disable sleep (incl. lid-closed) and configure auto-wake"
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
