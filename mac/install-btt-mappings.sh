#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HELPER="$ROOT/run/deskflow-focus"
BTT_DIR="$HOME/Library/Application Support/BetterTouchTool"
BACKUP_DIR="$ROOT/run/btt-backups"
SENSITIVITY="${BTT_TWO_FINGER_SWIPE_SENSITIVITY:-0.38}"

[[ -x "$HELPER" ]] || "$ROOT/mac/compile-helper.sh"
[[ -d "$BTT_DIR" ]] || {
  printf 'BetterTouchTool is not installed or has never been opened: %s\n' "$BTT_DIR" >&2
  exit 2
}
[[ "$SENSITIVITY" =~ ^0([.][0-9]+)?$ ]] || {
  printf 'BTT_TWO_FINGER_SWIPE_SENSITIVITY must be greater than 0 and at most 1.\n' >&2
  exit 2
}
awk -v value="$SENSITIVITY" 'BEGIN { exit !(value > 0 && value <= 1) }' || exit 2

DB="$(
  find "$BTT_DIR" -maxdepth 1 -type f -name 'btt_data_store.version_*' \
    ! -name '*-wal' ! -name '*-shm' ! -name '*.before-*' -print |
    sort -t_ -k4,4n -k5,5n -k7,7n |
    tail -1
)"
[[ -n "$DB" && -f "$DB" ]] || {
  printf 'BetterTouchTool data store was not found. Open BTT once, then retry.\n' >&2
  exit 2
}

mkdir -p "$BACKUP_DIR"
BACKUP="$BACKUP_DIR/btt-before-deskflow-mappings-$(date +%Y%m%d-%H%M%S).sqlite"
sqlite3 "$DB" ".backup '$BACKUP'"

python3 - "$HELPER" <<'PY'
import json
import subprocess
import sys
import time

helper = sys.argv[1]

GET = 'on run argv\n tell application "BetterTouchTool" to get_trigger (item 1 of argv)\nend run'
UPDATE = 'on run argv\n tell application "BetterTouchTool" to update_trigger (item 1 of argv) json (item 2 of argv)\nend run'
ADD = 'on run argv\n tell application "BetterTouchTool" to add_new_trigger (item 1 of argv)\nend run'


def osa(script, *args):
    return subprocess.run(
        ["osascript", "-e", script, *args],
        check=True,
        text=True,
        capture_output=True,
    ).stdout


def get(uuid):
    raw = osa(GET, uuid)
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def update(uuid, fields):
    osa(UPDATE, uuid, json.dumps(fields, separators=(",", ":")))


def shell_action(uuid, parent, command):
    return {
        "BTTActionCategory": 0,
        "BTTTriggerParentUUID": parent,
        "BTTIsPureAction": True,
        "BTTTriggerClass": "BTTTriggerTypeTouchpadAll",
        "BTTUUID": uuid,
        "BTTPredefinedActionType": 206,
        "BTTPredefinedActionName": "Execute Shell Script  or  Task",
        "BTTShellTaskActionScript": command,
        "BTTShellTaskActionConfig": "/bin/bash:::-c:::-:::",
        "BTTEnabled": 1,
        "BTTEnabled2": 1,
        "BTTOrder": 1,
    }


def add_trackpad(parent, action, trigger_type, description, command, order):
    payload = {
        "BTTActionCategory": 0,
        "BTTTriggerType": trigger_type,
        "BTTTriggerClass": "BTTTriggerTypeTouchpadAll",
        "BTTTriggerTypeDescription": description,
        "BTTGestureNotes": f"Deskflow remote gesture: {description}",
        "BTTUUID": parent,
        "BTTPredefinedActionType": 366,
        "BTTPredefinedActionName": "Empty Placeholder",
        "BTTEnabled": 1,
        "BTTEnabled2": 1,
        "BTTOrder": order,
        "BTTActionsToExecute": [shell_action(action, parent, command)],
    }
    osa(ADD, json.dumps(payload, separators=(",", ":")))
    time.sleep(0.25)


def ensure_trackpad(parent, action, trigger_type, description, command, order):
    item = get(parent)
    if not item:
        add_trackpad(parent, action, trigger_type, description, command, order)
        item = get(parent)
    if item.get("BTTTriggerTypeDescriptionReadOnly") != description:
        raise RuntimeError(f"BTT did not register {description}")
    actions = item.get("BTTActionsToExecute", [])
    if len(actions) != 1 or not actions[0].get("BTTUUID"):
        raise RuntimeError(f"{description} does not have exactly one action")
    update(parent, {"BTTEnabled": 1, "BTTEnabled2": 1})
    update(
        actions[0]["BTTUUID"],
        {
            "BTTEnabled": 1,
            "BTTEnabled2": 1,
            "BTTPredefinedActionType": 206,
            "BTTPredefinedActionName": "Execute Shell Script  or  Task",
            "BTTShellTaskActionScript": command,
            "BTTShellTaskActionConfig": "/bin/bash:::-c:::-:::",
        },
    )


