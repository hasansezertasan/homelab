# Similar Projects & Repositories Research

Research into projects similar to [codex-controls-mac](https://github.com/hasansezertasan/codex-controls-mac) and [homelab](https://github.com/hasansezertasan/homelab) — self-hosted remote dev setups, AI agent hosting, Mac-as-server, and related tooling.

---

## 1. Spare Mac → AI Agent Machine (Most Directly Similar)

These are the closest matches to `codex-controls-mac` — turning a spare Mac into an always-on AI agent box.

| Project | URL | Description | Relevance |
|---------|-----|-------------|-----------|
| **ykdojo/claude-controls-mac** | https://github.com/ykdojo/claude-controls-mac | The original — step-by-step guide to turning a spare Mac into an always-on Claude Code machine with SSH, Remote Control, computer use, clipboard sync. `codex-controls-mac` is a direct port of this. | **Direct inspiration** |
| **Travis Media guide** | https://travis.media/blog/mac-homelab-ai-agent-server/ | "Turn an Old MacBook Pro Into a 24/7 AI Agent Server" — detailed guide for running Hermes and OpenClaw on a spare/broken-screen MacBook. Covers sleep prevention, network, launchd services. | **Very high** — same concept, different agents |
| **Mac Mini AI Server guides** | https://hyperbox.sh/blog/mac-mini-home-server-ai-agents <br> https://www.myaiagentos.com/blog/mac-mini-ai-server-setup-guide-2026 <br> https://prommer.net/en/tech/guides/mac-mini-ai-agent-server/ | Multiple 2026 guides on running Claude Code, Hermes, and OpenClaw on a Mac mini as an always-on server. | **High** — same pattern, Mac mini instead of MacBook |
| **Astropad headless Mac mini guide** | https://astropad.com/blog/headless-mac-mini-setup-guide/ | "How to Set Up a Headless Mac mini for AI Agents [2026 Guide]" — focused on headless/clamshell operation. | **High** |

---

## 2. AI Agent Mission Control / Orchestrators

These manage fleets of AI coding agents — the orchestration layer your `homelab` setup needs.

| Project | URL | Description | Relevance |
|---------|-----|-------------|-----------|
| **Codeman** | https://github.com/Ark0N/Codeman | Self-hosted mission control for AI coding agents. Spawns Claude Code, OpenCode, Codex, Gemini, Pi, Grok inside persistent tmux sessions, streams real terminals to any browser, re-prompts on idle, auto-resumes on usage-limit reset. Mobile-optimized UI, QR auth, REST API (~190 endpoints). MIT, one-line install on macOS/Linux. | **Very high** — does what `homelab` does but as a full product |
| **amux** | https://github.com/mixpeek/amux | Open-source control plane for AI coding agents. SQLite-backed kanban, tmux session per agent, web + mobile dashboard, self-healing recovery. Single Rust binary. MIT. | **Very high** — parallel agent orchestration with dashboard |
| **dev-3.0** | https://github.com/h0x91b/dev-3.0 | "Mission control for the One Person Studio" — fleet of AI coding agents in parallel, Kanban + git worktrees + tmux. Each task gets its own worktree/terminal/agent. | **High** — similar parallel-agent philosophy |
| **Mission Control (builderz-labs)** | https://github.com/builderz-labs/mission-control | Self-hosted control plane: dispatch tasks, review runs, track spend, operate Claude Code/Codex/etc. SQLite-backed, RBAC, cron, webhooks, pipelines. Alpha. | **High** |
| **Orca** | https://www.onorca.dev / https://github.com/stablyai/orca | Agent Development Environment (ADE). Parallel agents in isolated git worktrees, GitHub/Linear integration, browser previews, task dispatch. 63k+ stars. Already in your homelab stack. | **Direct component** |

---

## 3. Remote Phone/Mobile Control for AI Agents

Control your agent box from your phone — a key feature of both your repos.

| Project | URL | Description | Relevance |
|---------|-----|-------------|-----------|
| **Forge Remote** | https://apps.apple.com/us/app/forge-remote/id6760141378 | iOS app — mobile command center for AI coding agents. Connects to Claude Code, Aider, or Codex CLI sessions. Push notifications for permission approvals, real-time monitoring, remote instructions. | **Very high** — phone control for agent sessions |
| **codex-remote-control-lab** | https://github.com/Sunwood-ai-labs/codex-remote-control-lab | Local-first Codex app-server and token-protected LAN phone bridge. Phone browser operates desktop Codex without exposing it to LAN. Thread sync between desktop and phone. | **High** — same phone-control pattern for Codex |
| **codex-mobile-remote-control-vm** | https://github.com/Sunwood-ai-labs/codex-mobile-remote-control-vm | Codex skill for setting up Ubuntu VMs controllable from the ChatGPT/Codex mobile app. | **Medium** |
| **OpenChamber** | https://github.com/openchamber/openchamber / https://openchamber.dev | Web/PWA/desktop/mobile frontend for OpenCode. Private Relay (no port opening), QR code pairing, e2e encryption. Already in your homelab stack. | **Direct component** |
| **AgentsRoom** | https://agentsroom.dev/features/remote-agent-control | Remote control for Claude, Codex, Antigravity agents from phone. | **Medium** |

---

## 4. Computer Use / macOS Automation MCP Servers

Enable AI agents to see and control the desktop — used in `codex-controls-mac` step 11.

| Project | URL | Description | Relevance |
|---------|-----|-------------|-----------|
| **computer-use-mcp (zavora-ai)** | https://github.com/zavora-ai/computer-use-mcp | High-performance MCP server for Windows/macOS control in Rust. 64 tools: screenshot, mouse, keyboard, clipboard, app management, accessibility tree. The one used in `codex-controls-mac`. | **Direct component** |
| **macos-harness (browser-use)** | https://github.com/browser-use/macos-harness | Thinnest harness giving an LLM full Mac control. Accessibility tree, AppleScript, screenshots, raw coordinate input. Virtual cursor (doesn't move your real mouse). Python 3.12. | **Very high** — alternative computer-use approach |
| **MacOS-MCP (CursorTouch)** | https://github.com/CursorTouch/MacOS-MCP | Lightweight MCP server for computer use on macOS. File navigation, app control, UI interaction, browser automation. | **High** |
| **mac-use-mcp** | https://github.com/antbotlab/mac-use-mcp | Zero-dep macOS desktop automation MCP server — 18 tools for mouse, keyboard, screen control. `npx mac-use-mcp`. | **High** |
| **applescript-mcp (peakmojo)** | https://github.com/peakmojo/applescript-mcp | MCP server for running AppleScript — full Mac control via Apple Events. Simple, minimal setup. | **Medium** |
| **macos-automator-mcp (steipete)** | https://github.com/steipete/macos-automator-mcp | MCP server for AppleScript and JXA (JavaScript for Automation) on macOS. | **Medium** |
| **Mac Agent (AgentiLoop)** | https://github.com/macos26/agent | Native macOS 26 agentic AI harness. 27 years of Mac automation experience — Apple Events, ScriptingBridge, Accessibility APIs, XPC. 18+ LLM providers. | **High** — native Mac computer-use, different approach |
| **MacOS-Agent (Computer-use-agents)** | https://github.com/Computer-use-agents/MacOS-Agent | Natural language control of macOS applications (Finder, TextEdit, Preview, etc.). | **Medium** |
| **agent-browser (Vercel)** | https://github.com/vercel-labs/agent-browser | Browser automation CLI for AI agents, MCP server over stdio. | **Medium** |
| **BrowserMCP** | https://github.com/browsermcp/mcp | MCP server + Chrome extension for AI applications to control your browser. | **Medium** |

---

## 5. Self-Hosted Open-Source AI Coding Agents

The actual agents you'd run on the box. Relevant to what `homelab` installs.

| Project | URL | Description | Relevance |
|---------|-----|-------------|-----------|
| **OpenCode** | https://github.com/anomalyco/opencode | Terminal AI coding agent (TUI + CLI). Headless server mode (`opencode serve --port 4096`), OpenAPI spec, JS/TS SDK. MCP servers, LSP, plugins. Already in your homelab stack. | **Direct component** |
| **Hermes Agent** | https://github.com/NousResearch/hermes-agent / https://hermes-agent.ai | Open-source self-improving AI agent by Nous Research. Memory, skills, cron, web dashboard, GitHub workflows, messaging channels. Single-command macOS install. Already in your homelab stack. | **Direct component** |
| **Hermes Studio** | https://github.com/JPeetz/Hermes-Studio | Web UI & dashboard for Hermes Agent — chat, memory, skills, terminal, approvals, multi-agent orchestration. Self-hosted PWA. | **High** — frontend for Hermes |
| **Hermes WebUI** | https://github.com/nesquena/hermes-webui | Alternative web UI for Hermes Agent with session-recall and gateway routing. | **Medium** |
| **OpenHands** | https://github.com/OpenHands/openhands | MIT-licensed autonomous AI coding agent. Runs in isolated Docker sandbox (terminal, editor, browser, file system). 70k+ stars. Web UI included. | **High** — most popular self-hosted agent |
| **Goose** | https://github.com/aaif-goose/goose (was block-goose) | Open-source agent from Block → Linux Foundation. CLI, desktop app, API. 70+ MCP extensions, 15+ model providers, Ollama for local. Apache 2.0, 53k+ stars. | **High** |
| **Aider** | https://github.com/paul-gauthier/aider | Terminal AI coding agent, git-native. 45k+ stars. Works with local models via Ollama. Apache 2.0. | **High** |
| **Tabby** | https://github.com/TabbyML/tabby | Self-hosted AI coding assistant (Copilot alternative). Standalone binary, Docker, or Homebrew. No external dependencies. 33k+ stars. Apache 2.0. | **Medium** — completion assistant, not agent |

---

## 6. Mac Bootstrap / Homelab Setup Scripts

Similar to your `homelab` repo's one-shot bootstrap approach.

| Project | URL | Description | Relevance |
|---------|-----|-------------|-----------|
| **jiwidi/homelab** | https://github.com/jiwidi/homelab | Homelab on M4 Mac mini — `master_install.sh` one-time bootstrap, Docker containers, GPU-accelerated llama.cpp on host. | **Very high** — same concept, different stack |
| **geerlingguy/mac-dev-playbook** | https://github.com/geerlingguy/mac-dev-playbook | Most popular Mac provisioning via Ansible. Tested on 20+ Macs. CI-tested on GitHub Actions macOS. | **Medium** — dev setup, not AI-focused |
| **chaudhryjunaid/setup-apple-silicon-mac** | https://github.com/chaudhryjunaid/setup-apple-silicon-mac | Machine setup scripts for Apple Silicon Macs — brew-cli.sh, brew-cask.sh, etc. | **Medium** |
| **deild/mac-bootstrap** | https://github.com/deild/mac-bootstrap | Shell script to provision a new macOS machine. Idempotent. | **Medium** — general Mac setup |
| **joshukraine/mac-bootstrap** | https://github.com/joshukraine/mac-bootstrap | Mac provisioning — Homebrew, asdf, postgres via Homebrew Bundle. | **Low** — dev-focused, no AI |

---

## 7. Tailscale + AI Agent Remote Access

Tailscale is central to your `homelab` — these combine it with AI agent workflows.

| Project | URL | Description | Relevance |
|---------|-----|-------------|-----------|
| **Aperture by Tailscale** | https://tailscale.com/use-cases/securing-ai | Tailscale's AI Gateway — supports Claude Code, Codex, Gemini CLI. Route self-hosted and hosted models through tailnet. | **High** — official Tailscale AI integration |
| **Remote AI Coding with Tailscale SSH** | https://tsoporan.com/blog/remote-ai-development-claude-code-tailscale/ | Blog guide: Claude Code + Tailscale SSH for remote AI development from anywhere. | **High** — same pattern |
| **Claude Code Home Server + n8n + Tailscale** | https://johnnybilotta.com/projects/250520-local-llm-build/claude-code-home-server-n8n-tailscale/ | Distributed AI agent network combining Claude Code, n8n automation, and Tailscale mesh. | **High** |
| **WSL2 + tmux + Tailscale guide** | https://note.com/calque039/n/n083cd715adac?hl=en | Remote environment for agentic coding using WSL2 + tmux + Tailscale (Windows-focused). | **Medium** |
| **Remote coding environment on VPS** | https://ma.ttias.be/remote-coding-environment-vps/ | Setting up a remote environment for agentic coding on a VPS with Tailscale. | **Medium** |

---

## 8. Claude Code / Codex Headless & Remote Patterns

Guides and tools for running AI coding agents headlessly on remote servers.

| Project | URL | Description | Relevance |
|---------|-----|-------------|-----------|
| **Claude in the Cloud gist** | https://gist.github.com/alxpck/d1e86d9a62e3fc5cf6c1ce52d0a02b10 | tmux + ssh (or mosh) for persistent, autonomous Claude Code sessions on remote servers. | **High** |
| **amux headless guide** | https://amux.io/guides/claude-code-headless/ | "Claude Code Headless Mode: The Complete Self-Hosting Guide (2026)" — comprehensive reference. | **High** |
| **Self-Hosted AI Coding Agent ($25/mo)** | https://umesh-malik.com/blog/self-hosted-ai-coding-agent-sandbox | Sandboxed prompt-to-deploy for $25/mo on a VPS. | **Medium** |
| **Hyperbox (hosted service)** | https://hyperbox.sh | $40/mo pre-configured Mac mini in a data center with Claude Code, Cursor, Codex pre-installed. SSH, VNC, desktop access. The hosted alternative to self-hosting. | **Medium** — commercial alternative to DIY |

---

## 9. Ephemeral macOS CI / VM Infrastructure

Not directly AI-agent-focused but relevant infrastructure for running isolated workloads on Mac.

| Project | URL | Description | Relevance |
|---------|-----|-------------|-----------|
| **Cilicon (Trade Republic)** | https://github.com/traderepublic/Cilicon | Self-hosted ephemeral macOS CI on Apple Silicon. Uses Apple Virtualization Framework for near-native VMs. GitHub Actions provisioner. 1.2k stars. | **Medium** — CI-focused but same Mac infra pattern |
| **apple/container** | https://github.com/apple/container | Apple's official Linux container tool for macOS — lightweight VMs on Apple Silicon. Referenced in `codex-controls-mac` as a hybrid option. | **Medium** |

---

## 10. Curated Lists & Ecosystem References

| Resource | URL | Description |
|----------|-----|-------------|
| **awesome-cli-coding-agents** | https://github.com/bradagi/awesome-cli-coding-agents | 80+ CLI coding agents directory — agents, harnesses, orchestrators, parallel runners. The definitive list. |
| **awesome-agent-orchestrators** | https://github.com/andyrewlee/awesome-agent-orchestrators | List of agent orchestrators — multica, Clawe, Factory, amux, etc. |
| **9 Open-Source AI Coding Agents Worth Self-Hosting** | https://securityboulevard.com/2026/06/9-open-source-ai-coding-agents-worth-self-hosting/ | Roundup article comparing Goose, Tabby, Aider, OpenHands, etc. |
| **OpenCode Frontends Comparison** | https://arceapps.com/blog/opencode-frontends-comparison-2026/ | Honest comparison of OpenChamber, CodeNomad, nomacode, opencode-mobile. |
| **The Homelab AI Stack in 2026** | https://dev.to/signal-weekly/the-homelab-ai-stack-in-2026-what-self-hosters-are-actually-running-2d58 | What self-hosters are actually running — Ollama, Docker Compose, K3S, etc. |

---

## Summary: Most Relevant Projects

**Closest to `codex-controls-mac`:**
1. [ykdojo/claude-controls-mac](https://github.com/ykdojo/claude-controls-mac) — direct inspiration
2. [Travis Media Mac homelab guide](https://travis.media/blog/mac-homelab-ai-agent-server/) — same concept, different agents
3. [browser-use/macos-harness](https://github.com/browser-use/macos-harness) — alternative computer-use approach

**Closest to `homelab`:**
1. [Ark0N/Codeman](https://github.com/Ark0N/Codeman) — most feature-complete agent mission control
2. [mixpeek/amux](https://github.com/mixpeek/amux) — parallel agent control plane, single binary
3. [jiwidi/homelab](https://github.com/jiwidi/homelab) — Mac mini homelab bootstrap, similar philosophy
4. [h0x91b/dev-3.0](https://github.com/h0x91b/dev-3.0) — kanban + worktrees + tmux fleet

**Worth watching:**
- [Forge Remote](https://apps.apple.com/us/app/forge-remote/id6760141378) — iOS app for agent control
- [Hyperbox](https://hyperbox.sh) — hosted Mac mini service ($40/mo alternative to self-hosting)
- [Aperture by Tailscale](https://tailscale.com/use-cases/securing-ai) — official Tailscale AI gateway
