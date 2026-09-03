#!/usr/bin/env bash
# Quick health check of the homelab stack.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BOLD=$'\033[1m'; GRN=$'\033[32m'; RED=$'\033[31m'; DIM=$'\033[2m'; RST=$'\033[0m'

check_cmd() {
  if command -v "$1" &>/dev/null; then
    printf "  ${GRN}✓${RST} %-14s %s\n" "$1" "${DIM}$(command -v "$1")${RST}"
  else
    printf "  ${RED}✗${RST} %-14s ${DIM}not installed${RST}\n" "$1"
  fi
}

check_port() {
  local port="$1"; local name="$2"
  if lsof -iTCP:"$port" -sTCP:LISTEN -n -P &>/dev/null; then
    printf "  ${GRN}✓${RST} :%-5s listening (%s)\n" "$port" "$name"
  else
    printf "  ${RED}✗${RST} :%-5s not listening (%s)\n" "$port" "$name"
  fi
}

check_launchd() {
  local label="$1"
  local pid
  pid=$(launchctl list | awk -v l="$label" '$3==l {print $1; found=1} END {exit !found}') || {
    printf "  ${RED}✗${RST} %-40s not loaded\n" "$label"
    return
  }
  printf "  ${GRN}✓${RST} %-40s pid=%s\n" "$label" "${pid:-?}"
}

echo "${BOLD}Binaries${RST}"
check_cmd tailscale
# RustDesk ships as a .app bundle on macOS, no CLI by default — check both.
if command -v rustdesk &>/dev/null || command -v RustDesk &>/dev/null || [[ -d /Applications/RustDesk.app ]]; then
  printf "  ${GRN}✓${RST} %-14s ${DIM}installed${RST}\n" "rustdesk"
else
  printf "  ${RED}✗${RST} %-14s ${DIM}not installed${RST}\n" "rustdesk"
fi
check_cmd opencode
check_cmd openchamber
check_cmd orca
check_cmd hermes
check_cmd brew

echo
echo "${BOLD}CLI tools${RST}"
for c in git gh mise uv bun jq rg fd bat orb; do check_cmd "$c"; done

echo
echo "${BOLD}Ports${RST}"
check_port 4096 "OpenCode"
check_port 3000 "OpenChamber"
# Orca is opt-in (HOMELAB_ORCA=1) — only report its port when the plist exists,
# so a deliberately-disabled Orca doesn't show as a failure. Read the actual
# port from the plist (bootstrap can override it via HOMELAB_ORCA_PORT) rather
# than assuming the 6768 default.
orca_plist="$HOME/Library/LaunchAgents/dev.onorca.orca.plist"
if [[ -f "$orca_plist" ]]; then
  # ProgramArguments is: orca serve --port <PORT> --pairing-address <ADDR>.
  # -A1 prints the <string> line right after --port; extract its digits.
  # Portable BSD-grep only (no gawk) — this repo is macOS-only.
  orca_port=$(grep -A1 '<string>--port</string>' "$orca_plist" | grep -Eo '[0-9]+' | head -1)
  check_port "${orca_port:-6768}" "Orca"
fi

echo
echo "${BOLD}launchd${RST}"
check_launchd dev.openchamber.opencode
check_launchd dev.openchamber.openchamber
[[ -f "$HOME/Library/LaunchAgents/dev.onorca.orca.plist" ]] && check_launchd dev.onorca.orca
check_launchd com.nousresearch.hermes-gateway

echo
echo "${BOLD}Tailscale${RST}"
if command -v tailscale &>/dev/null; then
  tailscale status 2>/dev/null | head -3 || echo "  ${DIM}(not signed in)${RST}"
else
  echo "  ${DIM}(tailscale CLI not on PATH — open the GUI app)${RST}"
fi

echo
echo "${BOLD}macOS resource tuning${RST}"
"${SCRIPT_DIR}/debloat-mac.sh" status
