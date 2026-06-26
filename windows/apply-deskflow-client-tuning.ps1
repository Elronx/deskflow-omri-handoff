param(
    [ValidateRange(0.1, 10.0)]
    [double]$ScrollScale = 0.1,
    [int]$WheelScrollLines = 1,
    [int]$WheelScrollChars = 1,
    [ValidateSet('false', 'true')]
    [string]$InvertYScroll = 'false',
    [ValidateSet('false', 'true')]
    [string]$InvertXScroll = 'false',
    [string]$MacServerIp = '',
    [switch]$RestartDeskflow,
    [switch]$AddCurrentUserAutostart
)

$ErrorActionPreference = 'Stop'

$Root = Join-Path $env:USERPROFILE 'Mac-Windows\deskflow-mac-windows-setup'
$LogFile = Join-Path $Root 'deskflow-client-tuning.log'
New-Item -ItemType Directory -Force -Path $Root | Out-Null

function Write-TuneLog([string]$Message) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Add-Content -Path $LogFile -Value $line
    Write-Host $line
}

function Set-IniValue {
    param(
        [string[]]$Lines,
        [string]$Section,
        [string]$Key,
        [string]$Value
    )

    $sectionHeader = "[$Section]"
    $sectionStart = -1
    $sectionEnd = $Lines.Count

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].Trim() -ieq $sectionHeader) {
            $sectionStart = $i
            break
        }
    }

    if ($sectionStart -lt 0) {
        return @($Lines + '' + $sectionHeader + "$Key=$Value")
    }

    for ($i = $sectionStart + 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].Trim() -match '^\[[^\]]+\]$') {
            $sectionEnd = $i
            break
        }
    }

    for ($i = $sectionStart + 1; $i -lt $sectionEnd; $i++) {
        if ($Lines[$i] -match "^\s*$([regex]::Escape($Key))\s*=") {
            $copy = @($Lines)
            $copy[$i] = "$Key=$Value"
            return $copy
        }
    }

    $before = if ($sectionEnd -gt 0) { $Lines[0..($sectionEnd - 1)] } else { @() }
    $after = if ($sectionEnd -lt $Lines.Count) { $Lines[$sectionEnd..($Lines.Count - 1)] } else { @() }
    return @($before + "$Key=$Value" + $after)
}

function Add-ExistingPath([System.Collections.Generic.List[string]]$List, [string]$Path) {
    if ($Path -and (Test-Path $Path) -and -not $List.Contains($Path)) {
        [void]$List.Add($Path)
    }
}

function Find-DeskflowConfigFiles {
    $files = [System.Collections.Generic.List[string]]::new()

    @(
        (Join-Path $env:ProgramFiles 'Deskflow\settings\Deskflow.conf'),
        (Join-Path $env:ProgramFiles 'Deskflow\Deskflow.conf'),
        (Join-Path ${env:ProgramFiles(x86)} 'Deskflow\settings\Deskflow.conf'),
        (Join-Path ${env:ProgramFiles(x86)} 'Deskflow\Deskflow.conf'),
        (Join-Path $env:ProgramData 'Deskflow\Deskflow.conf'),
        (Join-Path $env:LOCALAPPDATA 'Deskflow\Deskflow.conf'),
        (Join-Path $env:APPDATA 'Deskflow\Deskflow.conf')
    ) | ForEach-Object { Add-ExistingPath $files $_ }

    $searchRoots = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\DeskflowPortable'),
        (Join-Path $env:LOCALAPPDATA 'Programs'),
        $env:APPDATA
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($root in $searchRoots) {
        Get-ChildItem -Path $root -Recurse -Filter 'Deskflow.conf' -ErrorAction SilentlyContinue |
            Select-Object -First 25 |
            ForEach-Object { Add-ExistingPath $files $_.FullName }
    }

    return @($files | Select-Object -Unique)
}

function Find-DeskflowExecutable([string]$ExeName) {
    $direct = @(
        (Join-Path $env:ProgramFiles "Deskflow\$ExeName"),
        (Join-Path ${env:ProgramFiles(x86)} "Deskflow\$ExeName"),
        (Join-Path $env:LOCALAPPDATA "Programs\DeskflowPortable\PFiles64\Deskflow\$ExeName"),
        (Join-Path $env:LOCALAPPDATA "Programs\Deskflow\$ExeName")
    ) | Where-Object { $_ -and (Test-Path $_) }

    if ($direct.Count -gt 0) {
        return ($direct | Select-Object -First 1)
    }

    $searchRoots = @(
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        (Join-Path $env:LOCALAPPDATA 'Programs')
    ) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($root in $searchRoots) {
        $match = Get-ChildItem -Path $root -Recurse -Filter $ExeName -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($match) {
            return $match.FullName
        }
    }

    return $null
}

function Set-DeskflowRegistryClientValue {
    param(
        [string]$Name,
        [string]$Value
    )

    $paths = @(
        'HKCU:\Software\Deskflow\Deskflow\client',
        'HKCU:\Software\Deskflow\Deskflow'
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            New-ItemProperty -Path $path -Name $Name -Value $Value -PropertyType String -Force | Out-Null
            Write-TuneLog "Registry set: $path $Name=$Value"
        }
    }
}

