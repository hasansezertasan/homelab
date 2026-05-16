#!/usr/bin/env bash
# Reverse of bootstrap.sh — unloads launchd jobs and uninstalls apps.
# Does NOT delete config/data dirs (~/.opencode, ~/.hermes, etc.) —
# remove those manually if you really mean it.

set -euo pipefail

LAUNCH_DIR="$HOME/Library/LaunchAgents"

echo "==> Reverting headless pmset tweaks"
sudo pmset -a disablesleep 0 2>/dev/null || true
sudo pmset -a sleep 1 2>/dev/null || true
echo "    pmset disablesleep=0, sleep=1 (defaults restored — review with: pmset -g)"

echo "==> Unloading launchd jobs"
for label in \
  dev.openchamber.opencode \
  dev.openchamber.openchamber \
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

echo "==> Removing OpenChamber / OpenCode / Hermes binaries"
brew uninstall openchamber 2>/dev/null || true
rm -rf "$HOME/.opencode/bin"  # leave config/data
rm -f  "$HOME/.local/bin/hermes"

echo
echo "Done. Data dirs left intact:"
echo "  ~/.opencode/   ~/.openchamber/   ~/.hermes/   ~/.config/tailscale/"
echo "Delete them manually if you want a fully clean slate."
