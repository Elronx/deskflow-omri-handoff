# Deskflow Mac-to-Windows Handoff

Reusable setup notes and prompts for using a Mac keyboard and Mac trackpad/mouse to control a Windows laptop over LAN/Wi-Fi.

This package is intentionally input-only. It does not set up Moonlight, Sunshine, screen streaming, or screen swapping. Those were useful for temporary maintenance, but they caused confusing recursive display states. Start with Deskflow only.

## Goal

- Mac is the Deskflow server.
- Windows laptop is the Deskflow client.
- Windows screen is logically to the right of the Mac screen.
- Mac `Command` behaves like Windows `Alt` while controlling Windows.
- Switch back to Mac with `Command+Shift+1` where supported, or Deskflow's closest supported equivalent.
- Switch to Windows with `Command+Shift+2` where supported.
- Keep pointer movement stable with absolute Deskflow pointer mode; avoid locked relative mode unless there is a specific reason to re-test it.
- Tune Windows client scrolling as far as Deskflow allows.
- Two-finger swipe left/right sends browser Back/Forward with a deliberate
  threshold and a one-action cooldown.
- Three-finger swipe left/right sends previous/next tab on Windows.
- Three-finger tap sends a native middle mouse click on Windows.
- Start with clipboard sharing disabled; re-enable later only after the input bridge is stable.

## Quick Start For Omri

1. Open Codex on the Mac and paste [PROMPT_FOR_MAC_CODEX.md](PROMPT_FOR_MAC_CODEX.md).
2. Open Codex on the Windows laptop and paste [PROMPT_FOR_WINDOWS_CODEX.md](PROMPT_FOR_WINDOWS_CODEX.md).
3. Let the Mac Codex and Windows Codex exchange the facts they ask for: Mac IP, Windows IP, Deskflow screen names, firewall status, and connection test output.
4. Do not enable the optional screen-streaming pieces until Deskflow input is stable.

## Files

- [PROMPT_FOR_MAC_CODEX.md](PROMPT_FOR_MAC_CODEX.md): prompt to paste into Omri's Mac Codex.
- [PROMPT_FOR_WINDOWS_CODEX.md](PROMPT_FOR_WINDOWS_CODEX.md): prompt to paste into Omri's Windows Codex.
- [HANDOFF.md](HANDOFF.md): what worked, what failed, and why.
- [templates/server.conf.template](templates/server.conf.template): Deskflow server config template for the Mac.
- [mac/deskflow-focus.swift](mac/deskflow-focus.swift): helper that posts Deskflow hotkeys without moving the cursor.
- [mac/compile-helper.sh](mac/compile-helper.sh): compiles the Swift helper.
- [mac/install-btt-mappings.sh](mac/install-btt-mappings.sh): backs up the
  active BetterTouchTool store and installs the switch, tab, navigation, and
  middle-click mappings.
- [mac/switch-to-windows.sh](mac/switch-to-windows.sh): calls the helper to switch control to Windows.
- [mac/switch-to-mac.sh](mac/switch-to-mac.sh): calls the helper to return control to Mac.
- [mac/deskflow-server-wrapper.sh](mac/deskflow-server-wrapper.sh): starts Deskflow bound to the local LAN interface, not VPN tunnels.
- [mac/deskflow-reliable-restart.sh](mac/deskflow-reliable-restart.sh): controlled restart helper for the Mac server LaunchAgent.
- [mac/deskflow-watchdog.sh](mac/deskflow-watchdog.sh): wake/listener watchdog for the Mac server.
- [mac/com.local.deskflow-server.plist.template](mac/com.local.deskflow-server.plist.template): supervised Mac server LaunchAgent template.
- [mac/com.local.deskflow-watchdog.plist.template](mac/com.local.deskflow-watchdog.plist.template): LaunchAgent template for the watchdog.
- [windows/apply-deskflow-client-tuning.ps1](windows/apply-deskflow-client-tuning.ps1): Windows-side Deskflow scroll tuning and optional client restart/autostart.

## Safety Notes

- Do not commit local credentials, Sunshine credentials, logs, or machine-specific configs.
- Never disable Windows UAC secure desktop to make Deskflow easier to use.
- The bundle contains no passwords, certificates, tokens, host addresses, or
  machine-specific trust. Every downloaded release must match the SHA-256 in
  the prompt before any script runs.
- Do not touch Bluetooth/custom HID projects for this setup.
- Ask before installs, firewall changes, Accessibility/Input Monitoring permissions, or autostart changes.
- Keep all Omri-specific work in `~/Mac-Windows/deskflow-mac-windows-setup` on the Mac and `%USERPROFILE%\Mac-Windows\deskflow-mac-windows-setup` on Windows.
- If VPN is used, bind Deskflow to the local LAN IP dynamically with `mac/deskflow-server-wrapper.sh`, and make sure the VPN allows local LAN access.
