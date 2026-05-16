# OpenCode + OpenChamber

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

## How OpenChamber finds OpenCode

The two services share no config file. The coupling lives in
`launchd/dev.openchamber.openchamber.plist` via two environment variables:

- `OPENCODE_HOST=http://127.0.0.1:4096` — tells OpenChamber where the
  already-running OpenCode listener is. If you change the OpenCode port in
  `dev.openchamber.opencode.plist`, change this value to match.
- `OPENCODE_SKIP_START=true` — stops OpenChamber from spawning its own
  bundled OpenCode. Without this, you'd have two OpenCode processes fighting
  over the same project lock files. Leave it `true` as long as the OpenCode
  plist is loaded.

## First-time config

1. **Set a real UI password.** Edit
   `launchd/dev.openchamber.openchamber.plist`, find the
   `CHANGE-ME-BEFORE-LOADING` string, replace it with a strong password.
   Then re-run `./bootstrap.sh` to reload the plist.
2. **Pick a model provider.** Open `http://localhost:3000` (or the tailnet
   URL from your phone), log in with the password, and add an API key.
   OpenCode supports Anthropic, OpenAI, Google, Groq, OpenRouter, Ollama, etc.
3. **Add projects.** Use OpenChamber's "Add Project" → either point at an
   existing folder on the Mac or clone a repo into one.

## Accessing from the phone

The PWA install flow works well on iOS/Android:
- Visit `http://<mac-tailscale-ip>:3000`
- Tap Share → "Add to Home Screen"
- It becomes an app icon with notifications and keyboard-safe layout

## Logs

```
tail -f ~/Library/Logs/homelab/opencode.log
tail -f ~/Library/Logs/homelab/openchamber.log
```

## Restarting after an update

```
launchctl unload ~/Library/LaunchAgents/dev.openchamber.opencode.plist
launchctl unload ~/Library/LaunchAgents/dev.openchamber.openchamber.plist
launchctl load   ~/Library/LaunchAgents/dev.openchamber.opencode.plist
launchctl load   ~/Library/LaunchAgents/dev.openchamber.openchamber.plist
```

Or just `./bootstrap.sh` again — it's idempotent.

## Optional: enable HTTPS

If you want `https://` instead of plain HTTP over the tailnet, the easiest
path is **Tailscale Serve**:

```
tailscale serve --bg --https 443 http://localhost:3000
```

That gives you `https://<machine>.tail-scale.ts.net` with a real cert,
no Caddy or nginx needed.
