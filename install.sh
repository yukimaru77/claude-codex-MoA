#!/usr/bin/env bash
# install.sh — wire the MoA proxies into this machine.
#
#   ./install.sh          install/repair (idempotent)
#   ./install.sh --check  verify only, change nothing
#
# What it wires (see README):
#   ~/.config/moa/instances/*.json   instance configs (copied if absent)
#   ~/.local/share/moa/              state, telemetry, launchd logs
#   ~/Library/LaunchAgents/com.<user>.moa.plist  daemon (RunAtLoad+KeepAlive)
#   ~/.local/bin/moa                 control/diagnosis CLI
#   ~/.claude/commands/moa.md        /moa for Claude Code
#   ~/.codex/prompts/moa.md          /moa for Codex
#   ~/.agents/skills/moa             natural-language discovery for Codex
#
#   ~/.local/bin/claude-moa, codex-moa   MoA-capable entry commands (they
#                                         share your normal skills/MCP/login)
# It never touches plain `claude` / `codex` — those stay fully direct.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
USER_NAME="$(id -un)"
LABEL="com.$USER_NAME.moa"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

say() { printf '%s\n' "$*"; }
run() { if [ "$CHECK" = 1 ]; then printf '[check]'; printf ' %q' "$@"; printf '\n'; else "$@"; fi; }

for f in bin/moa-api bin/moa bin/claude-moa bin/codex-moa config/instances/claude.json config/instances/codex.json \
         config/claude-command-moa.md config/codex-prompt-moa.md config/skill-moa/SKILL.md \
         service/com.USER.moa.plist; do
  [ -e "$REPO/$f" ] || { echo "missing repo file: $f" >&2; exit 66; }
done

run mkdir -p "$HOME/.config/moa/instances" "$HOME/.local/share/moa/obs" \
             "$HOME/.claude/commands" "$HOME/.codex/prompts" "$HOME/.agents/skills"
for inst in claude codex; do
  [ -f "$HOME/.config/moa/instances/$inst.json" ] || \
    run cp "$REPO/config/instances/$inst.json" "$HOME/.config/moa/instances/$inst.json"
done
run ln -sfn "$REPO/bin/moa" "$HOME/.local/bin/moa"
run ln -sfn "$REPO/bin/claude-moa" "$HOME/.local/bin/claude-moa"
run ln -sfn "$REPO/bin/codex-moa" "$HOME/.local/bin/codex-moa"
run cp "$REPO/config/claude-command-moa.md" "$HOME/.claude/commands/moa.md"
run cp "$REPO/config/codex-prompt-moa.md" "$HOME/.codex/prompts/moa.md"
run mkdir -p "$HOME/.agents/skills/moa"
run cp "$REPO/config/skill-moa/SKILL.md" "$HOME/.agents/skills/moa/SKILL.md"
[ -d "$HOME/.codex/skills" ] && run ln -sfn "$HOME/.agents/skills/moa" "$HOME/.codex/skills/moa"

if [ "$CHECK" = 1 ]; then
  say "[check] render + bootstrap $PLIST"
else
  sed -e "s|com.USER.moa|$LABEL|g" -e "s|HOME_DIR|$HOME|g" \
      "$REPO/service/com.USER.moa.plist" > "$PLIST"
  launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || \
    launchctl bootstrap "gui/$(id -u)" "$PLIST"
fi
say "MoA install complete. Verify: moa diag all"
