# Deskflow Handoff For Mac Server And Windows Client

This is the cleaned-up result of the Mac and Windows Deskflow setup work.

## Final Architecture

Use Deskflow for input only:

- Mac runs Deskflow as server.
- Windows runs Deskflow as client.
- Deskflow TCP port: `24800`.
- Windows screen sits to the right of the Mac screen in Deskflow layout.
- Clipboard sharing starts disabled for the base input-only setup; re-enable later only if needed and stable.
- Screen streaming, Moonlight, Sunshine, and screen swap are optional future work and are not part of the base handoff.

## What Worked

Mac server settings:

- `switchDelay = 0`
- `relativeMouseMoves = false`
- `clipboardSharing = false`
- `clipboardSharingSize = 1024`
- If VPN is used, bind Deskflow to the current local LAN IP dynamically rather than to VPN tunnel interfaces.
- Set Deskflow `preventSleep=false` for lower battery/heat unless the Mac must be forced awake.
- Windows screen to the right of Mac screen.
- Do not lock cursor when switching; locked relative mode caused center warps on the working setup.

Windows screen modifier mapping in the Mac Deskflow server config:

```text
super = alt
meta = alt
alt = alt
ctrl = ctrl
```

This makes the Mac `Command` key behave like Windows `Alt` for keys Deskflow receives while the Windows client is focused. Deskflow's text config exposes generic `alt`, not a left/right Alt split.

Important exception: macOS reserves physical `Command+Tab` for the Mac app switcher, so Deskflow may never receive it. To make `Command+Tab` act like Windows `Alt+Tab`, add a BetterTouchTool bridge that is enabled only while Windows mode is active:

- `Command+Shift+2` switches to Windows and enables the BTT `Command+Tab` bridge.
- Physical `Command+Tab` then runs a helper that posts `Option+Tab` through Deskflow, which Windows receives as `Alt+Tab`.
- `Command+Shift+1` returns to Mac and disables the BTT bridge so normal Mac `Command+Tab` works again.

Working hotkey pattern:

```text
keystroke(shift+super+1) = switchToScreen(<MAC_SCREEN_NAME>)
keystroke(shift+super+2) = switchToScreen(<WINDOWS_SCREEN_NAME>)
keystroke(control+super+right) = switchInDirection(right)
keystroke(control+super+left) = switchInDirection(left)
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

Do not assume Deskflow mapping alone can override macOS `Command+Tab`. If `Command+Tab` matters, use the BTT enable/disable bridge described above.

Do not use locked relative mouse mode as the default. The working setup initially used `relativeMouseMoves=true` plus `lockCursorToScreen(on)`, but that caused pointer warps/center jumps, especially around Windows focus changes and UAC prompts. The stable default is `relativeMouseMoves=false` and no `lockCursorToScreen(...)` hotkey actions.

Do not mix in screen streaming at first. Moonlight/Sunshine was used only as a temporary maintenance view when Windows Codex handoff was unavailable. It is not needed for daily Deskflow input control.

Start with clipboard sharing disabled. It is convenient, but for the lowest-overhead reliable baseline it is another sync path that is not required for keyboard/mouse control.

Do not expose Deskflow over VPN tunnel interfaces if VPN is used. In the working setup, the best final state was a dynamic LAN bind: a wrapper waits for the Wi-Fi/LAN IP, writes it as `interface=<LAN_IP>` directly under `coreMode=2` in `~/Library/Deskflow/Deskflow.conf`, then starts `deskflow-core`.

The VPN must allow local LAN traffic. If the route to the Windows laptop goes through `utun*` or disappears, enable local-network/LAN access or split tunneling for the LAN subnet on both machines.

## Mac Reliability Watchdog

For daily use, run Deskflow server through a user LaunchAgent and add a small watchdog:

- Restart Deskflow if TCP `24800` is not listening.
- Detect macOS wake events and restart Deskflow once after wake.
- Keep the external `server.conf` as the source of layout/hotkeys.
- Set Deskflow GUI `startCoreWithGui=false` so the LaunchAgent is the single owner of the core process.

The repo includes templates:

- `mac/deskflow-reliable-restart.sh`
- `mac/deskflow-watchdog.sh`
- `mac/deskflow-server-wrapper.sh`
- `mac/com.local.deskflow-watchdog.plist.template`
- `mac/com.local.deskflow-server.plist.template`

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

## Trackpad Mapping Bundle

`mac/install-btt-mappings.sh` installs the complete tested mapping through
BetterTouchTool's supported AppleScript interface after taking a SQLite backup:

- two-finger swipe left: Windows/browser Back;
- two-finger swipe right: Windows/browser Forward;
- three-finger swipe left: previous Chrome/browser tab (`Control+Shift+Tab`);
- three-finger swipe right: next Chrome/browser tab (`Control+Tab`);
- three-finger tap: native middle mouse button;
- `Command+Shift+1`: return to Mac;
- `Command+Shift+2`: switch to Windows.

The two-finger mapping defaults to sensitivity `0.38` and serializes both
directions through one 700 ms cooldown. This prevents an ordinary horizontal
image pan from navigating too easily and prevents one gesture from firing Back
twice. The helper sends explicit modifier down/up transitions for tab changes,
so Windows receives the intended chord rather than a plain Tab focus change.

BetterTouchTool is a separate third-party application and may require a trial
or license. Its Accessibility permission must be granted by the Mac user; the
installer cannot and must not bypass macOS consent.

Ask before changing permissions, installing software, changing firewall rules, or adding autostart entries.

## Verification Checklist

Mac-side:

- `server.conf` uses the real `<MAC_SCREEN_NAME>` and `<WINDOWS_SCREEN_NAME>`.
- Deskflow server is listening on TCP `24800`.
- Deskflow log shows Windows client connected.
- Clipboard sharing is disabled for the first stable input-only pass.
- `Command+Shift+1` or fallback hotkey switches back to Mac.
- `Command+Shift+2` or fallback hotkey switches to Windows.
- If the BTT bridge is installed, `Command+Shift+2` enables Windows `Command+Tab -> Alt+Tab`, and `Command+Shift+1` disables it.
- Typing `Shift+1` produces `!` and does not switch machines.

Windows-side:

- Deskflow client shows the Mac server IP.
- Windows has an established TCP connection to `<MAC_LAN_IP>:24800`.
- Notepad receives typed text.
- If the BTT bridge is installed, `Command+Tab` from Mac behaves like Windows `Alt+Tab` after Windows mode is entered with `Command+Shift+2`.
- Two-finger scroll is tested in a browser and adjusted only through the Windows tuning script or Deskflow client settings.

UAC note:

- Windows UAC prompts may appear on secure desktop, where normal user-level Deskflow input cannot click `Yes`.
- Prefer a Deskflow service/daemon/elevated-client setup if the installed Deskflow build supports it.
- Do not disable UAC secure desktop unless the user explicitly accepts the security tradeoff.

## Coordination Script

The Mac Codex should ask Windows Codex for:

- Windows IP address.
- Windows Deskflow installed/version.
- Windows firewall state.
- Whether Windows can reach `<MAC_LAN_IP>`.
- Windows client screen name/hostname as shown in Deskflow.
- Whether `Get-NetTCPConnection -RemoteAddress <MAC_LAN_IP> -RemotePort 24800` shows `Established`.

The Windows Codex should wait for the Mac screen name and Mac IP before final client configuration.
