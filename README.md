# claude-codex-MoA

Item-level **MoA (Mixture of Agents)** proxy for Claude Code and Codex CLI.

Every single step of an agent loop (one API call = one "item") can be
answered by a committee: the identical request fans out to N candidate
models in parallel, then a synthesizer model merges their proposals into
the one response the client receives. Toggle per session with `/moa` —
in "passthrough" mode the proxy is **byte-transparent** (your own login,
your own models, claude.ai connectors intact), so it is safe to keep your
daily-driver `claude` / `codex` permanently routed through it.

```
claude ──▶ :8400 (anthropic protocol) ─┬─ passthrough → api.anthropic.com (your auth, verbatim)
codex  ──▶ :8401 (responses protocol) ─┤
                                       └─ moa → candidates via gateway → synthesizer → one item
```

## Upstream gateway

MoA mode needs an OpenAI/Anthropic-compatible gateway that can serve the
candidate models (cross-provider credentials + protocol conversion). This
repo assumes **[CrossProviderAgentSetting](https://github.com/yukimaru77/CrossProviderAgentSetting)**
(CLIProxyAPI on `127.0.0.1:8317`) — install that first. Any compatible
gateway works by changing `upstream` / `upstream_key_file` in the instance
configs.

## Install

```bash
git clone https://github.com/yukimaru77/claude-codex-MoA.git ~/tasks/claude-codex-MoA
cd ~/tasks/claude-codex-MoA && ./install.sh
moa diag all        # must be all PASS
```

Then (user decision — one line each) route the daily drivers through it:
- Claude: `"ANTHROPIC_BASE_URL": "http://127.0.0.1:8400"` in the `env` of `~/.claude/settings.json`
- Codex: `model_provider = "moa"` + a `[model_providers.moa]` table
  (`base_url = "http://127.0.0.1:8401/v1"`, `wire_api = "responses"`,
  `requires_openai_auth = true`) in `~/.codex/config.toml`

Rollback = remove those lines. AI agents: follow `docs/AGENT_SETUP.md`.

## Use

```
/moa            # in Claude Code or Codex: toggle for the current session (next step)
moa on codex    # same from a terminal
moa status      # live counters per instance
moa stats 24    # aggregates: per-candidate ok/fail + latency percentiles
moa errors      # degraded items, newest first
moa diag all    # layer-by-layer PASS/FAIL with the exact fix per failure
```

Instances are just config files: `~/.config/moa/instances/<name>.json`
(port, protocol `anthropic`|`responses`, candidates with optional
`{"model":..,"count":N}` duplicates, synthesizer, timeouts). Add a file +
restart the LaunchAgent = new proxy. No code changes.

## Observability

Designed so a weak model can diagnose it: per-item JSONL telemetry with
request fingerprints, per-candidate latency/stop_reason/error bodies,
synthesis phases, degradation markers, live counters at `/health`, and a
diag command that prints the fix for every failure. Schemas + runbook:
`docs/OBSERVABILITY.md`.

## Bugs / stuck?

Open a detailed issue at
<https://github.com/yukimaru77/claude-codex-MoA/issues> — include your
instance configs (no secrets), `moa diag all` output, and the relevant
`moa errors` lines (redact tokens). AI agents: ask the user before filing.
