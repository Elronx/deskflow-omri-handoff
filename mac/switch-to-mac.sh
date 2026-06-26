#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HELPER="$ROOT/run/deskflow-focus"

if [[ ! -x "$HELPER" ]]; then
  "$ROOT/mac/compile-helper.sh"
fi

"$HELPER" mac
