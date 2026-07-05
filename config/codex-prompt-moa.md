Toggle MoA (Mixture of Agents) for Codex sessions (all Codex sessions run
through the MoA proxy via the `moa` model provider in ~/.codex/config.toml).

Run this shell command (argument may be on / off / toggle / status; default toggle):

    moa ${1:-toggle} codex

Report to the user in 1-2 short lines: the new mode, and that it applies from
the next step of this session. "moa" = every step fans out to the candidate
models and a synthesizer merges them; "passthrough" = fully transparent
single-model behavior (requests go byte-faithfully to the ChatGPT backend
with your own login). Sessions started before the moa provider was configured
need a restart to pick it up.
