#!/usr/bin/env bash
# Reverse of bootstrap.sh — unloads launchd jobs and uninstalls apps.
# Does NOT delete config/data dirs (~/.opencode, ~/.hermes, etc.) —
# remove those manually if you really mean it.

set -euo pipefail

LAUNCH_DIR="$HOME/Library/LaunchAgents"

echo "==> Reverting headless pmset tweaks (only what bootstrap.sh set)"
sudo pmset -a disablesleep 0 2>/dev/null || true
sudo pmset -a sleep 1 displaysleep 10 disksleep 10 powernap 0 lidwake 1 acwake 0 2>/dev/null || true
sudo systemsetup -setrestartfreeze off 2>/dev/null || true
echo "    pmset tweaks reverted to common defaults — verify with: pmset -g"
echo "    (does not restore any pre-bootstrap custom pmset config)"

echo "==> Unloading launchd jobs"
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
