# Prompt For Omri's Windows Codex

Paste the text below into Codex on Omri's Windows laptop.

```text
Goal: Set up Deskflow with this Windows laptop as the CLIENT, controlled by a Mac SERVER over the local LAN/Wi-Fi.

Context:
I want the Mac keyboard and Mac trackpad/mouse to control this Windows laptop with the lowest practical latency. Deskflow input-only is the target. Do not set up Moonlight, Sunshine, Parsec, screen streaming, or screen swapping unless I explicitly ask later.

Priority order:
1. Lowest practical input latency.
2. Reliable smooth switching.
3. Mac Command should behave as Windows Ctrl while controlling Windows. The Mac server config handles most of this.
4. Trackpad pointer speed should feel close to the Mac.
5. Two-finger scroll should be slowed and smoothed as much as Deskflow/Windows allow.

Work area:
Use a new separate folder only:
%USERPROFILE%\Mac-Windows\deskflow-mac-windows-setup

Reference package:
Use the handoff repo files I provide. Read README.md, HANDOFF.md, and windows/apply-deskflow-client-tuning.ps1 before changing anything.

Important lessons from the working setup:
- The Mac is the Deskflow server; Windows is the Deskflow client.
- Windows does not need inbound Deskflow server access for the normal client setup, but it must reach the Mac server at <MAC_LAN_IP>:24800.
- Ask before installing software, changing firewall rules, adding autostart, or making admin-level changes.
- Deskflow client scroll scale should be set to 0.1. That is the lowest built-in value we found useful.
- Windows wheel settings should be WheelScrollLines=1 and WheelScrollChars=1.
- If the Deskflow GUI cannot restart the client, find deskflow-core.exe and run it as:
  deskflow-core.exe client -s "<PATH_TO_DESKFLOW_CONF>"
- Portable Deskflow installs can live under:
  %LOCALAPPDATA%\Programs\DeskflowPortable\PFiles64\Deskflow

First run these read-only facts in PowerShell and report the full output:

Get-ComputerInfo | Select-Object OsName, OsVersion, OsBuildNumber, WindowsProductName, CsManufacturer, CsModel
hostname
whoami
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object Name, InterfaceDescription, LinkSpeed, MacAddress
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '169.*' -and $_.IPAddress -ne '127.0.0.1'} | Select-Object InterfaceAlias, IPAddress, PrefixLength
Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select-Object NextHop, InterfaceAlias
netsh wlan show interfaces
Get-NetFirewallProfile | Select-Object Name, Enabled
winget --version
winget list | Select-String -Pattern 'Deskflow|Input Leap|Barrier|Synergy|Moonlight|Sunshine|Parsec'
Get-ChildItem "$env:ProgramFiles","${env:ProgramFiles(x86)}","$env:LOCALAPPDATA\Programs","$env:APPDATA" -Recurse -Filter "deskflow*.exe" -ErrorAction SilentlyContinue | Select-Object -First 50 FullName

Then ask Mac Codex for:
- Mac LAN IP.
- Mac Deskflow screen name.
- Whether the Mac Deskflow server is listening on TCP 24800.

After Mac Codex gives <MAC_LAN_IP>, run:

Test-Connection -Count 20 -TargetName <MAC_LAN_IP> | Measure-Object -Property Latency -Average -Maximum -Minimum
Test-NetConnection <MAC_LAN_IP> -Port 24800

Tasks after approval:
1. Install Deskflow if not present, using the official Deskflow release or winget if available. Ask before installing.
2. Configure Deskflow as client connecting to <MAC_LAN_IP>.
3. Report the exact Windows client screen name/hostname shown in Deskflow so Mac Codex can put that in server.conf.
4. When Mac server is ready, connect the Windows client.
5. Verify:
   Get-NetTCPConnection -RemoteAddress <MAC_LAN_IP> -RemotePort 24800 -ErrorAction SilentlyContinue
6. Test Notepad input from the Mac:
   - normal letters.
   - Shift+1 should type !, not switch machines.
   - Command+C/V/A/L from the Mac should behave like Ctrl+C/V/A/L on Windows.
7. Apply scroll tuning by running windows/apply-deskflow-client-tuning.ps1:
   powershell -ExecutionPolicy Bypass -File .\windows\apply-deskflow-client-tuning.ps1 -ScrollScale 0.1 -WheelScrollLines 1 -WheelScrollChars 1 -RestartDeskflow
8. If Omri approves autostart, rerun with -AddCurrentUserAutostart and the real -MacServerIp.
9. Test browser scrolling, especially YouTube or a long webpage. If it is still too fast, explain clearly that Deskflow is already at the built-in 0.1 floor and the next step would be a separate Windows scroll smoothing/filter helper.
10. Keep exact notes of settings, paths, connection state, and tests.

Do not touch Bluetooth/custom HID repos. Do not enable screen streaming. Start in read-only mode, report facts, and wait for Mac-side coordination before changing anything.
```
