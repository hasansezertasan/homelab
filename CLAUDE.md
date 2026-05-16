# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

One-shot bootstrap that turns a clean Apple Silicon Mac into a personal home server. Pure shell + launchd plists — no application code, no tests, no build step. Five tools layered behind Tailscale: Tailscale (mesh VPN), RustDesk (remote desktop), Hermes (AI agent), OpenCode (`:4096` localhost), OpenChamber (`:3000` tailnet). Dokploy is deferred — see `docs/DOKPLOY-LATER.md`.

Nothing is exposed to the public internet. Tailscale ACLs are the firewall.

Entry points: `install.sh` is the remote `curl | bash` bootstrapper (clones repo + runs `bootstrap.sh`); `bootstrap.sh` is the local installer.

## Commands

```bash
./bootstrap.sh                       # install + reload launchd jobs (idempotent)
HOMELAB_HEADLESS=1 ./bootstrap.sh    # additionally disable sleep + wake-on-AC + restart-after-freeze
./status.sh                          # health: binaries, ports, launchd, tailscale
./teardown.sh                        # remove apps + unload launchd (keeps ~/.opencode, ~/.hermes data dirs)
```

No linter, no test suite. Validate shell edits with `bash -n bootstrap.sh` and `shellcheck` if available.

## Architecture

- `bootstrap.sh` — single installer. Sections numbered 0-8: Xcode CLT → Homebrew → Tailscale → RustDesk → OpenCode → OpenChamber → Hermes → launchd → optional headless tweaks. Uses `step/ok/skip/warn/fail` helpers for output. `set -euo pipefail`.
- `install.sh` — remote bootstrap. Installs Xcode CLT, clones repo to `~/homelab`, execs `bootstrap.sh`.
- `launchd/*.plist` — templates with `__HOME__` placeholder. `install_plist()` substitutes via `sed`, writes to `~/Library/LaunchAgents/`, then `launchctl unload || true` + `launchctl load` for clean reload. Hermes plist exists but is commented out (opt-in).
- `mise.toml` — per-project runtime pins for agents using `mise`.
- `status.sh` / `teardown.sh` — companions to bootstrap.

## Invariants

- **`bootstrap.sh` MUST stay idempotent.** Every install step guards with `command -v` / `[[ -d /Applications/X.app ]]` before installing. Every launchd reload uses `unload ... || true` then `load`. New steps must follow this pattern — never assume clean state, never error on re-run.
- Apple Silicon only (`/opt/homebrew`). Script warns but proceeds on non-arm64.
- Never `sudo` the whole script — `bootstrap.sh` refuses `EUID==0` and calls `sudo` only inside the headless section.
- Installer URLs (`curl | bash`) are pinned to upstream `main` for OpenCode / OpenChamber / Hermes — changing these is a supply-chain decision, flag it.
- Plists use `__HOME__` placeholder, never hard-coded paths. New plists must follow.
- Secrets/passwords (e.g. OpenChamber UI password marked `CHANGE-ME-BEFORE-LOADING`) live in plists the user edits before re-running bootstrap. Don't bake real values into templates.

## Conventions

- Document-Driven Development: README + `docs/*.md` are the contract. Update docs first, then make `bootstrap.sh` match.
- Conventional Commits, Conventional Branch, Conventional PR titles (per global CLAUDE.md).
