# Prompt For Omri's Windows Codex

Paste everything inside the block into Codex on Omri's Windows laptop.

```text
Goal: install the complete Deskflow Windows-client bundle and coordinate with
the Mac Codex until input, reconnection, and every forwarded mapping pass.

Authorization and interaction policy:
- You may download this exact bundle, install the official current Deskflow
  release, configure the current user's Deskflow client, apply the included
  tuning, and create current-user autostart.
- Do not stop for routine read-only checks, backups, downloads, file creation,
  or current-user settings. Pause only when Windows itself requires an
  elevation confirmation or credentials. Never disable UAC or secure desktop.
- Never install a keyboard/mouse suppression hook or leave any process that
  captures or exclusively controls the user's physical input.

Secure bundle retrieval (do this first; do not use an attachment or a Mac-only
path):

URL:
https://github.com/Elronx/deskflow-omri-handoff/releases/download/v2.0.0/deskflow-omri-bundle-v2.0.0.zip

Required SHA-256:
96808ff51e82d253b718b0c843ef193b3461b20327a2f9e5078976a1922dcec3

Run the PowerShell equivalent of:

  $Stage = Join-Path $env:TEMP ("deskflow-omri-" + [guid]::NewGuid())
  New-Item -ItemType Directory -Path $Stage | Out-Null
  $Archive = Join-Path $Stage 'deskflow-omri-bundle-v2.0.0.zip'
  Invoke-WebRequest -Uri 'https://github.com/Elronx/deskflow-omri-handoff/releases/download/v2.0.0/deskflow-omri-bundle-v2.0.0.zip' -OutFile $Archive
  $Actual = (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($Actual -ne '96808ff51e82d253b718b0c843ef193b3461b20327a2f9e5078976a1922dcec3') {
      throw "Deskflow handoff SHA-256 mismatch: $Actual"
  }
  Expand-Archive -LiteralPath $Archive -DestinationPath (Join-Path $Stage 'unpacked')

If the checksum differs, stop without running anything. The extracted source is
under `$Stage\unpacked\deskflow-omri-bundle-v2.0.0`. Read `SECURITY.md`,
`README.md`, `HANDOFF.md`, and `windows\apply-deskflow-client-tuning.ps1`
before executing scripts. Confirm the PowerShell contains no downloaded second
stage, credential material, or machine-specific identity.

Install the verified source at this exact per-user work area:

  %USERPROFILE%\Mac-Windows\deskflow-mac-windows-setup

If that target already exists, do not overwrite it. Back it up with a timestamp
or continue only if it is clearly this same clean package. Preserve every
pre-existing user file.

Required behavior:
- Windows is the Deskflow client; Mac is the server; TCP port 24800.
- Default physical layout matching Elron's final setup: Windows is LEFT of the
  Mac; moving right from Windows returns to Mac.
- Mac Command is translated to Windows Alt by the Mac server.
- Three-finger left/right arrives as Control+Shift+Tab / Control+Tab.
- Three-finger tap arrives as native middle mouse button.
- Two-finger left/right arrives as browser Back/Forward.
- Scroll tuning: Deskflow X/Y scale 0.1; Windows wheel lines/chars 1.
- No Moonlight, Sunshine, screen streaming, screen swapping, custom HID driver,
  or Bluetooth changes.
- Keep Windows UAC and secure desktop enabled. Stock Deskflow cannot promise
  control of every protected UAC/credential surface; do not weaken security.

Execution:
1. Gather Windows version/build, hostname, current user/admin state, active LAN
   adapter/IP/MAC, default route, VPN state, firewall profiles, and installed
   Deskflow version/path. Make no changes during this fact pass.
2. Give Mac Codex the exact Windows LAN IP and Deskflow client screen name. Ask
   it for the Mac LAN IP and confirmation that TCP 24800 is listening.
3. Install only the official current Deskflow release if absent. Prefer the
   official winget package when available; verify publisher/source before
   installation. Do not install a random portable build.
4. Configure the client to the exact Mac LAN IP. Do not open a broad inbound
   firewall rule; the client needs outbound LAN access to the Mac server.
5. Copy the verified bundle into the work area, preserving its directory
   structure.
6. After the Mac server is ready, connect and require an Established TCP session
   to `<MAC_LAN_IP>:24800`.
7. Run one PowerShell command from the installed bundle root:
   `& .\windows\apply-deskflow-client-tuning.ps1 -ScrollScale 0.1 -WheelScrollLines 1 -WheelScrollChars 1 -RestartDeskflow -AddCurrentUserAutostart -MacServerIp <MAC_LAN_IP>`
8. Inspect the resulting HKCU autostart command and require exact quoted paths
   to the discovered official `deskflow-core.exe` and actual config. It must
   start exactly one interactive client after sign-in.
9. Test Notepad input, Shift+1=`!`, ordinary pointer motion, scroll, browser Back
   once, Forward once, previous/next tab once, and a three-finger middle click.
10. Test client-process restart without reboot and verify automatic reconnect.
11. Report clearly that protected UAC/credential desktops are not proven by
    stock Deskflow. Do not disable secure desktop or claim an impossible pass.
12. Record exact versions, paths, hashes, settings, TCP state, and test results
    in a local completion report.

Do not claim completion until the Mac server is reachable, the TCP session is
Established, and all ordinary-desktop tests pass. Start now with secure bundle
retrieval and read-only fact gathering.
```
