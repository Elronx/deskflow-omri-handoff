# Deskflow Handoff For Mac Server And Windows Client

This is the cleaned-up result of the Mac and Windows Deskflow setup work.

## Final Architecture

Use Deskflow for input only:

- Mac runs Deskflow as server.
- Windows runs Deskflow as client.
- Deskflow TCP port: `24800`.
- Windows screen sits to the right of the Mac screen in Deskflow layout.
- Clipboard sharing can stay enabled with a small limit if stable.
- Screen streaming, Moonlight, Sunshine, and screen swap are optional future work and are not part of the base handoff.

## What Worked

Mac server settings:

- `switchDelay = 0`
- `relativeMouseMoves = true`
- `clipboardSharing = true`
- `clipboardSharingSize = 1024`
- Do not pin the Deskflow server to one specific LAN interface/IP in the GUI settings unless the IP is reserved and stable.
- Windows screen to the right of Mac screen.
- Cursor lock when switching to Windows.
- Cursor unlock when switching back to Mac.

Windows screen modifier mapping in the Mac Deskflow server config:

```text
super = ctrl
meta = ctrl
alt = alt
ctrl = ctrl
```

This makes the Mac `Command` key behave like Windows `Ctrl` while the Windows client is focused. Without it, `Command` can act like the Windows key and open Start.

Working hotkey pattern:

```text
keystroke(shift+super+1) = switchToScreen(<WINDOWS_SCREEN_NAME>), lockCursorToScreen(on)
keystroke(shift+super+2) = lockCursorToScreen(off), switchToScreen(<MAC_SCREEN_NAME>)
keystroke(control+super+right) = switchInDirection(right), lockCursorToScreen(on)
keystroke(control+super+left) = lockCursorToScreen(off), switchInDirection(left)
```

Also include `shift+alt+1/2` and `control+alt+right/left` fallbacks, because Deskflow/macOS modifier naming can vary.

## What To Avoid

Do not use these hotkeys:

```text
keystroke(shift+meta+1)
keystroke(shift+meta+2)
```

On the working Mac, `shift+meta+1` behaved like plain `Shift+1`. That broke typing `!` because it switched to Windows.

Do not use an edge-push cursor fallback in helper scripts. The early helper moved the mouse to the right edge to force switching; it caused the pointer to jump. The final helper only posts Deskflow hotkeys.

Do not mix in screen streaming at first. Moonlight/Sunshine was used only as a temporary maintenance view when Windows Codex handoff was unavailable. It is not needed for daily Deskflow input control.

Do not leave the Mac server bound to a single transient Wi-Fi IP. In the working setup, overnight sleep/wake produced `cannot bind address` failures and a connected-but-flickering input state. Removing the fixed `interface=<LAN_IP>` line and letting Deskflow listen on `*:24800` was more reliable.

## Mac Reliability Watchdog

For daily use, run Deskflow server through a user LaunchAgent and add a small watchdog:

- Restart Deskflow if TCP `24800` is not listening.
- Detect macOS wake events and restart Deskflow once after wake.
- Keep the external `server.conf` as the source of layout/hotkeys.
- Set Deskflow GUI `startCoreWithGui=false` so the LaunchAgent is the single owner of the core process.

The repo includes templates:

- `mac/deskflow-reliable-restart.sh`
- `mac/deskflow-watchdog.sh`
- `mac/com.local.deskflow-watchdog.plist.template`

When adapting the plist, replace `<MAC_SETUP_ROOT>` with Omri's absolute setup folder, usually `/Users/<omri-user>/Mac-Windows/deskflow-mac-windows-setup`.

## Windows Client Tuning

Deskflow forwards Mac trackpad scroll to Windows as wheel-style scroll events, not native macOS inertial trackpad events. The best built-in tuning we found:

```text
yScrollScale=0.1
xScrollScale=0.1
invertYScroll=false
invertXScroll=false
WheelScrollLines=1
WheelScrollChars=1
```

`0.1` is the lowest Deskflow client scroll scale exposed by current Deskflow settings. If scrolling is still too fast or not smooth enough after that, the next real fix is a Windows-side scroll smoothing/filter helper. Do not keep lowering Deskflow scale below `0.1` unless a newer Deskflow version explicitly supports it.

## Installation And Permissions

The Mac may need:

- Deskflow installed.
- Accessibility permission for Deskflow.
- Input Monitoring permission for Deskflow if macOS asks.
- Accessibility permission for Codex/Terminal if Codex compiles and uses the Swift hotkey helper.

The Windows laptop may need:

- Deskflow installed.
- Outbound access to the Mac server at `<MAC_LAN_IP>:24800`.
- Autostart entry if Omri wants Deskflow client to reconnect after login.

Ask before changing permissions, installing software, changing firewall rules, or adding autostart entries.

## Verification Checklist

Mac-side:

- `server.conf` uses the real `<MAC_SCREEN_NAME>` and `<WINDOWS_SCREEN_NAME>`.
- Deskflow server is listening on TCP `24800`.
- Deskflow log shows Windows client connected.
- `Command+Shift+1` or fallback hotkey switches to Windows.
- `Command+Shift+2` or fallback hotkey switches back to Mac.
- Typing `Shift+1` produces `!` and does not switch machines.

Windows-side:

- Deskflow client shows the Mac server IP.
- Windows has an established TCP connection to `<MAC_LAN_IP>:24800`.
- Notepad receives typed text.
- `Command+C`, `Command+V`, `Command+A`, and `Command+L` from Mac behave like Windows `Ctrl+C`, `Ctrl+V`, `Ctrl+A`, and `Ctrl+L`.
- Two-finger scroll is tested in a browser and adjusted only through the Windows tuning script or Deskflow client settings.

## Coordination Script

The Mac Codex should ask Windows Codex for:

- Windows IP address.
- Windows Deskflow installed/version.
- Windows firewall state.
- Whether Windows can reach `<MAC_LAN_IP>`.
- Windows client screen name/hostname as shown in Deskflow.
- Whether `Get-NetTCPConnection -RemoteAddress <MAC_LAN_IP> -RemotePort 24800` shows `Established`.

The Windows Codex should wait for the Mac screen name and Mac IP before final client configuration.
