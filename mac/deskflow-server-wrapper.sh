#!/usr/bin/env bash
set -euo pipefail

ROOT="${DESKFLOW_SETUP_ROOT:-$HOME/Mac-Windows/deskflow-mac-windows-setup}"
SETTINGS="${DESKFLOW_SETTINGS:-$HOME/Library/Deskflow/Deskflow.conf}"
CORE="${DESKFLOW_CORE:-/Applications/Deskflow.app/Contents/MacOS/deskflow-core}"
LAN_IFACE="${DESKFLOW_LAN_IFACE:-en0}"
WINDOWS_IP="${DESKFLOW_WINDOWS_IP:-}"
LOG="$ROOT/run/deskflow-reliability.log"
SERVER_START_STATE="$ROOT/run/deskflow-server-start-epoch.txt"

mkdir -p "$ROOT/run"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"
}

[[ "$WINDOWS_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  log "ERROR: DESKFLOW_WINDOWS_IP must be set to the Windows LAN IPv4 address."
  exit 75
}

if [[ "$LAN_IFACE" == "auto" ]]; then
  LAN_IFACE="$(route -n get "$WINDOWS_IP" 2>/dev/null | awk '/interface:/{print $2; exit}')"
fi

is_private_ipv4() {
  local ip="$1" second
  [[ "$ip" =~ ^10\. ]] && return 0
  [[ "$ip" =~ ^192\.168\. ]] && return 0
  if [[ "$ip" =~ ^172\.([0-9]+)\. ]]; then
    second="${BASH_REMATCH[1]}"
    (( second >= 16 && second <= 31 )) && return 0
  fi
  return 1
}

lan_ip=""
for _ in {1..30}; do
  lan_ip="$(ipconfig getifaddr "$LAN_IFACE" 2>/dev/null || true)"
  if [[ "$LAN_IFACE" == en* ]] && is_private_ipv4 "$lan_ip"; then
    break
  fi
  sleep 1
done

if [[ "$LAN_IFACE" != en* ]] || ! is_private_ipv4 "$lan_ip"; then
  log "ERROR: no private LAN address found on route-selected $LAN_IFACE; refusing to bind Deskflow to VPN or an unknown interface."
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

start_tmp="$(mktemp "${SERVER_START_STATE}.tmp.XXXXXX")"
printf '%s\n' "$(date +%s)" > "$start_tmp"
mv -f -- "$start_tmp" "$SERVER_START_STATE"

log "Starting Deskflow server bound to route-selected $LAN_IFACE/$lan_ip for Windows $WINDOWS_IP, avoiding VPN tunnel interfaces."
exec "$CORE" server -s "$SETTINGS"
