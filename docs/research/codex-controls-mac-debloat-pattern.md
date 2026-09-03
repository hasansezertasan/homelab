# Research: adopting the `codex-controls-mac` tuning pattern

Date: 2026-09-03

Local tracking: [homelab issue #16](https://github.com/hasansezertasan/homelab/issues/16)

## Conclusion

The same overall feature belongs in this homelab. This repository targets a
dedicated, headless Apple Silicon Mac and already exposes optional machine-level
tuning through `HOMELAB_HEADLESS=1`, so an opt-in resource-tuning companion is a
natural extension. The reusable pattern is: document the tradeoffs, provide an
idempotent helper, offer conservative defaults and explicit aggressive flags,
and supply status and rollback paths.

It should not be copied verbatim. Safe resource reclamation should be separated
from Gatekeeper, quarantine, and SIP changes. Those security-sensitive changes
either do not apply to this homelab's normal SSH/LaunchAgent execution path or
have risks and reversibility limits that make them poor bootstrap defaults.

## What the linked work intended

### Issue 3: diagnose `syspolicyd` pressure

[Issue #3](https://github.com/hasansezertasan/codex-controls-mac/issues/3)
is open and proposes documentation for diagnosing suspected Gatekeeper /
`syspolicyd` overhead during subprocess-heavy agent workloads. Its original
proposal listed Full Disk Access, Terminal Developer Tools permission,
recursive quarantine removal, reduced fan-out, and possibly disabling
Gatekeeper, while explicitly asking which mitigations should be defaults versus
opt-ins.

The merged documentation narrowed the causal claim: Gatekeeper assessments are
described as occurring on first launch or when a binary changes, with cached
results for unchanged code, and operators are told to measure `syspolicyd` CPU
before acting. This correction came directly from review feedback that
`fs_usage -f exec` reports activity rather than CPU and cannot prove that every
`exec()` causes a new assessment
([review thread](https://github.com/hasansezertasan/codex-controls-mac/pull/5#discussion_r3803361818),
[final README](https://github.com/hasansezertasan/codex-controls-mac/blob/73c7b550f256e5b646c2063311c14ff3e949e69b/README.md)).

Issue #3 was referenced by PR #5 but was not closed; it remains the unresolved
background discussion rather than a fully settled implementation contract. Its
owner discussion also converged on a hybrid model—Linux containers for headless
work and bare macOS for GUI work—and clarified that churn in distinct or newly
materialized binaries is more relevant than raw process count because unchanged
assessed code is cached
([container discussion](https://github.com/hasansezertasan/codex-controls-mac/issues/3#issuecomment-5326963409),
[process-churn correction](https://github.com/hasansezertasan/codex-controls-mac/issues/3#issuecomment-5327455788)).

### Issue 4: reclaim resources on a dedicated agent Mac

[Issue #4](https://github.com/hasansezertasan/codex-controls-mac/issues/4)
asked for a documented, scriptable, reversible checklist covering Spotlight,
iCloud, Photos/media analysis, Siri and suggestions, login items, Time Machine,
software-update policy, visual effects, analytics, and sleep settings. It asked
for an idempotent `debloat-mac.sh`, clear tradeoffs, and safe/universal versus
aggressive/optional tiers.

Issue #4 is closed by the merged PR. That is the part whose goal and delivery
model most directly transfer to this homelab.

## What PR 5 delivered

[PR #5](https://github.com/hasansezertasan/codex-controls-mac/pull/5)
was merged into `main` on 2026-09-03. It contains three commits, 333 additions,
and two changed files:

- [`README.md`](https://github.com/hasansezertasan/codex-controls-mac/blob/73c7b550f256e5b646c2063311c14ff3e949e69b/README.md):
  136 added lines documenting measurement and mitigation of `syspolicyd`,
  background-service trimming, manual System Settings choices, rollback, and a
  hybrid Linux-container option.
- [`debloat-mac.sh`](https://github.com/hasansezertasan/codex-controls-mac/blob/73c7b550f256e5b646c2063311c14ff3e949e69b/debloat-mac.sh):
  a 197-line interactive/non-interactive helper.

The helper's interface is the main reusable design:

- items 1-3 are preselected: disable Spotlight indexing, disable
  `photoanalysisd`, and reduce motion/transparency;
- Gatekeeper Developer Tools registration, quarantine removal, and the
  SIP-gated `mediaanalysisd` change are opt-in;
- explicit modes include `--safe`, `--gatekeeper`, `--quarantine`,
  `--media-daemon`, `--all`, and `--undo`;
- no-flag interactive runs show a checklist, while no-flag non-interactive runs
  apply only the conservative group;
- service actions distinguish persistent `launchctl disable` in the user domain
  from stopping the live GUI-domain instance with `bootout`;
- the PR reports `bash -n` validation, and its
  [ShellCheck job passed](https://github.com/hasansezertasan/codex-controls-mac/actions/runs/32130923727/job/95691670070).

The review materially improved the documentation. Reviewers required direct CPU
measurement, limited Developer Tools advice to locally launched Terminal
sessions, replaced the invented `~/work` example with an explicit reviewed
directory, completed rollback instructions, preserved the project's managed
LaunchAgent, and qualified the container isolation claim
([Codex findings](https://github.com/hasansezertasan/codex-controls-mac/pull/5#discussion_r3803361821),
[quarantine scope](https://github.com/hasansezertasan/codex-controls-mac/pull/5#discussion_r3803361826),
[service-domain resolution](https://github.com/hasansezertasan/codex-controls-mac/pull/5#discussion_r3803537490),
[container correction](https://github.com/hasansezertasan/codex-controls-mac/pull/5#discussion_r3803384898)).
The only formal reviews were comments rather than approvals; CodeRabbit's first
pass characterized merge risk as moderate and later marked the addressed
threads resolved
([review summary](https://github.com/hasansezertasan/codex-controls-mac/pull/5#pullrequestreview-4960198099)).

## Caveats in the merged upstream helper

The final README is safer and more precise than the final script in several
places, so the script is a pattern to adapt rather than an artifact to vendor:

- The README says Terminal Developer Tools permission applies only to locally
  launched Terminal sessions, not SSH or LaunchAgent-owned sessions. The script
  still labels this a "Gatekeeper exemption" and says it skips repeated checks.
- The README scopes quarantine removal to a specific reviewed checkout. The
  script defaults `DEBLOAT_TREE` to `~/work` and recursively removes the
  attribute.
- The script says everything is reversible, but its quarantine function
  correctly admits that removal is not reversible.
- Disabling `mediaanalysisd` requires turning off SIP. That cost is
  disproportionate for a Tailscale-reachable server and should not be presented
  as normal homelab tuning.

These mismatches are visible in the merged
[`debloat-mac.sh`](https://github.com/hasansezertasan/codex-controls-mac/blob/73c7b550f256e5b646c2063311c14ff3e949e69b/debloat-mac.sh)
alongside the corrected
[`README.md`](https://github.com/hasansezertasan/codex-controls-mac/blob/73c7b550f256e5b646c2063311c14ff3e949e69b/README.md).

## Fit with this homelab

The homelab already owns adjacent behavior:

- `HOMELAB_HEADLESS=1` configures sleep, display sleep, wake-on-AC, and
  restart-after-freeze in `bootstrap.sh`, with a corresponding best-effort
  reversal in `teardown.sh`.
- The README already recommends staying signed out of Apple ID or disabling
  consumer iCloud features.
- Tailscale and RustDesk login items plus OpenCode/OpenChamber/Orca launch jobs
  are intentional infrastructure. Any "trim login items" guidance must
  explicitly preserve them.
- Agent entry points are primarily remote or managed (`launchd`, Tailscale,
  OpenCode, OpenChamber, and Orca), so Terminal-specific Developer Tools advice
  is not a generally applicable performance control here.

## Recommended homelab shape

1. Add a documented optional resource-tuning mode adjacent to the current
   headless mode, using this repo's environment-variable interface rather than
   importing the upstream CLI unchanged (for example, a dedicated opt-in such
   as `HOMELAB_DEBLOAT=1`).
2. Keep conservative resource controls distinct from security controls.
   Spotlight and irrelevant consumer analysis can be considered for the
   conservative tier; Gatekeeper disabling, SIP disabling, and recursive
   quarantine removal should not be automated.
3. Make each change idempotent, expose its current state in `status.sh`, and
   reverse only changes the homelab actually applied. Where the previous value
   can vary, record it instead of restoring a guessed default.
4. Preserve all homelab-managed login items and LaunchAgents explicitly.
5. Treat `syspolicyd` as a diagnostic path: measure with Activity Monitor or
   `top`, correlate with changed/downloaded executables, then offer narrowly
   scoped remediation. Do not imply that every agent subprocess is reassessed.
6. Keep container isolation as separate architecture guidance. It can move
   headless process churn into Linux, but its macOS CLI and VM helpers still run
   on the host and it cannot serve GUI automation workloads.

This yields the useful part of the upstream work—repeatable, visible resource
tuning—without turning a performance option into a blanket reduction of the
host's security posture.
