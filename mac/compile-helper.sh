#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/run"
swiftc "$ROOT/mac/deskflow-focus.swift" -o "$ROOT/run/deskflow-focus"
echo "Compiled $ROOT/run/deskflow-focus"
