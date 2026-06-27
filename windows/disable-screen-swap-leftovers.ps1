$ErrorActionPreference = 'Continue'

$Root = Join-Path $env:USERPROFILE 'Mac-Windows\deskflow-screen-swap'
$LogFile = Join-Path $Root 'disable-screen-swap-leftovers.log'
New-Item -ItemType Directory -Force -Path $Root | Out-Null

function Write-CleanupLog([string]$Message) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Add-Content -Path $LogFile -Value $line
    Write-Host $line
}

Write-CleanupLog 'Disabling Deskflow/Moonlight screen-swap leftovers. Deskflow input client is not touched.'

$pollerPattern = 'deskflow-screen-swap-poller.ps1'
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match [regex]::Escape($pollerPattern) } |
    ForEach-Object {
        Write-CleanupLog "Stopping poller process PID $($_.ProcessId)"
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }

Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq 'Moonlight.exe' -and $_.CommandLine -match 'stream' } |
    ForEach-Object {
        Write-CleanupLog "Stopping Moonlight stream PID $($_.ProcessId)"
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }

$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
Remove-ItemProperty -Path $runKey -Name 'DeskflowScreenSwapPoller' -ErrorAction SilentlyContinue
Write-CleanupLog 'Removed HKCU Run entry DeskflowScreenSwapPoller if present.'

$startup = [Environment]::GetFolderPath('Startup')
$shortcut = Join-Path $startup 'Deskflow Screen Swap Poller.lnk'
if (Test-Path $shortcut) {
    Remove-Item -Path $shortcut -Force
    Write-CleanupLog "Removed startup shortcut: $shortcut"
}

try {
    $task = Get-ScheduledTask -TaskName 'DeskflowScreenSwapPoller' -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName 'DeskflowScreenSwapPoller' -Confirm:$false
        Write-CleanupLog 'Removed scheduled task DeskflowScreenSwapPoller.'
    }
} catch {
    Write-CleanupLog "Scheduled task cleanup skipped or failed: $($_.Exception.Message)"
}

Write-CleanupLog 'Screen-swap cleanup finished.'
