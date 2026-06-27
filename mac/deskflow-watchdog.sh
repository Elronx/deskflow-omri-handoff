#!/usr/bin/env bash
set -euo pipefail

ROOT="${DESKFLOW_SETUP_ROOT:-$HOME/Mac-Windows/deskflow-mac-windows-setup}"
RUN="$ROOT/run"
LOG="$RUN/deskflow-reliability.log"
LOCK="$RUN/deskflow-watchdog.lock"
WAKE_STATE="$RUN/deskflow-last-wake.txt"
IP_STATE="$RUN/deskflow-last-ip.txt"

mkdir -p "$RUN"
if ! mkdir "$LOCK" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"
}

restart() {
  "$ROOT/deskflow-reliable-restart.sh" "$1" >> "$LOG" 2>&1 || true
}

default_iface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
current_ip=""
if [[ -n "$default_iface" ]]; then
  current_ip="$(ipconfig getifaddr "$default_iface" 2>/dev/null || true)"
fi

if [[ -n "$current_ip" ]]; then
  previous_ip="$(cat "$IP_STATE" 2>/dev/null || true)"
  if [[ -n "$previous_ip" && "$previous_ip" != "$current_ip" ]]; then
    log "Default LAN IP changed from $previous_ip to $current_ip."
    restart "ip-change-$previous_ip-to-$current_ip"
  fi
  printf '%s\n' "$current_ip" > "$IP_STATE"
fi

if ! lsof -nP -iTCP:24800 -sTCP:LISTEN 2>/dev/null | grep -q 'deskflow'; then
  log "No Deskflow listener on TCP 24800."
  restart "missing-listener"
  exit 0
fi

latest_wake="$(pmset -g log 2>/dev/null | awk '/[[:space:]](Wake|DarkWake)[[:space:]]/ {last=$1" "$2} END {print last}')"
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
  sleep 8
  log "Detected wake event at $latest_wake; restarting Deskflow to refresh macOS input capture."
  restart "wake-$latest_wake"
fi
