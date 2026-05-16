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
