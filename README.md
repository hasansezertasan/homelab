# homelab

One-shot bootstrap for turning a clean Apple Silicon MacBook into a personal
home server running:

| Layer       | Tool                                                    | Purpose                                         |
| ----------- | ------------------------------------------------------- | ----------------------------------------------- |
| Network     | [Tailscale](https://tailscale.com)                      | Mesh VPN — the only thing reachable from afar   |
| Remote GUI  | [RustDesk](https://rustdesk.com)                        | Desktop access over the tailnet, no relay needed|
| AI agent    | [Hermes](https://github.com/NousResearch/hermes-agent)  | Web dashboard, desktop app, or terminal TUI     |
| Coding (cli)| [OpenCode](https://opencode.ai)                         | Headless AI coding agent on `:4096`             |
| Coding (UI) | [OpenChamber](https://openchamber.dev)                  | Web/PWA frontend for OpenCode on `:3000`        |
| Coding (UI) | [Orca](https://onorca.dev) *(opt-in alt to OpenChamber)*| Parallel-agent ADE; headless `orca serve` on `:6768` |
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
3. Run `hermes setup` to pick a model provider, then use `hermes desktop`
   (Electron app) or `hermes dashboard` (web UI on `127.0.0.1:9119`).
4. **OpenChamber UI password** — `bootstrap.sh` prompts for it the first
   time and stores it at `~/.config/homelab/openchamber.password` (mode 600).
   Subsequent runs reuse the stored value, so the script stays idempotent.
   For non-interactive runs, pre-set `OPENCHAMBER_UI_PASSWORD=...` in the
   environment or write the password file yourself. Rotate with
   `rm ~/.config/homelab/openchamber.password && ./bootstrap.sh`.
5. Visit `http://<mac-tailscale-ip>:3000` from your phone.

## What it does

- Installs Homebrew (Apple Silicon, `/opt/homebrew`).
- `brew bundle` against `./Brewfile` — formulae (`git`, `gh`, `mise`, `uv`,
  `node`, `bun`, `jq`, `ripgrep`, `fd`, `bat`, `zoxide`, `ctx7`, `opencode`,
  `hermes-agent`) + casks (`tailscale-app`, `rustdesk`, `orbstack`, `orca`).
  See `Brewfile` for the canonical list.
- Registers Tailscale and RustDesk as macOS **Login Items** so the GUI apps
  relaunch on every reboot (visible/removable under System Settings → General
  → Login Items).
- `curl | bash` (official installer): OpenChamber.
- Drops two launchd plists in `~/Library/LaunchAgents/` so OpenCode and
  OpenChamber auto-start on boot. (Hermes has no launchd job — you launch it
  on demand via `hermes desktop` or `hermes dashboard`.)
- Prompts (once) for the OpenChamber UI password and stores it at
  `~/.config/homelab/openchamber.password` (mode 600) so re-runs stay
  non-interactive. Set `OPENCHAMBER_UI_PASSWORD` in the env to skip the prompt.
- Optional: with `HOMELAB_ORCA=1`, drops a launchd plist that runs Orca's
  headless runtime (`orca serve`) on `:6768` over the tailnet — a parallel-agent
  alternative to OpenChamber. Off by default; OpenChamber stays the running
  default. See [Orca](#orca-parallel-agent-ade).
- Optional: with `HOMELAB_HEADLESS=1`, disables sleep and configures the Mac
  to wake on power and restart-after-freeze — closer to a real server. Display
  blanks after `HOMELAB_DISPLAYSLEEP` minutes (default `2`; set `0` to never
  blank).
- Installs Claude Code skill packs via `npx skills add` — currently
  [`obra/superpowers`](https://github.com/obra/superpowers). Edit the
  `SKILL_PACKS` array in `bootstrap.sh` §7 to add more.

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
| `zoxide`   | Smarter `cd` — jump to frecent dirs. Add `eval "$(zoxide init zsh)"` to `~/.zshrc`. |
| `ctx7`     | Context7 CLI — pull up-to-date library docs into agents and the shell. |
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
        │  Hermes     dashboard :9119 (localhost only)  │
        │  OpenCode   :4096   (localhost only)          │
        │  OpenChamber :3000  (tailnet)                 │
        │  Orca       :6768   (tailnet, opt-in)         │
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
    └── dev.onorca.orca.plist                   (opt-in — HOMELAB_ORCA=1)
```

Per-tool setup guides live inline at the bottom of this README — see
[Per-tool guides](#per-tool-guides).

## Headless Mac mode

If this Mac is going to live in a closet:

```bash
HOMELAB_HEADLESS=1 ./bootstrap.sh                         # default: display blanks after 2 min
HOMELAB_HEADLESS=1 HOMELAB_DISPLAYSLEEP=5 ./bootstrap.sh   # custom timer
HOMELAB_HEADLESS=1 HOMELAB_DISPLAYSLEEP=0 ./bootstrap.sh   # never blank the display
```

This disables system sleep (incl. clamshell via `pmset disablesleep`), wakes
the Mac when AC power is restored, wakes on lid-open, lets the display sleep
after `HOMELAB_DISPLAYSLEEP` minutes (default `2`, `0` = never), and turns on
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
- **Hermes** is the brain that lives on the box — drive it from its web
  dashboard or desktop app (or the terminal TUI), and it remembers across
  sessions thanks to the Honcho-backed memory loop.
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

### Orca (parallel-agent ADE)

<details>
<summary><strong>Opt-in headless runtime, tailnet pairing, mobile companion</strong></summary>

[Orca](https://onorca.dev) is an ADE for driving a *fleet* of coding agents
(Claude Code, Codex, OpenCode, …) in parallel, each in its own git worktree. It
ships as a desktop app (installed by the `orca` cask in the `Brewfile`, which
also puts the `orca` CLI at `/opt/homebrew/bin/orca`) and has a mobile companion
app for watching agents from your phone.

It's an **opt-in alternative to OpenChamber**, not a replacement — both stay
installable, and OpenChamber remains the running default. The difference:

- **OpenChamber** is a thin web/PWA UI over the *one* OpenCode listener on
  `:4096` (see [OpenCode + OpenChamber](#opencode--openchamber)).
- **Orca** brings its **own** agent runtime. `orca serve` does *not* connect to
  the homelab's OpenCode `:4096` — it starts and manages its own agents. Run
  both at once if you like; `:6768` and `:3000` don't collide.

#### Enabling the headless runtime

The `orca serve` launchd job is off by default. Turn it on:

```bash
HOMELAB_ORCA=1 ./bootstrap.sh
```

This installs `launchd/dev.onorca.orca.plist`, which runs:

```bash
orca serve --port 6768 --pairing-address <your-tailnet-ip>
```

The server binds `0.0.0.0:6768`. Note `orca serve` has **no bind-host flag**, so
unlike the OpenChamber plist you can't pin it to the tailnet interface — on a
non-tailnet network the port is reachable by the local LAN too. The real access
control here is Orca's **pairing**: a client can't drive agents without a paired
E2EE credential (see below), so an unpaired peer that merely reaches the socket
can't do anything. Keep the Mac on your tailnet and treat pairing offers as
secrets. `--pairing-address` is only the address *advertised to clients* — it
does not change the bind address.

> **Needs a logged-in GUI session.** `orca serve` is an Electron process run as
> a launchd *LaunchAgent*, so it only runs while you're logged into the Mac's
> GUI session — same as the OpenChamber/OpenCode agents, but Orca is heavier. A
> truly headless Mac with no auto-login won't start it; enable auto-login or
> keep a GUI session active.

**Pairing address resolution**, in order:

1. `ORCA_PAIRING_ADDRESS=100.x.x.x` in the environment, if set.
2. Otherwise `tailscale ip -4` (so **sign in to Tailscale first**).
3. If neither is available the Orca step is skipped with a warning — the rest
   of the bootstrap still succeeds. Re-run once Tailscale is up.

Override the port with `HOMELAB_ORCA_PORT=...` (default `6768`).

#### Pairing a device

On start, `orca serve` prints a one-time **pairing offer** — an
`orca://pair?code=...` link — to its log. Read it into a variable (so the
credential stays off-screen and out of your clipboard) and pass it along:

```bash
# read the latest offer from the launchd log into a shell variable
code=$(grep -o 'orca://pair?[^ ]*' ~/Library/Logs/homelab/orca.log | tail -1)

# pair this machine's CLI (or another Mac) to the runtime
orca environment add --name mac --pairing-code "$code"
```

The **mobile companion app** is the cleaner path — it keeps the credential out
of argv and shell history entirely. Run `orca serve --mobile-pairing` in a
terminal (stop the launchd job first so the port is free) to print a
phone-scoped QR/link, then scan it in the app.

> **Security.** A pairing offer is a device credential with E2EE material —
> anyone who has it can drive your agents. Two exposure points to mind:
> `~/Library/Logs/homelab/orca.log` contains the offer (treat that log as a
> secret — don't paste it into shared channels or proxy access logs), and
> passing `--pairing-code` on the command line records it in your shell history
> and process list. Prefer the mobile QR path; if you use the CLI, clear the
> command from history afterward (e.g. zsh `print -rz` avoidance, or trim
> `~/.zsh_history`). Rotate by restarting the service (below), which mints a
> fresh offer.

#### Logs

```bash
tail -f ~/Library/Logs/homelab/orca.log
tail -f ~/Library/Logs/homelab/orca.err
```

#### Restarting

```bash
launchctl unload ~/Library/LaunchAgents/dev.onorca.orca.plist
launchctl load   ~/Library/LaunchAgents/dev.onorca.orca.plist
```

Or `HOMELAB_ORCA=1 ./bootstrap.sh` again — it's idempotent. The desktop app
itself auto-updates (Homebrew cask `auto_updates`), so `brew bundle` won't fight
it.

#### Disabling

Dropping `HOMELAB_ORCA` on a later run does **not** stop an already-installed
Orca service — `bootstrap.sh` only ever adds it. To stop and remove the service:

```bash
launchctl unload ~/Library/LaunchAgents/dev.onorca.orca.plist
rm ~/Library/LaunchAgents/dev.onorca.orca.plist
```

`teardown.sh` does the same unload+remove. Either way the Orca **app** is left
installed (it doubles as a standalone ADE) — remove it with
`brew uninstall --cask orca` if you want it gone.

</details>

### Hermes Agent (Nous Research)

<details>
<summary><strong>Dashboard, desktop app, terminal TUI</strong></summary>

Hermes is the agent that lives on the box. Three ways to drive it, all local
to the Mac (reach the GUI from afar via RustDesk over the tailnet):

- `hermes` — interactive chat in your terminal (classic REPL;
  `hermes --tui` for the modern TUI)
- `hermes desktop` — Electron desktop app
- `hermes dashboard` — web UI on `127.0.0.1:9119` (manage config, API keys,
  sessions)

#### First run

```
hermes setup
```

This walks you through:
- Picking a model provider (Nous Portal, OpenRouter, Anthropic, OpenAI, ...)
- Configuring tools
- Optionally migrating from OpenClaw

Then launch whichever surface you prefer:

```
hermes desktop          # Electron app
hermes dashboard        # web UI on 127.0.0.1:9119
hermes dashboard --status   # list / --stop to stop running web servers
```

#### Why local-only

`hermes dashboard` binds `127.0.0.1` by default. The old `--insecure` flag is
a **no-op** as of the June 2026 hardening — a non-loopback bind now *requires*
an auth provider (password or OAuth), so exposing it raw over the tailnet isn't
possible anyway. Keep the dashboard on loopback and reach it through the
RustDesk desktop session; that's the simplest secure story and needs no
launchd job.

> If you later want the dashboard reachable from other tailnet devices'
> browsers, front the loopback listener with `tailscale serve` — it keeps the
> bind on `127.0.0.1` and adds TLS. Only bind `0.0.0.0` if you really need a
> LAN listener, and register an auth provider first (`hermes dashboard
> register` wires up Nous Portal OAuth).

#### Logs

```
tail -f ~/.hermes/logs/hermes.log
```

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

### Optio (later, via OrbStack Kubernetes)

<details>
<summary><strong>Kubernetes path for when you want Optio</strong></summary>

[Optio](https://optio.host) ([source](https://github.com/jonwiggins/optio),
MIT) is workflow orchestration for AI coding agents — it drives a ticket
from creation through a merged PR, watches the PR, feeds CI failures back
to the agent, and resumes on conflicts or review feedback. It's the
supervisor layer that sits on top of agents like OpenCode, Claude Code,
Codex, Copilot, or Gemini, which makes it a natural complement to the
OpenCode + Hermes pair this homelab already runs.

It's deferred for the same reason Dokploy is: runtime mismatch. The rest
of the stack is `launchd` + native binaries. Optio ships as a Helm chart
and assumes a Kubernetes cluster (Next.js dashboard on `:3100`, Fastify
API on `:30400`, BullMQ workers, Postgres, Redis, one pod per repo). That's
a new dependency class, so it lives outside `bootstrap.sh` until you opt in.

#### Enable Kubernetes in OrbStack

OrbStack (already installed via the `Brewfile`) ships a built-in
Kubernetes distribution — no Docker Desktop required.

```
orb start k8s
kubectl config use-context orbstack
kubectl get nodes
```

(Allocate CPU/RAM in OrbStack Settings → Resources. Optio's components are
modest, but agent pods spawned per repo will want headroom — start with
4 CPU / 8 GB and grow.)

#### Install Optio via Helm

Follow the upstream Helm instructions in
[jonwiggins/optio](https://github.com/jonwiggins/optio) — they're the
source of truth and will drift faster than this README. The shape is:

```
helm repo add optio https://jonwiggins.github.io/optio
helm repo update
helm upgrade --install optio optio/optio \
  --namespace optio --create-namespace \
  --values ./optio-values.yaml
```

Keep your `optio-values.yaml` out of this repo — it'll contain GitHub
tokens, agent API keys, and the dashboard admin secret. Stash it under
`~/.config/homelab/optio-values.yaml` (mode 600) for symmetry with the
existing secret-handling pattern.

#### Reach it from the tailnet

Optio's UI defaults to `:3100`. OrbStack's k8s exposes services on
`localhost` by default; to make it reachable from your phone over the
tailnet, expose the Mac's port (Tailscale's mesh handles the rest — no
public ingress, ACLs are the firewall):

```
kubectl -n optio port-forward --address 0.0.0.0 svc/optio-web 3100:3100
```

Bookmark `http://<mac-tailscale-ip>:3100`. For a long-lived setup, wrap
the `kubectl port-forward` in a launchd plist alongside the existing ones
— but only after Optio settles into your workflow; a per-session forward
is fine for evaluation.

#### Why not bake it into `bootstrap.sh`?

Three reasons, all soft:

1. **Idempotency contract.** Every step in `bootstrap.sh` guards on
   `command -v` or app paths and reloads launchd via unload-then-load.
   `helm upgrade --install` is idempotent, but cluster state (CRDs, PVCs,
   stuck pods) isn't, and `teardown.sh` would need a real uninstall path.
2. **State surface.** Postgres + Redis volumes + agent credentials are a
   bigger blast radius than the current "delete `~/.opencode` and you're
   clean" model.
3. **Audience.** Optio is opinionated about workflow — you want it after
   you've decided "yes, I want autonomous PR loops on my tailnet,"
   not as a default of the bootstrap.

If you end up running Optio long-term and want it managed alongside the
other services, the right move is a dedicated `homelab-optio` repo (or a
`contrib/` directory here) that owns its values file, Helm hooks, and the
port-forward plist — not new sections in `bootstrap.sh`.

</details>

---

## License

MIT. Fork freely.
