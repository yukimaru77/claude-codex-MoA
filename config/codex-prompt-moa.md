Toggle MoA (Mixture of Agents) for codex-moa sessions.

Run this shell command (argument may be on / off / toggle / status; default toggle):

    moa ${1:-toggle} codex

Report to the user in 1-2 short lines: the new mode ("moa" = every step fans
out to the candidate models and a synthesizer merges them; "passthrough" =
byte-transparent single-model behavior). If this session was started as
`codex-moa` it applies from the next step; a plain `codex` session talks
directly to the ChatGPT backend and cannot be rerouted — tell the user to run
`codex-moa` (same config, skills, MCP, and login as plain codex; only the
wire hop differs).
