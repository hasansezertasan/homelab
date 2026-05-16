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
| PaaS        | Dokploy *(deferred — Linux-only)*                       | See [Dokploy (later, via Lima)](#dokploy-later-via-lima) |

> **Heads up about Dokploy.** It targets Ubuntu/Debian and won't run natively
> on macOS. This bootstrap installs the other five. When you're ready, add
> Dokploy inside a Lima VM following [Dokploy (later, via Lima)](#dokploy-later-via-lima).

## Quick start

Fresh Mac with nothing installed? One-liner — triggers the Xcode Command
Line Tools prompt (which brings `git`), clones the repo, runs bootstrap:

```bash
curl -fsSL https://raw.githubusercontent.com/hasansezertasan/homelab/main/install.sh | bash
```

Then:

1. Sign in to **Tailscale**:
   - GUI: open Tailscale.app, click "Log in".
   - Headless / phone-driven: run `tailscale login --qr` in Terminal and scan the printed QR with your phone — no browser on the Mac needed.
2. Open **RustDesk** → enable Direct IP Access (see [RustDesk over Tailscale](#rustdesk-over-tailscale)).
3. Run `hermes setup` to pick a model + configure platforms.
4. **OpenChamber UI password** — `bootstrap.sh` prompts for it the first
   time and stores it at `~/.config/homelab/openchamber.password` (mode 600).
   Subsequent runs reuse the stored value, so the script stays idempotent.
   For non-interactive runs, pre-set `OPENCHAMBER_UI_PASSWORD=...` in the
   environment or write the password file yourself. Rotate with
   `rm ~/.config/homelab/openchamber.password && ./bootstrap.sh`.
5. Visit `http://<mac-tailscale-ip>:3000` from your phone.

## What it does

- Installs Homebrew (Apple Silicon, `/opt/homebrew`).
- `brew install`: `git`, `gh`, `mise`, `uv`, `node`, `bun`, `jq`, `ripgrep`, `fd`, `bat`.
- `brew install --cask`: Tailscale, RustDesk, OrbStack.
- Registers Tailscale and RustDesk as macOS **Login Items** so the GUI apps
  relaunch on every reboot (visible/removable under System Settings → General
  → Login Items).
- `curl | bash` (official installers): OpenCode, OpenChamber, Hermes.
- Drops two launchd plists in `~/Library/LaunchAgents/` so OpenCode and
  OpenChamber auto-start on boot. (Hermes gateway plist ships in the repo
  but is opt-in — uncomment one line in `bootstrap.sh` to enable.)
- Prompts (once) for the OpenChamber UI password and stores it at
  `~/.config/homelab/openchamber.password` (mode 600) so re-runs stay
  non-interactive. Set `OPENCHAMBER_UI_PASSWORD` in the env to skip the prompt.
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
If you want HTTPS for the web UI, use `tailscale serve` — see [OpenCode + OpenChamber](#opencode--openchamber).

## Repo layout

```
.
├── bootstrap.sh             # main installer — start here
├── install.sh               # remote curl|bash bootstrap (clones repo + runs bootstrap.sh)
├── teardown.sh              # reverse it (keeps data dirs)
├── status.sh                # health check: binaries, ports, launchd, tailscale
├── mise.toml                # per-project runtime pins
└── launchd/
    ├── dev.openchamber.opencode.plist
    ├── dev.openchamber.openchamber.plist
    └── com.nousresearch.hermes-gateway.plist   (opt-in)
```

Per-tool setup guides live inline at the bottom of this README — see
[Per-tool guides](#per-tool-guides).

## Headless Mac mode

If this Mac is going to live in a closet:

```bash
HOMELAB_HEADLESS=1 ./bootstrap.sh
```

This disables system sleep (incl. clamshell via `pmset disablesleep`), wakes
the Mac when AC power is restored, wakes on lid-open, lets the display sleep
after 10 minutes, and turns on auto-restart-after-freeze. You'll also want, in System Settings:

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

## Per-tool guides

Click to expand.

### RustDesk over Tailscale

<details>
<summary><strong>Direct-IP-access config + macOS permissions</strong></summary>

You're skipping RustDesk's public relay servers. Instead, Tailscale gives
every machine a stable `100.x.x.x` IP and handles NAT traversal + encryption.
You enter that IP into RustDesk's "Control Remote Desktop" box and connect
directly, peer-to-peer. No port forwarding, no hbbs/hbbr servers, no keys.

#### One-time setup on the Mac (the server side)

1. Open **Tailscale.app**, sign in, accept the macOS network extension prompt.
   Note the IP: `tailscale ip -4` (e.g. `100.101.102.103`).
2. Open **RustDesk**:
   - Settings → **Security**:
     - ☑ **Enable Direct IP Access**
     - **Password** → set a permanent password (not "one-time"). Strong one.
   - Settings → **Display** → **Default codec**: pick **H265** (best
     quality/bandwidth), then H264, then VP9. Apple Silicon has VideoToolbox
     hardware decode for H264 and H265 (HEVC); VP9 is software-only on macOS
     and will burn CPU. Greyed-out entries = your build/hardware can't decode
     them.
3. Grant macOS permissions when prompted:
   - System Settings → Privacy & Security → **Screen Recording** → enable RustDesk
   - **Accessibility** → enable RustDesk
   - **Input Monitoring** → enable RustDesk
4. `bootstrap.sh` already registers RustDesk as a macOS **Login Item** so it
   relaunches after every reboot. Verify under **System Settings → General →
   Login Items**. Remove it there if you don't want auto-start. The app's own
   Settings → General → ☑ "Start on boot" is an alternative — pick one, not
   both.

#### From your phone / laptop (the client side)

1. Install Tailscale and sign into the same tailnet.
2. Install RustDesk.
3. Open RustDesk → in the **"Control Remote Desktop"** field, type the Mac's
   `100.x.x.x` Tailscale IP (or `mac-mini.tail-scale.ts.net` works on iOS/Android
   but **not** on RustDesk — it expects raw IPs).
4. Enter the permanent password from step 2 above.

That's it. The session is double-encrypted: WireGuard underneath, RustDesk on top.

#### Troubleshooting

- **"Can't reach host"** — `tailscale ping <mac-ip>` from the client first.
  If that fails, the problem is Tailscale, not RustDesk.
- **Black screen on macOS** — Screen Recording permission isn't granted.
  Reopen System Settings → Privacy & Security → Screen Recording, toggle off+on.
- **Laggy** — switch codec to H265, lower the quality slider, or check
  `tailscale netcheck` to see if you're falling back to a DERP relay.

</details>

### OpenCode + OpenChamber

<details>
<summary><strong>First-time config, PWA install, HTTPS via tailscale serve</strong></summary>

OpenCode is the headless AI coding agent. OpenChamber is the web/PWA UI that
talks to it. The bootstrap runs them as two separate launchd services:

```
┌────────────────────────────────────────────────────────────┐
│  127.0.0.1:4096   opencode serve            (localhost)    │
│         ▲                                                  │
│         │ HTTP                                             │
│  0.0.0.0:3000     openchamber serve         (tailnet)      │
└────────────────────────────────────────────────────────────┘
```

OpenCode binds to localhost only — nothing reaches it except OpenChamber.
OpenChamber binds to `0.0.0.0` so it's reachable from any device on your
tailnet. Tailscale's ACLs are the firewall.

#### How OpenChamber finds OpenCode

The two services share no config file. The coupling lives in
`launchd/dev.openchamber.openchamber.plist` via two environment variables:

- `OPENCODE_HOST=http://127.0.0.1:4096` — tells OpenChamber where the
  already-running OpenCode listener is. If you change the OpenCode port in
  `dev.openchamber.opencode.plist`, change this value to match.
- `OPENCODE_SKIP_START=true` — stops OpenChamber from spawning its own
  bundled OpenCode. Without this, you'd have two OpenCode processes fighting
  over the same project lock files. Leave it `true` as long as the OpenCode
  plist is loaded.

#### First-time config

1. **Set a UI password.** `bootstrap.sh` prompts on first run and stores the
   value at `~/.config/homelab/openchamber.password` (mode 600). Re-runs reuse
   it. Skip the prompt with `OPENCHAMBER_UI_PASSWORD=... ./bootstrap.sh`.
   Rotate by deleting the file and re-running.
2. **Pick a model provider.** Open `http://localhost:3000` (or the tailnet
   URL from your phone), log in with the password, and add an API key.
   OpenCode supports Anthropic, OpenAI, Google, Groq, OpenRouter, Ollama, etc.
3. **Add projects.** Use OpenChamber's "Add Project" → either point at an
   existing folder on the Mac or clone a repo into one.

#### Accessing from the phone

The PWA install flow works well on iOS/Android:
- Visit `http://<mac-tailscale-ip>:3000`
- Tap Share → "Add to Home Screen"
- It becomes an app icon with notifications and keyboard-safe layout

#### Logs

```
tail -f ~/Library/Logs/homelab/opencode.log
tail -f ~/Library/Logs/homelab/openchamber.log
```

#### Restarting after an update

```
launchctl unload ~/Library/LaunchAgents/dev.openchamber.opencode.plist
launchctl unload ~/Library/LaunchAgents/dev.openchamber.openchamber.plist
launchctl load   ~/Library/LaunchAgents/dev.openchamber.opencode.plist
launchctl load   ~/Library/LaunchAgents/dev.openchamber.openchamber.plist
```

Or just `./bootstrap.sh` again — it's idempotent.

#### Optional: enable HTTPS

If you want `https://` instead of plain HTTP over the tailnet, the easiest
path is **Tailscale Serve**:

```
tailscale serve --bg --https 443 http://localhost:3000
```

That gives you `https://<machine>.tail-scale.ts.net` with a real cert,
no Caddy or nginx needed.

</details>

### Hermes Agent (Nous Research)

<details>
<summary><strong>Gateway setup, enabling auto-start</strong></summary>

The killer feature here for a home server: Hermes has a **messaging gateway**
that lets you talk to the agent from Telegram, Discord, Slack, WhatsApp, or
Signal. The Mac runs the agent; you talk to it from your phone, anywhere.

#### First run

```
hermes setup
```

This walks you through:
- Picking a model provider (Nous Portal, OpenRouter, Anthropic, OpenAI, ...)
- Configuring tools
- Optionally migrating from OpenClaw

Then either:
- `hermes` — interactive TUI in your terminal
- `hermes gateway setup && hermes gateway start` — messaging mode

#### Enabling the gateway as a launchd service

By default `bootstrap.sh` does **not** auto-start the gateway, because you need
to add platform credentials first. Once you've done `hermes gateway setup` and
added at least one platform (Telegram is easiest):

1. Edit `bootstrap.sh` and uncomment this line near the bottom:
   ```bash
   # install_plist "com.nousresearch.hermes-gateway"
   ```
2. Re-run `./bootstrap.sh`. The gateway now starts on boot.

#### Why this pairs well with Tailscale

The gateway connects *outbound* to Telegram/Discord/etc., so it doesn't need
inbound network access. You don't even need port forwarding — the agent
running on your Mac can be reached from anywhere just by messaging the bot.

Tailscale matters here for two reasons:
1. **Browser dashboard.** Hermes ships a web UI on `:8080` you can pin to the
   tailnet IP.
2. **SSH backend.** If you set `hermes config terminal_backend ssh`, the
   agent can run commands inside *other* tailnet machines, not just the Mac.

#### Logs

```
tail -f ~/.hermes/logs/hermes.log
```

(The launchd plist also writes to `~/Library/Logs/homelab/hermes.log`.)

</details>

### Dokploy (later, via Lima)

<details>
<summary><strong>Lima VM path for when you want Dokploy</strong></summary>

Dokploy is a Docker-Swarm-based PaaS that officially supports Ubuntu/Debian
only. On Apple Silicon the cleanest path is a lightweight Linux VM via
[Lima](https://lima-vm.io). It's smaller than UTM, scriptable, and shares
your home directory by default.

#### Install Lima

```
brew install lima
```

#### Start an Ubuntu 22.04 VM

```
limactl start --name=dokploy template://ubuntu-lts \
  --cpus=4 --memory=8 --disk=60
```

(Adjust CPU/RAM to taste. Dokploy is light but your apps may not be.)

#### Inside the VM — install Dokploy

```
limactl shell dokploy
sudo apt-get update && sudo apt-get -y upgrade
curl -sSL https://dokploy.com/install.sh | sudo sh
```

#### Reach it from the Mac

Lima auto-forwards ports. Dokploy defaults to `:3000` — same as OpenChamber,
which is hard-coded in `launchd/dev.openchamber.openchamber.plist`. **Change
Dokploy's port** (e.g. forward to `:3001` via Lima's port-forwarding config)
rather than the OpenChamber plist — the rest of the repo's docs assume
OpenChamber on `:3000`.

To reach Dokploy from your phone over the tailnet:

```
# Install Tailscale inside the VM too:
limactl shell dokploy
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Now the VM has its own `100.x.x.x` IP and shows up in your tailnet alongside
the Mac. Bookmark `http://<vm-tailscale-ip>:3000`.

#### Why not Docker Desktop on the Mac?

You could run Dokploy's Docker stack on Docker Desktop, but Dokploy uses
Docker **Swarm** features (services, configs, secrets) and assumes a real
Linux Docker host. The Swarm-on-Docker-Desktop path is fragile. A Lima VM
is closer to how Dokploy expects to run, and migrations to a real VPS or
Asahi later are trivial.

</details>

---

## License

MIT. Fork freely.
