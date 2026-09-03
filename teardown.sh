#!/usr/bin/env bash
# Reverse of bootstrap.sh — unloads launchd jobs and uninstalls apps.
# Does NOT delete config/data dirs (~/.opencode, ~/.hermes, etc.) —
# remove those manually if you really mean it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCH_DIR="$HOME/Library/LaunchAgents"
DEBLOAT_STATE_DIR="${HOMELAB_DEBLOAT_STATE_DIR:-$HOME/.config/homelab/debloat}"

# Only roll back a snapshot this repo captured (marker written by debloat-mac.sh).
if [[ -f "${DEBLOAT_STATE_DIR}/.homelab-debloat" ]]; then
  "${SCRIPT_DIR}/debloat-mac.sh" undo
fi

echo "==> Reverting headless pmset tweaks (only what bootstrap.sh set)"
sudo pmset -a disablesleep 0 2>/dev/null || true
sudo pmset -a sleep 1 displaysleep 10 disksleep 10 powernap 0 lidwake 1 acwake 0 2>/dev/null || true
sudo systemsetup -setrestartfreeze off 2>/dev/null || true
echo "    pmset tweaks reverted to common defaults — verify with: pmset -g"
echo "    (does not restore any pre-bootstrap custom pmset config)"

echo "==> Unloading launchd jobs"
# com.nousresearch.hermes-gateway is legacy — bootstrap.sh never installs it any
# more, but keep it here so boxes that opted into the old gateway get cleaned up.
for label in \
  dev.openchamber.opencode \
  dev.openchamber.openchamber \
  dev.onorca.orca \
  com.nousresearch.hermes-gateway
do
  plist="${LAUNCH_DIR}/${label}.plist"
  if [[ -f "$plist" ]]; then
    launchctl unload "$plist" 2>/dev/null || true
    rm -f "$plist"
    echo "    removed $label"
  fi
done

echo "==> Uninstalling Homebrew casks"
for cask in tailscale-app tailscale rustdesk; do
  brew uninstall --cask "$cask" 2>/dev/null && echo "    removed $cask" || true
done
# Orca is intentionally NOT uninstalled — it doubles as a standalone desktop ADE
# you may rely on outside the homelab (this repo is often edited from inside it).
# The launchd job above is already unloaded/removed; the app stays. Remove it
# yourself if you really mean to: brew uninstall --cask orca
echo "    left orca installed (run 'brew uninstall --cask orca' to remove the app)"

echo "==> Removing Hermes' own launchd job (ai.hermes.gateway)"
# This plist is written by `hermes gateway install` (bootstrap.sh §5c), not from
# a template in launchd/, so let Hermes remove it — and do it before the binary
# is uninstalled below, while the CLI still exists.
if command -v hermes &>/dev/null; then
  hermes gateway uninstall 2>/dev/null && echo "    removed ai.hermes.gateway" \
    || echo "    no ai.hermes.gateway job to remove"
else
  echo "    hermes not on PATH — skipping (remove ~/Library/LaunchAgents/ai.hermes.gateway.plist by hand if it exists)"
fi

echo "==> Removing OpenChamber / OpenCode / Hermes binaries"
brew uninstall openchamber 2>/dev/null || true
# Only the installed binary is removed; ~/.opencode/auth.json + other state
# files remain. Delete ~/.opencode manually for a full wipe.
brew uninstall opencode 2>/dev/null || true
brew uninstall hermes-agent 2>/dev/null || true

echo
echo "Done. Data dirs left intact:"
echo "  ~/.opencode/   ~/.openchamber/   ~/.hermes/   ~/.config/tailscale/"
echo "Delete them manually if you want a fully clean slate."
