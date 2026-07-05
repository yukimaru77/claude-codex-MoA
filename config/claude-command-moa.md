---
description: Toggle MoA (Mixture of Agents) — takes effect in claude-moa sessions
allowed-tools: Bash(moa:*), Bash(echo:*)
---

Run these two commands with the Bash tool:
1. `moa ${ARGUMENTS:-toggle} claude` (valid: on / off / toggle / status; default toggle)
2. `echo "${ANTHROPIC_BASE_URL:-direct}"`

Then report to the user in 1-2 short lines:

- If command 2 printed a URL containing `8400`: this session runs through the
  MoA proxy, so the new mode applies **from the very next step**. State the
  mode: "moa" = every step fans out to the candidate models and the
  synthesizer merges them; "passthrough" = byte-transparent single-model
  behavior (your own login and models).
- Otherwise: this session talks directly to its provider and cannot be
  rerouted mid-flight. The global mode was still switched — tell the user to
  run `claude-moa` in a terminal for a session where it takes effect
  (claude-moa shares the same skills, MCP, sessions, and login as plain
  claude; only the wire hop differs).
