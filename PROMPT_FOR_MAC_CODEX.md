# Prompt For Omri's Mac Codex

Paste everything inside the block into Codex on Omri's Mac.

```text
Goal: install the complete Deskflow Mac-server bundle and coordinate with the
Windows Codex until keyboard, pointer, hotkeys, and trackpad mappings pass.

Authorization and interaction policy:
- You may download this exact bundle, install the official current Deskflow
  release, install/open BetterTouchTool if it is missing, compile the included
  local Swift helper, create current-user LaunchAgents, and configure the
  current user's Deskflow/BTT settings.
- Do not stop for routine read-only checks, backups, file creation, compilation,
  or current-user configuration. Pause only when macOS itself requires the user
  to enter a password, grant Accessibility/Input Monitoring, or accept a
  BetterTouchTool license/trial. Open the exact required settings page when that
  happens and explain the single action Omri must take.
- Never capture or exclusively control physical input. If any UI automation
  stalls, release it before waiting or troubleshooting.

Secure bundle retrieval (do this first; do not use an attachment or a path from
another computer):

URL:
https://github.com/Elronx/deskflow-omri-handoff/releases/download/v2.0.0/deskflow-omri-bundle-v2.0.0.zip

Required SHA-256:
96808ff51e82d253b718b0c843ef193b3461b20327a2f9e5078976a1922dcec3

Run the equivalent of:

  STAGE="$(mktemp -d)"
  ARCHIVE="$STAGE/deskflow-omri-bundle-v2.0.0.zip"
  curl --fail --location --proto '=https' --tlsv1.2 \
    'https://github.com/Elronx/deskflow-omri-handoff/releases/download/v2.0.0/deskflow-omri-bundle-v2.0.0.zip' \
    --output "$ARCHIVE"
  test "$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')" = \
    '96808ff51e82d253b718b0c843ef193b3461b20327a2f9e5078976a1922dcec3'
  ditto -x -k "$ARCHIVE" "$STAGE/unpacked"

If the checksum differs, stop without running anything. The extracted source is
under `$STAGE/unpacked/deskflow-omri-bundle-v2.0.0`. Read `SECURITY.md`,
`README.md`, and `HANDOFF.md` before executing scripts. Inspect the scripts and
confirm that they contain no downloaded second stage, credential material, or
machine-specific identity.

Install the verified source at this exact per-user work area:

  ~/Mac-Windows/deskflow-mac-windows-setup

If that target already exists, do not overwrite it. Back it up with a timestamp
or continue only if it is clearly this same clean package. Preserve every
pre-existing user file.

Architecture and required behavior:
- Mac is the Deskflow server; Windows is the client; TCP port 24800.
- Default physical layout matching Elron's final setup: Windows is LEFT of the
  Mac; moving left enters Windows and moving right returns to the Mac. Keep
  Command+Shift+1/2 hotkeys regardless of layout.
- Command+Shift+1 returns to Mac; Command+Shift+2 selects Windows.
- Mac Command acts as Windows Alt while Windows is controlled.
- Two-finger left/right swipe sends browser Back/Forward. Use the included 0.38
  deliberate-swipe sensitivity and shared 700 ms cooldown so one swipe cannot
  navigate twice.
- Three-finger left/right swipe sends previous/next browser tab using explicit
  Control+Shift+Tab / Control+Tab transitions.
- Three-finger tap sends one native middle mouse click.
- Absolute pointer mode; no locked-relative mode and no edge-push/visible cursor
  animation in the switch helper.
- Clipboard starts disabled. No screen streaming, Moonlight, or Sunshine.
- Bind only to the route-selected private LAN interface, never a VPN tunnel.
- Keep Windows UAC secure desktop enabled. Stock Deskflow may not control every
  protected Windows prompt; do not weaken Windows security to hide that limit.

Execution:
1. Gather macOS version, Mac Deskflow screen name, active LAN interface/IP,
   route/VPN status, and installed Deskflow/BTT versions.
2. Ask Windows Codex for its LAN IP and exact Deskflow client screen name.
3. Install official Deskflow if absent. Do not install an unknown continuous or
   third-party binary.
4. Generate `server.conf` from `templates/server.conf.template` with the real
   screen names and the required left-side physical links. Preserve the private
   helper bindings: Control+Command+Right selects Windows and
   Control+Command+Left selects Mac; these are screen selectors, not physical
   edge directions.
5. Configure Deskflow server with `switchDelay=0`,
   `relativeMouseMoves=false`, and `clipboardSharing=false`.
6. Compile `mac/deskflow-focus.swift` using `mac/compile-helper.sh`. Run its
   `status` mode; it must not inject input.
7. Install the server and watchdog LaunchAgents from both plist templates,
   replacing `<MAC_SETUP_ROOT>` and `<WINDOWS_LAN_IP>` with exact values.
   Validate the rendered plists before loading them. Ensure the GUI is not a
   second owner of `deskflow-core`.
8. After BetterTouchTool is installed/open and Accessibility is granted, run
   `mac/install-btt-mappings.sh`. It must create a timestamped BTT database
   backup and finish with PASS. Never edit an unrelated BTT trigger.
9. Start the server and coordinate the Windows client connection.
10. Test twenty edge crossings and ten hotkey round trips. Verify Shift+1 types
    `!`, the pointer does not visibly travel or jump, and there is exactly one
    server core and one established client connection.
11. Test each gesture on Windows: Back once, Forward once, previous tab once,
    next tab once, and one middle click. Ordinary horizontal image panning must
    not navigate accidentally.
12. Verify a simulated server restart and an actual later sleep/wake reconnect.
    The watchdog must not perform a duplicate post-wake restart.
13. Record exact versions, rendered paths, checksums, permissions, connection
    state, and test results in a local completion report.

Do not claim completion until Windows is established and every test that does
not require a later physical sleep/wake has passed. Start now with secure bundle
retrieval and fact gathering.
```
