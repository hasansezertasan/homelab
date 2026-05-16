# homelab

One-shot bootstrap for turning a clean Apple Silicon MacBook into a personal
home server running:

| Layer       | Tool                                                    | Purpose                                         |
| ----------- | ------------------------------------------------------- | ----------------------------------------------- |
| Network     | [Tailscale](https://tailscale.com)                      | Mesh VPN — the only thing reachable from afar   |
| Remote GUI  | [RustDesk](https://rustdesk.com)                        | Desktop access over the tailnet, no relay needed|
| AI agent    | [Hermes](https://github.com/NousResearch/hermes-agent)  | Talk to it from Telegram/Discord/Slack/Signal   |
| Coding (cli)| [OpenCode](https://opencode.ai)                         | Headless AI coding agent on `:4096`             |
| Coding (UI) | [OpenChamber](https://openchamber.dev)                  | Web/PWA frontend for OpenCode on `:3000`        |
| PaaS        | Dokploy *(deferred — Linux-only)*                       | See `docs/DOKPLOY-LATER.md`                     |

> **Heads up about Dokploy.** It targets Ubuntu/Debian and won't run natively
> on macOS. This bootstrap installs the other five. When you're ready, add
> Dokploy inside a Lima VM following `docs/DOKPLOY-LATER.md`.

## Quick start

Fresh Mac with nothing installed? One-liner — triggers the Xcode Command
Line Tools prompt (which brings `git`), clones the repo, runs bootstrap:

```bash
curl -fsSL https://raw.githubusercontent.com/hasansezertasan/homelab/main/install.sh | bash
```

Then:

1. Open **Tailscale.app** and sign in.
2. Open **RustDesk** → enable Direct IP Access (see `docs/RUSTDESK.md`).
3. Run `hermes setup` to pick a model + configure platforms.
4. Edit `launchd/dev.openchamber.openchamber.plist`, set a real UI password
   where it says `CHANGE-ME-BEFORE-LOADING`, re-run `./bootstrap.sh`.
5. Visit `http://<mac-tailscale-ip>:3000` from your phone.

## What it does

- Installs Homebrew (Apple Silicon, `/opt/homebrew`).
- `brew install`: `git`, `gh`, `mise`, `uv`, `bun`, `jq`, `ripgrep`, `fd`, `bat`.
- `brew install --cask`: Tailscale, RustDesk, OrbStack.
- `curl | bash` (official installers): OpenCode, OpenChamber, Hermes.
- Drops three launchd plists in `~/Library/LaunchAgents/` so OpenCode and
  OpenChamber auto-start on boot. (Hermes gateway is opt-in.)
- Optional: with `HOMELAB_HEADLESS=1`, disables sleep and configures the Mac
  to wake on power and restart-after-freeze — closer to a real server.

The script is **idempotent**. Re-run it as often as you want; it skips
anything already installed and reloads the launchd jobs cleanly.

### Why these CLI tools

| Tool       | Reason                                                                 |
| ---------- | ---------------------------------------------------------------------- |
| `git`      | Agents read history, branch, and commit. Non-negotiable.               |
| `gh`       | Agents open PRs, read issues, and check CI. Auth via keychain.         |
| `mise`     | Per-project Node/Python/Go versions without sudo. `mise.toml` aware.   |
| `uv`       | Default Python tool — fast venvs, installs, lockfiles.                 |
| `bun`      | Default JS/TS tool — runtime + package manager in one binary.          |
| `jq`       | Agents pipe JSON constantly (API responses, configs, logs).            |
| `ripgrep`  | Fast code search — every agent's first move into an unfamiliar repo.   |
| `fd`       | Fast file finder — `find` ergonomics without `find` syntax.            |
| `bat`      | Syntax-highlighted `cat` for human eyes during RustDesk sessions.      |
| OrbStack   | Docker engine on Apple Silicon — lighter than Docker Desktop, free.    |

## The resulting architecture

```
        ┌───────────── your phone / laptop ─────────────┐
        │  Tailscale client ─→  100.x.x.x mesh          │
        └──────────────────┬────────────────────────────┘
                           │ WireGuard (encrypted)
        ┌──────────────────▼────────────────────────────┐
        │             MacBook M1 Pro (home)             │
        │  Tailscale  identity + reachability           │
        │  RustDesk   desktop @ 100.x.x.x               │
        │  Hermes     chat from Telegram/Discord/...    │
        │  OpenCode   :4096   (localhost only)          │
        │  OpenChamber :3000  (tailnet)                 │
        └───────────────────────────────────────────────┘
```

Nothing is exposed to the public internet. Tailscale ACLs are your firewall.
If you want HTTPS for the web UI, use `tailscale serve` — see `docs/OPENCHAMBER.md`.

## Repo layout

```
.
├── bootstrap.sh             # main installer — start here
├── teardown.sh              # reverse it (keeps data dirs)
├── status.sh                # health check: binaries, ports, launchd, tailscale
├── launchd/
│   ├── dev.openchamber.opencode.plist
│   ├── dev.openchamber.openchamber.plist
│   └── com.nousresearch.hermes-gateway.plist   (opt-in)
└── docs/
    ├── RUSTDESK.md          # Direct-IP-access config + macOS permissions
    ├── OPENCHAMBER.md       # First-time config, PWA install, HTTPS via tailscale serve
    ├── HERMES.md            # Gateway setup, enabling auto-start
    └── DOKPLOY-LATER.md     # Lima VM path for when you want Dokploy
```

## Headless Mac mode

If this Mac is going to live in a closet:

```bash
HOMELAB_HEADLESS=1 ./bootstrap.sh
```

This disables sleep, enables wake-on-AC and wake-on-lid, and turns on
auto-restart-after-freeze. You'll also want, in System Settings:

- Users & Groups → set "Automatic login" to your homelab user.
- General → Sharing → enable Screen Sharing (a fallback to RustDesk).
- Energy → "Prevent automatic sleeping when display is off".

## Health check

```bash
./status.sh
```

Prints which binaries are installed, which ports are listening, which
launchd jobs are loaded, and a one-line Tailscale status.

## Teardown

```bash
./teardown.sh
```

Removes the installed apps and unloads the launchd jobs. **Keeps data dirs**
(`~/.opencode/`, `~/.hermes/`, etc.) — delete those manually if you want a
truly clean slate.

## Why these tools together?

Mostly because each one solves a real piece of the "I want a personal
server" problem, and they compose without fighting each other:

- **Tailscale** removes the entire "expose stuff to the internet" problem.
  No port forwarding, no DDNS, no reverse proxy, no Let's Encrypt.
- **RustDesk over Tailscale** is the simplest GUI-into-the-Mac story.
  Tailscale's [own docs](https://tailscale.com/docs/solutions/access-remote-desktops-with-rustdesk)
  recommend exactly this combo — direct IP access, no RustDesk relay.
- **OpenCode + OpenChamber** turn the Mac into "coding agent from your
  phone." OpenChamber is explicitly built to expose OpenCode over a VPN.
- **Hermes** is the brain that lives on the box — talk to it from anywhere
  via the messaging gateway, and it remembers across sessions thanks to
  the Honcho-backed memory loop.
- **Dokploy** (later) becomes the place to drop random Docker apps. Inside
  a Lima VM, you can blow it away and restart without touching the Mac.

## Open questions & recommendations

Pre-bootstrap decisions worth making before running the script. These are
not enforced by `bootstrap.sh` — they shape the *operator* side of the box.

### Apple ID — sign in or skip?

**Recommendation: skip on first boot, add later only if you need a specific
iCloud-only feature.**

- **Skip pros:** no iCloud Drive eating disk, no Find My remote-locking the
  server you can't physically reach, no Keychain sync leaking secrets between
  daily-driver Mac and homelab, no Handoff/Universal Clipboard surprises with
  agents, no "App Store update requires your password" prompts during a
  headless reboot.
- **Skip cons:** no App Store apps, no `xcode-select` GUI niceties (CLT still
  works fine), no iMessage/FaceTime (which you don't want on a server anyway).
- **If you must:** use a *dedicated* Apple ID for the homelab. Disable iCloud
  Drive, Find My Mac, Keychain, Photos, and Handoff. Keep only App Store +
  Software Update.
- **Find My Mac specifically:** turn OFF. Activation Lock on a remote
  headless Mac = paperweight if anything goes wrong.

### Git + GitHub — how should agents authenticate?

**Recommendation: install `gh`, authenticate with a dedicated GitHub
account (or fine-grained PAT), and never put your personal SSH key on the box.**

```bash
brew install gh git
gh auth login   # choose HTTPS + browser flow; gh stores creds in keychain
git config --global user.name  "homelab bot"
git config --global user.email "you+homelab@users.noreply.github.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
```

Then for the coding agents:

- **Dedicated GitHub account** (or a *machine user* if you have GitHub Pro) so
  agent commits are attributable and can be revoked independently of you.
- **Fine-grained PAT** scoped only to the repos you want the agent to touch.
  Avoid classic tokens with `repo` scope — they grant access to *every* repo.
- **SSH key:** generate a *new* `ed25519` key on the homelab (`ssh-keygen -t
  ed25519 -C "homelab@$(hostname)"`), upload only that pubkey to GitHub. Never
  copy your daily-driver private key onto the server.
- **GPG / sigstore signing:** optional but cheap. `gh` can configure commit
  signing via SSH key. Lets you tell "agent did this" from "I did this."
- **No `co-authored-by: claude.ai/code`** — see the global rule in
  `~/.claude/CLAUDE.md`. Don't add AI tools as coauthors.

`gh` + `git` are installed by `bootstrap.sh`, but `gh auth login` and the
identity config above are deliberately left to you — choose your account
story before authenticating.

### Browser — what should the agents drive?

**Recommendation: Chromium-family for agents, Safari for ad-hoc human use
over RustDesk.**

- **Chrome / Chromium / Brave** — best support for headless automation
  (Playwright, Puppeteer, `chrome-devtools-mcp`). Safari's WebDriver is
  finicky and breaks across OS updates. Firefox works but its automation
  ecosystem is smaller.
- **Two-browser pattern:** install Chrome *or* Brave for agents, leave Safari
  for the times you VNC/RustDesk in and want to read a doc. Keeps agent
  cookies/logins/extensions out of your human browsing profile.
- **Brave specifically** if you want built-in tracker blocking on a box
  that's going to make a lot of un-curated requests.
- **`brew install --cask google-chrome`** or `brave-browser`. Skip Chromium
  builds from `brew install chromium` unless you specifically need the
  bare upstream (they aren't auto-updated by Google).

---

## License

MIT. Fork freely.
