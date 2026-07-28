# MacBook M1 Home Lab — Brewfile
# Installed via `brew bundle --file=./Brewfile` in bootstrap.sh §1b.

# CLI staples
brew "git"
brew "gh"
brew "mise"
brew "uv"
brew "node"
brew "bun"
brew "jq"
brew "ripgrep"
brew "fd"
brew "bat"
brew "zoxide"
brew "ctx7"

# Agents — homebrew/core ships official builds. Binaries land in
# /opt/homebrew/bin/ so the launchd plists' PATH resolves them without
# any symlink shim. hermes-agent installs three: hermes, hermes-agent,
# hermes-acp.
brew "opencode"
brew "hermes-agent"

# GUI apps (Login Items registered separately in bootstrap.sh).
# The tailscale-app cask was renamed from "tailscale" upstream; brew's
# old_tokens metadata makes "tailscale" resolve to "tailscale-app" on any
# reasonably modern Homebrew, so no fallback is needed here.
cask "tailscale-app"
cask "rustdesk"
cask "orbstack"

# Orca — parallel-agent ADE, an opt-in alternative to OpenChamber. The cask
# ships the desktop app AND the `orca` CLI at /opt/homebrew/bin/orca (so the
# launchd plist resolves it without a shim). Installed unconditionally like
# orbstack; the headless `orca serve` launchd job is opt-in via HOMELAB_ORCA=1
# in bootstrap.sh. Cask auto-updates itself, so `brew bundle --no-upgrade`
# won't fight the app's own updater.
cask "stablyai/orca/orca"
