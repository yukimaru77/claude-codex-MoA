# MoA Observability

Every layer emits structured local telemetry so that a weak model — or a
human with jq — can answer "what failed, where, when, and how to fix it"
without reading code. Nothing leaves this machine.

## First move when ANYTHING misbehaves

```bash
moa diag all
```

It checks every layer in dependency order — config JSON → mode file →
launchd → daemon /health → upstream gateway → EVERY configured model
(real 1-token probes) → end-to-end through each instance — and prints
`PASS`/`FAIL` with the exact fix command per failure. Fix the FIRST
failure; later ones are usually consequences.

## Data files

| File | Writer | What |
|---|---|---|
| `~/.local/share/moa/obs/moa-<instance>.jsonl` | moa-api | one line per API call (schema below); rotates at 50 MB → `.1` |
| `~/.local/share/moa/mode-<instance>` | moa CLI / /moa | current mode (`moa` / `passthrough`) |
| `~/.local/share/moa/launchd.{out,err}.log` | launchd | daemon crashes / stack traces |
| `GET :840x/health` | moa-api | live counters: items by mode, degraded count, per-candidate ok/fail, uptime, boot_id |

All JSONL is guaranteed valid UTF-8 (invalid bytes are dropped at write
time — one bad byte would make grep/awk treat the file as binary and
silently return nothing).

## Item schema — `moa_item` (schema: 2)

- identity: `req_id` (per request), `trace_id` (propagates the client's
  `x-ai-harness-trace` header — joins gateway error dumps), `boot_id`
  (which daemon run), `instance_name`, `ts`/`ts_ms`
- `mode`: `moa` | `passthrough` | `background` | `degraded`;
  `direct: true` = byte-transparent forward to the real provider
- `request`: shape fingerprint — `req_model`, `n_messages`, `n_tools`,
  `max_tokens`, `input_chars`, `last_role`, `last_has_tool_result`
- moa items: `fanout_ms`; `candidates[]` each with `instance` (`model#N`),
  `ok`, `latency_ms`, `stop_reason`, `usage`, `summary` (block-type
  histogram, `text_chars`, `tools_called`) or on failure `http_status`,
  `error`, `error_body`; then `n_survivors`, `synthesizer`,
  `synthesis_input_chars`, `synthesis_ms`, `synthesis_summary`, `total_ms`
- failure markers: `degraded` = `all_candidates_failed` |
  `synthesis_failed` (with `synthesis_http_status` / `synthesis_error` /
  `synthesis_error_body`); `aborted` = `client_disconnected_during_fanout`;
  `moa_fallback_served` / `moa_fallback_failed` events around the
  best-candidate fallback
- other events: `boot` (full effective config), `shutdown`, `mode_change`,
  `client_error`

## Analysis commands

```bash
moa stats 24        # per-candidate ok/fail + p50/p95, synthesis and item totals
moa errors 20 codex # degraded/error items for one instance, newest first
moa logs 20 claude  # raw tail
jq 'select(.mode=="moa") | {ts, total_ms, degraded}' ~/.local/share/moa/obs/moa-claude.jsonl
```

## Runbook

| Symptom | Meaning | Fix |
|---|---|---|
| diag FAIL: daemon not answering | moa-api down / port clash | printed kickstart command; read `launchd.err.log` |
| diag FAIL: upstream gateway unreachable | CrossProviderAgentSetting's cliproxy (:8317) down | kickstart it; `ai-auth status` |
| diag FAIL one model `rate_limit_error`, claude-only | gateway forwarding Claude OAuth without cloak | `disable-claude-cloak-mode: false` in the gateway config, restart it |
| diag FAIL one model `authentication_error` | credential expired in the gateway | `ai-auth login anthropic` / `login openai` / `rotate zai` |
| `degraded: all_candidates_failed` | every candidate errored (see each `error_body`) | usually upstream outage; check gateway health at that time |
| `degraded: synthesis_failed` | candidates fine, synthesizer errored; client got best candidate via fallback | read `synthesis_error_body`; often rate limit on the synthesizer model |
| instant 400 "role 'system' is not supported on this model" | older Anthropic model got Claude Code's mid-conversation system message | should not happen: `coerce_system_messages: true` (default) converts them — if seen, the flag was disabled |
| client shows "Failed to parse JSON" in passthrough | compressed upstream body relayed raw | should not happen: accept-encoding is stripped in direct forwards — if seen, daemon predates that fix |
| everything slow in moa mode | wall clock = slowest candidate + synthesis | `moa stats` shows the slow candidate; remove it or lower `candidate_timeout_s` |
| Codex "failed to refresh available models" | Codex wants its own {"models":[{slug,...}]} catalog, not an OpenAI list | set `models_command` in the codex instance config to `["codex","debug","models"]` (served verbatim, cached at boot) — restart the daemon after editing |
| session ignores /moa | session started before the proxy wiring | restart the CLI (base URL is fixed at process start) |
| daemon refuses to start: "accept_any_local_auth requires a loopback listen_host" | an unauthenticated instance was bound to a routable address (open-relay risk) | set listen_host to 127.0.0.1, or drop accept_any_local_auth |
| passthrough 400 "max_tokens: Field required" (model = your own, no max_tokens) | a non-`/v1/messages` endpoint (e.g. `/v1/messages/count_tokens`) was force-routed to `/v1/messages` | fixed: proxy_direct preserves the client's actual path (`direct_path` in telemetry). If seen, the daemon predates the fix — restart it |
