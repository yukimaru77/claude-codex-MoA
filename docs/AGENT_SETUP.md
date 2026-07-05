# AGENT_SETUP.md — instructions for an AI agent installing claude-codex-MoA

You are an AI coding agent. Set up the MoA proxies on this machine. Work
autonomously; ask the user only for account-level decisions. NEVER print
API keys or tokens. macOS/launchd is the reference platform (translate to
systemd user units on Linux).

## Phase 0 — prerequisite: the upstream gateway

MoA mode needs a gateway serving the candidate models on an
OpenAI/Anthropic-compatible API. Default assumption:
**CrossProviderAgentSetting** (CLIProxyAPI on 127.0.0.1:8317) is installed
with credentials registered (`ai-auth status` shows Claude/Codex/GLM ok).
If it is missing, install it first (its own AGENT_SETUP.md) or set
`upstream` + `upstream_key_file` in the instance configs to another
compatible gateway.

## Phase 1 — install

```bash
git clone https://github.com/yukimaru77/claude-codex-MoA.git ~/tasks/claude-codex-MoA
cd ~/tasks/claude-codex-MoA && ./install.sh
```

install.sh copies instance configs to `~/.config/moa/instances/` (only if
absent), links `moa` into `~/.local/bin`, installs `/moa` for Claude
(`~/.claude/commands/moa.md`) and Codex (`~/.codex/prompts/moa.md`), the
`moa` skill into `~/.agents/skills/moa` (+ `~/.codex/skills` symlink), and
renders + bootstraps the `com.<user>.moa` LaunchAgent.

## Phase 2 — verify the daemon

`moa diag all` must print PASS on every line. Fix failures top to bottom
using the printed fix commands (docs/OBSERVABILITY.md has the runbook).

## Phase 3 — instance policy

- claude instance (:8400): candidates may include Claude models; synthesizer
  default `claude-fable-5`.
- codex instance (:8401): candidates are GPT/GLM ONLY — never route Claude
  models through the Codex harness.
- Candidate counts: `{"model": "...", "count": 2}` runs two independent
  samples. Any change = edit JSON + `launchctl kickstart -k gui/$(id -u)/com.<user>.moa`.

## Phase 4 — entry commands (default; do NOT touch plain claude/codex)

install.sh links `claude-moa` and `codex-moa` into `~/.local/bin`. They are
transparent wrappers: no config-dir isolation, no injected tokens, no model
pins — the user's normal skills, MCP servers, sessions, and login are shared
verbatim; only ANTHROPIC_BASE_URL (claude) or an inline `-c` model_provider
(codex) points at the proxy. NEVER modify ~/.claude/settings.json or
~/.codex/config.toml to route the plain commands — that was tried and the
user reverted it (2026-07-06): the daily drivers must stay direct.

## Phase 5 — end-to-end verification

```bash
claude-moa --print "Reply with exactly: MOA-PT" # passthrough, must answer normally
moa on claude
claude-moa --print "Reply with exactly: MOA-ON" # fans out; check:
moa stats 1                                     # candidates all ok, no degraded
moa off claude
# same for codex: codex-moa exec --skip-git-repo-check --ephemeral '...'
```

Confirm `moa stats` shows the item with all candidates ok and the
synthesizer used. Report results to the user; never include secrets.

## If stuck or you find a bug

Ask the user for permission, then file a detailed issue at
<https://github.com/yukimaru77/claude-codex-MoA/issues> (diag output,
instance configs, moa errors lines — all secrets redacted).
