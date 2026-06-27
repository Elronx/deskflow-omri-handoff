#!/usr/bin/env bash
set -euo pipefail

ROOT="${DESKFLOW_SETUP_ROOT:-$HOME/Mac-Windows/deskflow-mac-windows-setup}"
SETTINGS="${DESKFLOW_SETTINGS:-$HOME/Library/Deskflow/Deskflow.conf}"
CORE="${DESKFLOW_CORE:-/Applications/Deskflow.app/Contents/MacOS/deskflow-core}"
LAN_IFACE="${DESKFLOW_LAN_IFACE:-en0}"
LAN_PREFIX_REGEX="${DESKFLOW_LAN_PREFIX_REGEX:-^192\\.168\\.1\\.}"
LOG="$ROOT/run/deskflow-reliability.log"

mkdir -p "$ROOT/run"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"
}

lan_ip=""
for _ in {1..30}; do
  lan_ip="$(ipconfig getifaddr "$LAN_IFACE" 2>/dev/null || true)"
  if [[ "$lan_ip" =~ $LAN_PREFIX_REGEX ]]; then
    break
  fi
  sleep 1
done

if [[ ! "$lan_ip" =~ $LAN_PREFIX_REGEX ]]; then
  log "ERROR: no expected LAN IP found on $LAN_IFACE; refusing to bind Deskflow to VPN or unknown interface."
  exit 75
fi

tmp="${SETTINGS}.tmp.$$"
awk -v ip="$lan_ip" '
  BEGIN { in_core = 0; wrote = 0 }
  /^\[core\]$/ { in_core = 1; print; next }
  in_core && /^interface=/ { next }
  in_core && /^coreMode=/ {
    print
    print "interface=" ip
    wrote = 1
    next
  }
  /^\[/ {
    if (in_core && !wrote) {
      print "interface=" ip
      wrote = 1
    }
    in_core = 0
    print
    next
  }
  { print }
  END {
    if (in_core && !wrote) {
      print "interface=" ip
    }
  }
' "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"

log "Starting Deskflow server bound to $LAN_IFACE/$lan_ip, avoiding VPN tunnel interfaces."
exec "$CORE" server -s "$SETTINGS"
