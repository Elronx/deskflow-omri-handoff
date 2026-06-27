#!/usr/bin/env bash
set -euo pipefail

ROOT="${DESKFLOW_SETUP_ROOT:-$HOME/Mac-Windows/deskflow-mac-windows-setup}"
LABEL="${DESKFLOW_SERVER_LABEL:-com.local.deskflow-server}"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
UID_VALUE="$(id -u)"
LOG="$ROOT/run/deskflow-reliability.log"
REASON="${1:-manual}"

mkdir -p "$ROOT/run"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"
}

log "Restarting Deskflow server: reason=$REASON"

if [[ ! -f "$PLIST" ]]; then
  log "ERROR: missing LaunchAgent plist: $PLIST"
  exit 1
fi

launchctl bootstrap "gui/${UID_VALUE}" "$PLIST" 2>/dev/null || true
launchctl kickstart -k "gui/${UID_VALUE}/${LABEL}"

sleep 3

if lsof -nP -iTCP:24800 -sTCP:LISTEN | grep -q 'deskflow'; then
  log "Deskflow is listening on TCP 24800."
else
  log "ERROR: Deskflow is not listening on TCP 24800 after restart."
  exit 1
fi

lsof -nP -iTCP:24800 -sTCP:ESTABLISHED 2>/dev/null | sed 's/^/[connection] /' | tee -a "$LOG" || true
