# Prompt For Omri's Mac Codex

Paste the text below into Codex on Omri's Mac.

```text
Goal: Set up Deskflow with this Mac as the SERVER for low-latency LAN/Wi-Fi control of a Windows laptop.

Context:
I want to control my Windows laptop from my Mac using the Mac keyboard and Mac trackpad/mouse. The Mac is the Deskflow SERVER. The Windows laptop is the Deskflow CLIENT. Use Deskflow input-only first. Do not set up Moonlight, Sunshine, screen streaming, or screen swapping unless I explicitly ask later.

Priority order:
1. Lowest practical input latency.
2. Reliable smooth switching.
3. Hotkey switching, ideally Command+Shift+1 back to Mac and Command+Shift+2 to Windows, or the closest Deskflow-supported equivalent.
4. Mac Command should act as Windows Alt while controlling Windows. Command+Tab needs a BetterTouchTool bridge because macOS reserves it.
5. Clipboard sharing only after the input-only baseline is stable; start with clipboard disabled.

Work area:
Use a new separate folder only:
~/Mac-Windows/deskflow-mac-windows-setup

Reference package:
Use the handoff repo files I provide. Read README.md, HANDOFF.md, templates/server.conf.template, mac/deskflow-focus.swift, and the two prompts before changing anything.

Important lessons from the working setup:
- Use Deskflow input only at first.
- Windows screen should be to the right of the Mac screen.
- Set switchDelay = 0.
- Set relativeMouseMoves = true.
- Start with clipboardSharing = false for lower overhead; re-enable later only if I ask and the input bridge is stable.
- When switching to Windows, lock cursor to the Windows screen.
- When switching back to Mac, unlock cursor.
- On the Windows screen in the Mac server config, map:
  super = alt
  meta = alt
  alt = alt
  ctrl = ctrl
- Do not use keystroke(shift+meta+1) or keystroke(shift+meta+2). In the working Mac setup, that broke typing Shift+1 / ! by triggering a screen switch.
- Use shift+super+1/2 if Deskflow recognizes Command that way, plus shift+alt+1/2 fallback.
- The Swift helper must only post Control+Command+Right/Left Deskflow hotkeys. Do not push the cursor to the screen edge as a fallback.
- macOS captures physical Command+Tab before Deskflow can forward it. If I want Command+Tab to act as Windows Alt+Tab, create a BetterTouchTool bridge that is enabled only in Windows mode: Command+Shift+2 enables a BTT Command+Tab trigger that posts Option+Tab through Deskflow; Command+Shift+1 disables that BTT trigger so normal Mac Command+Tab returns.
- If VPN is used, do not expose Deskflow on VPN interfaces. Use the LAN wrapper pattern: bind to the current Wi-Fi/LAN IP dynamically and verify route to Windows stays on local LAN.
- Set Deskflow preventSleep=false unless I explicitly want the Mac kept awake; this reduces battery/heat and the watchdog can recover after wake.
- Add the Mac reliability watchdog after the base setup works: restart Deskflow if port 24800 is not listening and restart once after macOS wake.

Tasks:
1. Create/use ~/Mac-Windows/deskflow-mac-windows-setup only.
2. Gather Mac facts:
   - macOS version.
   - hostname / Deskflow screen name.
   - active network service.
   - LAN IP addresses.
   - Wi-Fi band/channel if available.
   - VPN/proxy status if visible.
   - Deskflow installed/version/path if present.
3. Ask before installing Deskflow, changing macOS permissions, adding BetterTouchTool, changing firewall settings, or adding autostart.
4. Coordinate with Windows Codex and ask it for:
   - Windows IP address.
   - Windows hostname/client screen name shown in Deskflow.
   - Deskflow installed/version/path.
   - firewall status.
   - whether it can ping/reach this Mac IP.
   - whether TCP connection to this Mac on port 24800 becomes Established after setup.
5. Generate server.conf from templates/server.conf.template with the real Mac and Windows screen names.
6. Configure Deskflow as server using that config.
7. Compile mac/deskflow-focus.swift and create switch scripts equivalent to switch-to-windows.sh and switch-to-mac.sh.
8. Install a user LaunchAgent for Deskflow server if one is not already present, and make sure it uses the Deskflow settings file that points to the external server.conf.
9. Install/adapt the watchdog templates:
   - mac/deskflow-server-wrapper.sh
   - mac/deskflow-reliable-restart.sh
   - mac/deskflow-watchdog.sh
   - mac/com.local.deskflow-watchdog.plist.template
10. Bind hotkeys:
   - Prefer direct Deskflow hotkeys shift+super+1 and shift+super+2.
   - If BetterTouchTool is already installed or I approve using it, bind Command+Shift+1 to switch-to-mac.sh and Command+Shift+2 to switch-to-windows.sh.
   - Keep Deskflow fallback hotkeys shift+alt+1/2 and control+super+arrow.
11. Verify:
   - Windows connects to Mac server on TCP 24800.
   - If VPN is used, Mac server listens on the LAN IP only, not VPN interfaces.
   - Route to Windows stays on Wi-Fi/LAN, not utun/VPN.
   - Command+Shift+1 or fallback returns to Mac.
   - Command+Shift+2 or fallback switches to Windows.
   - Shift+1 types ! and does not switch machines.
   - If the BTT bridge was installed, Command+Tab acts as Alt+Tab on Windows after entering Windows mode with Command+Shift+2.
   - Mouse does not jump to the right when switching.
   - Clipboard sharing is disabled for the first stable input-only pass.
12. Ask Windows Codex to run the Windows tuning script after input is working:
    windows/apply-deskflow-client-tuning.ps1 with ScrollScale 0.1, WheelScrollLines 1, WheelScrollChars 1.
13. Keep exact notes of settings, commands, permissions, test results, and any caveats.

Do not touch Bluetooth/custom HID repos. Do not enable screen streaming. Start by gathering facts and tell me the next safest action.
```