Write-TuneLog "Deskflow client tuning started. ScrollScale=$ScrollScale InvertY=$InvertYScroll InvertX=$InvertXScroll"
Write-TuneLog "Wheel settings before: $(Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' | Select-Object -Property WheelScrollLines,WheelScrollChars | ConvertTo-Json -Compress)"

$configFiles = Find-DeskflowConfigFiles
if (@($configFiles).Count -eq 0) {
    Write-TuneLog 'No Deskflow file config found. Will try registry settings only.'
}

foreach ($config in $configFiles) {
    Write-TuneLog "Updating Deskflow config file: $config"
    Copy-Item -Path $config -Destination "$config.before-touchpad-tuning.$(Get-Date -Format 'yyyyMMdd-HHmmss')" -Force
    $lines = @(Get-Content -Path $config -ErrorAction Stop)
    $lines = Set-IniValue -Lines $lines -Section 'client' -Key 'yScrollScale' -Value ([string]$ScrollScale)
    $lines = Set-IniValue -Lines $lines -Section 'client' -Key 'xScrollScale' -Value ([string]$ScrollScale)
    $lines = Set-IniValue -Lines $lines -Section 'client' -Key 'invertYScroll' -Value $InvertYScroll
    $lines = Set-IniValue -Lines $lines -Section 'client' -Key 'invertXScroll' -Value $InvertXScroll
    Set-Content -Path $config -Value $lines -Encoding UTF8
}

Set-DeskflowRegistryClientValue -Name 'yScrollScale' -Value ([string]$ScrollScale)
Set-DeskflowRegistryClientValue -Name 'xScrollScale' -Value ([string]$ScrollScale)
Set-DeskflowRegistryClientValue -Name 'invertYScroll' -Value $InvertYScroll
Set-DeskflowRegistryClientValue -Name 'invertXScroll' -Value $InvertXScroll

$desktopKey = 'HKCU:\Control Panel\Desktop'
Set-ItemProperty -Path $desktopKey -Name 'WheelScrollLines' -Value ([string]$WheelScrollLines)
Set-ItemProperty -Path $desktopKey -Name 'WheelScrollChars' -Value ([string]$WheelScrollChars)
Write-TuneLog "Wheel settings after registry write: $(Get-ItemProperty -Path $desktopKey | Select-Object -Property WheelScrollLines,WheelScrollChars | ConvertTo-Json -Compress)"

try {
    Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class WinUserScrollSettings {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
}
'@

    $SPI_SETWHEELSCROLLLINES = 0x0069
    $SPI_SETWHEELSCROLLCHARS = 0x006D
    $SPIF_UPDATEINIFILE = 0x0001
    $SPIF_SENDCHANGE = 0x0002
    $flags = $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE

    [void][WinUserScrollSettings]::SystemParametersInfo($SPI_SETWHEELSCROLLLINES, [uint32]$WheelScrollLines, [IntPtr]::Zero, $flags)
    [void][WinUserScrollSettings]::SystemParametersInfo($SPI_SETWHEELSCROLLCHARS, [uint32]$WheelScrollChars, [IntPtr]::Zero, $flags)
    Write-TuneLog 'Applied Windows wheel settings via SystemParametersInfo.'
} catch {
    Write-TuneLog "Could not apply Windows wheel settings through SystemParametersInfo: $($_.Exception.Message)"
}

$coreExe = Find-DeskflowExecutable 'deskflow-core.exe'
$guiExe = Find-DeskflowExecutable 'deskflow.exe'
$primaryConfig = @($configFiles | Where-Object { $_ -match '\\Deskflow\.conf$' } | Select-Object -First 1)[0]

if ($AddCurrentUserAutostart) {
    if (-not $coreExe) {
        Write-TuneLog 'Cannot add autostart: deskflow-core.exe not found.'
    } elseif (-not $primaryConfig) {
        Write-TuneLog 'Cannot add autostart: Deskflow.conf not found.'
    } else {
        $runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        $value = "`"$coreExe`" client -s `"$primaryConfig`""
        New-ItemProperty -Path $runKey -Name 'DeskflowClient' -Value $value -PropertyType String -Force | Out-Null
        Write-TuneLog "Added HKCU Run autostart: $value"
    }
}

if ($RestartDeskflow) {
    Write-TuneLog 'Restarting Deskflow client processes.'
    Get-Process -Name 'deskflow-core','deskflow' -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2

    if ($guiExe) {
        Start-Process -FilePath $guiExe
        Write-TuneLog "Started Deskflow GUI: $guiExe"
    } elseif ($coreExe -and $primaryConfig) {
        Start-Process -FilePath $coreExe -ArgumentList @('client', '-s', $primaryConfig)
        Write-TuneLog "Started Deskflow core client: $coreExe client -s $primaryConfig"
    } else {
        Write-TuneLog 'Deskflow executable/config not found; open Deskflow manually and reconnect the client.'
    }
}

if ($MacServerIp) {
    try {
        $connections = Get-NetTCPConnection -RemoteAddress $MacServerIp -RemotePort 24800 -ErrorAction SilentlyContinue
        if ($connections) {
            Write-TuneLog "TCP connection state to ${MacServerIp}:24800: $($connections.State -join ', ')"
        } else {
            Write-TuneLog "No TCP connection currently found to ${MacServerIp}:24800"
        }
    } catch {
        Write-TuneLog "Could not check TCP connection: $($_.Exception.Message)"
    }
}

Write-TuneLog "Deskflow client tuning finished. Log: $LogFile"
