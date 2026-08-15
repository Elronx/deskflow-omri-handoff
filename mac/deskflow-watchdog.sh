#!/usr/bin/env bash
set -euo pipefail

ROOT="${DESKFLOW_SETUP_ROOT:-$HOME/Mac-Windows/deskflow-mac-windows-setup}"
RUN="$ROOT/run"
LOG="$RUN/deskflow-reliability.log"
LOCK="$RUN/deskflow-watchdog.lock"
WAKE_STATE="$RUN/deskflow-last-wake.txt"
IP_STATE="$RUN/deskflow-last-ip.txt"
SERVER_START_STATE="$RUN/deskflow-server-start-epoch.txt"
LAN_IFACE="${DESKFLOW_LAN_IFACE:-auto}"
WINDOWS_IP="${DESKFLOW_WINDOWS_IP:-}"

mkdir -p "$RUN"
if ! mkdir "$LOCK" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"
}

restart() {
  "$ROOT/mac/deskflow-reliable-restart.sh" "$1" >> "$LOG" 2>&1 || true
}

if [[ "$LAN_IFACE" == "auto" && -n "$WINDOWS_IP" ]]; then
  LAN_IFACE="$(route -n get "$WINDOWS_IP" 2>/dev/null | awk '/interface:/{print $2; exit}')"
fi
current_ip="$(ipconfig getifaddr "$LAN_IFACE" 2>/dev/null || true)"

if [[ -n "$current_ip" ]]; then
  previous_ip="$(cat "$IP_STATE" 2>/dev/null || true)"
  if [[ -n "$previous_ip" && "$previous_ip" != "$current_ip" ]]; then
    log "Default LAN IP changed from $previous_ip to $current_ip."
    restart "ip-change-$previous_ip-to-$current_ip"
  fi
  printf '%s\n' "$current_ip" > "$IP_STATE"
fi

windows_route_iface=""
if [[ -n "$WINDOWS_IP" ]]; then
  windows_route_iface="$(route -n get "$WINDOWS_IP" 2>/dev/null | awk '/interface:/{print $2; exit}')"
fi
if [[ -n "$windows_route_iface" && "$windows_route_iface" != "$LAN_IFACE" ]]; then
  log "WARNING: route to Windows $WINDOWS_IP is via $windows_route_iface, expected $LAN_IFACE. VPN may be blocking local LAN."
fi

if ! lsof -nP -iTCP:24800 -sTCP:LISTEN 2>/dev/null | grep -q 'deskflow'; then
  log "No Deskflow listener on TCP 24800."
  restart "missing-listener"
  exit 0
fi

latest_wake="$(sysctl -n kern.waketime 2>/dev/null | sed -n 's/^{ sec = \([0-9][0-9]*\),.*/\1/p')"
if [[ -z "$latest_wake" ]]; then
  exit 0
fi

previous_wake="$(cat "$WAKE_STATE" 2>/dev/null || true)"
if [[ -z "$previous_wake" ]]; then
  printf '%s\n' "$latest_wake" > "$WAKE_STATE"
  exit 0
fi

if [[ "$latest_wake" != "$previous_wake" ]]; then
  printf '%s\n' "$latest_wake" > "$WAKE_STATE"
  now="$(date +%s)"
  started="$(cat "$SERVER_START_STATE" 2>/dev/null || true)"
  if [[ "$started" =~ ^[0-9]+$ ]] && (( now >= started && now - started <= 120 )); then
    log "Detected wake $latest_wake; a fresh server start is already in progress, avoiding a duplicate restart."
  else
    log "Detected wake event at $latest_wake; restarting Deskflow once to refresh macOS input capture."
    restart "wake-$latest_wake"
  fi
fi
