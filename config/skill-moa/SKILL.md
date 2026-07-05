---
name: moa
description: Toggle MoA (Mixture of Agents) fusion for claude-moa / codex-moa sessions. Use when the user says "moa", "MoA", "mixture of agents", "fusion mode", or asks to turn multi-model fusion on/off or check its status.
---

# moa — Mixture of Agents toggle

Switch the MoA proxy between "moa" (every step fans out to all candidate
models in parallel and a synthesizer merges them) and "passthrough"
(byte-transparent single model).

Run with the shell tool (argument: on / off / toggle / status; default toggle):

    moa <arg> claude    # for claude-moa sessions
    moa <arg> codex     # for codex-moa sessions

The mode only takes effect in sessions started via `claude-moa` / `codex-moa`
(they share the user's normal skills, MCP, sessions, and login — only the
wire hop differs). Plain `claude` / `codex` sessions are direct and cannot be
rerouted mid-flight; tell the user to start the -moa command instead.
For Claude you can check with `echo "${ANTHROPIC_BASE_URL:-direct}"`
(8400 = proxied session).

Report in 1-2 lines: the new mode and where it applies.
Diagnosis if anything misbehaves: `moa diag all`.
