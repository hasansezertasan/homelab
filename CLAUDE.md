# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

One-shot bootstrap that turns a clean Apple Silicon Mac into a personal home server. Pure shell + launchd plists — no application code, no tests, no build step. Five tools layered behind Tailscale: Tailscale (mesh VPN), RustDesk (remote desktop), Hermes (AI agent), OpenCode (`:4096` localhost), OpenChamber (`:3000` tailnet). Dokploy is deferred — see README §Dokploy (later, via Lima).

Nothing is exposed to the public internet. Tailscale ACLs are the firewall.

Entry points: `install.sh` is the remote `curl | bash` bootstrapper (clones repo + runs `bootstrap.sh`); `bootstrap.sh` is the local installer.

## Commands

```bash
./bootstrap.sh                       # install + reload launchd jobs (idempotent)
HOMELAB_HEADLESS=1 ./bootstrap.sh    # additionally disable sleep + wake-on-AC + restart-after-freeze
HOMELAB_HERMES_CRON=1 ./bootstrap.sh # additionally supervise Hermes' background process (hosts `hermes cron`)
HOMELAB_DEBLOAT=1 ./bootstrap.sh     # conservatively trim unused macOS background work
./status.sh                          # health: binaries, ports, launchd, tailscale
./teardown.sh                        # remove apps + unload launchd (keeps ~/.opencode, ~/.hermes data dirs)
```

No linter, no test suite. Validate shell edits with `bash -n bootstrap.sh` and `shellcheck` if available.

## Architecture

- `bootstrap.sh` — single installer. Sections numbered 0-7: Xcode CLT → Homebrew → `brew bundle` (Brewfile: CLI tools, agents, Tailscale, RustDesk, OrbStack) → GUI Login Items (Tailscale, RustDesk) → OpenChamber → launchd → optional headless/resource tweaks → skill packs. Uses `step/ok/skip/warn/fail` helpers for output. `set -euo pipefail`.
- `Brewfile` — single source of truth for brew formulae + casks. Add new tools here, not as new bootstrap.sh sections.
- `install.sh` — remote bootstrap. Installs Xcode CLT, clones repo to `~/homelab`, execs `bootstrap.sh`.
- `launchd/*.plist` — templates with `__HOME__` placeholder. `install_plist()` substitutes via `sed`, writes to `~/Library/LaunchAgents/`, then `launchctl unload || true` + `launchctl load` for clean reload. Hermes ships no template here — it runs on demand via `hermes desktop` / `hermes dashboard` / `hermes` (add `--tui` for the modern TUI). Its one background job (`ai.hermes.gateway`, opt-in via `HOMELAB_HERMES_CRON=1`) is written by `hermes gateway install`, so §5c shells out to that instead.
- `mise.toml` — per-project runtime pins for agents using `mise`.
- `debloat-mac.sh` — opt-in macOS resource tuning with captured-state rollback.
- `status.sh` / `teardown.sh` — companions to bootstrap.

## Invariants

- **`bootstrap.sh` MUST stay idempotent.** Every install step guards with `command -v` / `[[ -d /Applications/X.app ]]` before installing. Every launchd reload uses `unload ... || true` then `load`. New steps must follow this pattern — never assume clean state, never error on re-run.
- Apple Silicon only (`/opt/homebrew`). Script warns but proceeds on non-arm64.
- Never `sudo` the whole script — `bootstrap.sh` refuses `EUID==0` and calls `sudo` only inside the headless section.
- OpenChamber installs via `curl | bash` pinned to upstream `main` — changing that URL is a supply-chain decision, flag it. OpenCode and Hermes come from Homebrew (`opencode`, `hermes-agent` in the Brewfile), not `curl | bash`.
- Plists use `__HOME__` placeholder, never hard-coded paths. New plists must follow. The one job not covered by this is `ai.hermes.gateway` — Hermes writes and rewrites that plist itself (`hermes gateway install` / `uninstall`, re-run on every `hermes update`), so `bootstrap.sh` §5c and `teardown.sh` shell out to the CLI rather than shipping a competing template. Don't add one.
- `hermes cron` jobs only fire while a supervised `hermes gateway run` process is alive; that process needs no messaging platform configured. "Gateway" means the supervised host, not the retired chat bridge — don't re-add Telegram/Discord plumbing on the strength of the name.
- Secrets/passwords never live in repo templates. Plists use `__PLACEHOLDER__` tokens (e.g. `__OPENCHAMBER_UI_PASSWORD__`); `install_plist` substitutes at install time from values prompted on first run and stored under `~/.config/homelab/` (mode 600). Subsequent runs reuse stored values for idempotency. `$VARNAME` env-var overrides are supported for non-interactive bootstrap.
- Resource tuning is opt-in. Capture prior state under `~/.config/homelab/debloat/` before changing it, and restore only state captured by this repo. Gatekeeper, quarantine, and SIP changes are documentation-only.

## Conventions

- Document-Driven Development: README is the contract (per-tool guides live inline as collapsibles in §Per-tool guides). Update README first, then make `bootstrap.sh` match.
- Conventional Commits, Conventional Branch, Conventional PR titles (per global CLAUDE.md).
