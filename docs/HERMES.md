# Hermes Agent (Nous Research)

The killer feature here for a home server: Hermes has a **messaging gateway**
that lets you talk to the agent from Telegram, Discord, Slack, WhatsApp, or
Signal. The Mac runs the agent; you talk to it from your phone, anywhere.

## First run

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

## Enabling the gateway as a launchd service

By default `bootstrap.sh` does **not** auto-start the gateway, because you need
to add platform credentials first. Once you've done `hermes gateway setup` and
added at least one platform (Telegram is easiest):

1. Edit `bootstrap.sh` and uncomment this line near the bottom:
   ```bash
   # install_plist "com.nousresearch.hermes-gateway"
   ```
2. Re-run `./bootstrap.sh`. The gateway now starts on boot.

## Why this pairs well with Tailscale

The gateway connects *outbound* to Telegram/Discord/etc., so it doesn't need
inbound network access. You don't even need port forwarding — the agent
running on your Mac can be reached from anywhere just by messaging the bot.

Tailscale matters here for two reasons:
1. **Browser dashboard.** Hermes ships a web UI on `:8080` you can pin to the
   tailnet IP.
2. **SSH backend.** If you set `hermes config terminal_backend ssh`, the
   agent can run commands inside *other* tailnet machines, not just the Mac.

## Logs

```
tail -f ~/.hermes/logs/hermes.log
```

(The launchd plist also writes to `~/Library/Logs/homelab/hermes.log`.)
