<#
.SYNOPSIS
    Run a single pomodoro session: sleep for the duration, beep several times,
    then append a JSONL entry to the log.

.DESCRIPTION
    Designed to be launched as a background process. The caller (Claude) is
    notified when the script exits, which is the cue to ask the user what to do
    next (break vs. new session). Only sessions that run to completion are
    logged.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Label,

    [int]$Minutes = 25,

    [ValidateSet('work', 'short-break', 'long-break')]
    [string]$Type = 'work',

    [string]$LogPath = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'pomodoro-log.jsonl'),

    # Per-call override for the bell. Wins over the config file.
    [string]$BellPath,

    # Persistent config file. `bellPath` key sets the default bell.
    [string]$ConfigPath = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'pomodoro-config.json')
)

$start = Get-Date
Write-Host ("[{0}] Pomodoro started: [{1}] {2} ({3} min)" -f $start.ToString('HH:mm:ss'), $Type, $Label, $Minutes)

Start-Sleep -Seconds ($Minutes * 60)

$end = Get-Date

# Bell resolution order: -BellPath param > config file `bellPath` > Alarm01.wav.
# A real wav through SoundPlayer beats Console::Beep, which is unreliable on
# modern Windows (often routed to a phantom PC speaker that doesn't exist).
$bellWav = $BellPath
if (-not $bellWav -and (Test-Path $ConfigPath)) {
    try {
        $cfg = Get-Content -Path $ConfigPath -Raw -Encoding utf8 | ConvertFrom-Json
        if ($cfg.bellPath) { $bellWav = $cfg.bellPath }
    } catch {
        Write-Warning "Could not read $ConfigPath -- falling back to default bell."
    }
}
if (-not $bellWav) { $bellWav = Join-Path $env:SystemRoot 'Media\Alarm01.wav' }

if (Test-Path $bellWav) {
    $player = New-Object System.Media.SoundPlayer $bellWav
    for ($i = 0; $i -lt 3; $i++) {
        $player.PlaySync()
        Start-Sleep -Milliseconds 250
    }
} else {
    Write-Warning "Bell file not found: $bellWav -- falling back to SystemSounds.Asterisk."
    for ($i = 0; $i -lt 4; $i++) {
        [System.Media.SystemSounds]::Asterisk.Play()
        Start-Sleep -Milliseconds 600
    }
}

$logDir = Split-Path $LogPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$entry = [ordered]@{
    start            = $start.ToString('yyyy-MM-ddTHH:mm:sszzz')
    end              = $end.ToString('yyyy-MM-ddTHH:mm:sszzz')
    label            = $Label
    type             = $Type
    duration_minutes = $Minutes
}
$json = $entry | ConvertTo-Json -Compress
Add-Content -Path $LogPath -Value $json -Encoding utf8

Write-Host ("[{0}] Pomodoro complete: [{1}] {2}" -f $end.ToString('HH:mm:ss'), $Type, $Label)