def keyboard_payload(parent, action, keycode, destination):
    command = f"{helper} {destination}"
    return {
        "BTTActionCategory": 0,
        "BTTTriggerType": 0,
        "BTTTriggerClass": "BTTTriggerTypeKeyboardShortcut",
        "BTTUUID": parent,
        "BTTPredefinedActionType": 366,
        "BTTPredefinedActionName": "Empty Placeholder",
        "BTTAdditionalConfiguration": f"Deskflow: switch to {destination}",
        "BTTKeyboardShortcutKeyboardType": 0,
        "BTTTriggerOnDown": 1,
        "BTTEnabled": 1,
        "BTTEnabled2": 1,
        "BTTShortcutKeyCode": keycode,
        "BTTShortcutModifierKeys": 1179648,
        "BTTAutoAdaptToKeyboardLayout": 0,
        "BTTAdditionalActions": [
            {
                "BTTActionCategory": 0,
                "BTTTriggerParentUUID": parent,
                "BTTIsPureAction": True,
                "BTTTriggerClass": "BTTTriggerTypeKeyboardShortcut",
                "BTTUUID": action,
                "BTTPredefinedActionType": 206,
                "BTTPredefinedActionName": "Execute Shell Script  or  Task",
                "BTTShellTaskActionScript": command,
                "BTTShellTaskActionConfig": "/bin/bash:::-c:::-:::",
                "BTTEnabled": 1,
                "BTTEnabled2": 1,
            }
        ],
    }


keyboard = [
    ("49C35098-BEF8-4503-89DE-541D6811D789", "51DB140D-2384-4AD6-A9E9-96E0B1033EFD", 18, "mac"),
    ("9BA942FD-ECE6-4AB6-BA4E-702B4A3D6E15", "F8D6B689-FD7B-4867-A4EA-210D7263FEA8", 19, "windows"),
]
for parent, action, keycode, destination in keyboard:
    item = get(parent)
    if not item:
        osa(ADD, json.dumps(keyboard_payload(parent, action, keycode, destination), separators=(",", ":")))
        time.sleep(0.25)
        item = get(parent)
    actions = item.get("BTTActionsToExecute", [])
    if len(actions) != 1 or not actions[0].get("BTTUUID"):
        raise RuntimeError(f"Deskflow keyboard trigger {parent} is malformed")
    update(
        parent,
        {
            "BTTEnabled": 1,
            "BTTEnabled2": 1,
            "BTTShortcutKeyCode": keycode,
            "BTTShortcutModifierKeys": 1179648,
            "BTTTriggerOnDown": 1,
        },
    )
    update(
        actions[0]["BTTUUID"],
        {
            "BTTEnabled": 1,
            "BTTEnabled2": 1,
            "BTTShellTaskActionScript": f"{helper} {destination}",
            "BTTShellTaskActionConfig": "/bin/bash:::-c:::-:::",
        },
    )

gestures = [
    ("C30D6BDC-C6E4-44B9-A05D-E52468F3EEEB", "DFBEFC95-DD90-45C8-AF5D-8D893C2A42AD", 100, "3 Finger Swipe Left", "tab-previous", 1),
    ("DB597A2B-77BF-487D-B1D2-9E39063500CB", "3CB422CE-CBCD-4F02-A470-3D81FEF14C4D", 101, "3 Finger Swipe Right", "tab-next", 2),
    ("8E0C3A60-BF78-432D-851A-CAE4B520AF4D", "DC395FF3-DA6E-48EC-943F-634E9C529A01", 159, "2 Finger Swipe Left", "back", 3),
    ("0C10E636-0687-465C-8E58-B762F7A3C6CF", "D077BFE2-565B-4891-BBE8-BF50FB201F0F", 160, "2 Finger Swipe Right", "forward", 4),
    ("47852D58-4AA8-4E2B-A23E-9E7C831AB818", "6EE60438-09AF-4188-9524-565EF2B6F653", 104, "3 Finger Tap", "middle", 5),
]
for parent, action, trigger_type, description, destination, order in gestures:
    ensure_trackpad(
        parent,
        action,
        trigger_type,
        description,
        f"{helper} {destination}",
        order,
    )

for parent, _, _, description, _, _ in gestures:
    item = get(parent)
    actions = item.get("BTTActionsToExecute", [])
    if item.get("BTTEnabled", 1) != 1 or len(actions) != 1:
        raise RuntimeError(f"{description} did not verify")

print("PASS: Deskflow hotkeys and trackpad mappings installed and verified")
PY

defaults write com.hegenberg.BetterTouchTool \
  tpTwoFingerSwipeSensitivity -float "$SENSITIVITY"

printf 'BetterTouchTool backup: %s\n' "$BACKUP"
printf 'Two-finger swipe sensitivity: %s\n' "$SENSITIVITY"
