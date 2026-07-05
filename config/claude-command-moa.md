---
description: Toggle MoA (Mixture of Agents) for Claude sessions (all sessions run through the MoA proxy)
allowed-tools: Bash(moa:*), Bash(echo:*)
---

Run these two commands with the Bash tool:
1. `moa ${ARGUMENTS:-toggle} claude` (valid: on / off / toggle / status; default toggle)
2. `echo "${ANTHROPIC_BASE_URL:-direct}"`

Then report to the user in 1-2 short lines:

- If command 2 printed a URL containing `8400`: this session runs through the
  MoA proxy, so the new mode applies **from the very next step**. State the
  mode: "moa" = every step fans out to the candidate models and the
  synthesizer merges them; "passthrough" = fully transparent single-model
  behavior (requests go byte-faithfully to api.anthropic.com with your own
  login).
- Otherwise: this session was started before the proxy setting existed — the
  global mode was still switched; tell the user to restart `claude` so the
  session picks up the proxy.
