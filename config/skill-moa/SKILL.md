---
name: moa
description: Toggle MoA (Mixture of Agents) fusion for Claude/Codex sessions. Use when the user says "moa", "MoA", "mixture of agents", "fusion mode", or asks to turn multi-model fusion on/off or check its status.
---

# moa — Mixture of Agents toggle

Switch the MoA proxy between "moa" (every step fans out to all candidate
models in parallel and a synthesizer merges them) and "passthrough"
(byte-transparent single model).

Run with the shell tool (argument: on / off / toggle / status; default toggle):

    moa <arg> claude    # in Claude Code
    moa <arg> codex     # in Codex

All Claude and Codex sessions run through the MoA proxies by default
(claude: ANTHROPIC_BASE_URL in ~/.claude/settings.json; codex: the `moa`
model provider in ~/.codex/config.toml), so the new mode applies from the
next step. Only sessions started BEFORE that wiring existed need a restart —
for Claude verify with `echo "${ANTHROPIC_BASE_URL:-direct}"` (8400 = proxied).

Report in 1-2 lines: the new mode and that it applies from the next step.
Diagnosis if anything misbehaves: `moa diag all`.
