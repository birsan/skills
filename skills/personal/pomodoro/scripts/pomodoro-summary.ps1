<#
.SYNOPSIS
    Summarize completed pomodoros from the JSONL log, grouped by label.

.PARAMETER Range
    today     — sessions started since midnight (default)
    yesterday — sessions started during the previous calendar day
    week      — sessions started since the most recent Monday 00:00
    all       — every entry in the log

.PARAMETER LogPath
    Path to the JSONL log. Defaults to Documents\pomodoro-log.jsonl.
#>
[CmdletBinding()]
param(
    [ValidateSet('today', 'yesterday', 'week', 'all')]
    [string]$Range = 'today',

    [string]$LogPath = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'pomodoro-log.jsonl')
)

if (-not (Test-Path $LogPath)) {
    Write-Host "No pomodoro log found at $LogPath"
    return
}

$now = Get-Date
switch ($Range) {
    'today' {
        $from = $now.Date
        $to   = $now.Date.AddDays(1)
    }
    'yesterday' {
        $from = $now.Date.AddDays(-1)
        $to   = $now.Date
    }
    'week' {
        # ISO week start (Monday). DayOfWeek: Sunday=0..Saturday=6.
        $offset = ([int]$now.DayOfWeek + 6) % 7
        $from = $now.Date.AddDays(-$offset)
        $to   = $now.Date.AddDays(1)
    }
    'all' {
        $from = [datetime]::MinValue
        $to   = [datetime]::MaxValue
    }
}

$entries = Get-Content -Path $LogPath -Encoding utf8 |
    Where-Object { $_.Trim() } |
    ForEach-Object { $_ | ConvertFrom-Json }

$work = $entries | Where-Object {
    $_.type -eq 'work' -and [datetime]$_.start -ge $from -and [datetime]$_.start -lt $to
}

if (-not $work) {
    Write-Host "No work pomodoros in range '$Range'."
    return
}

$count = @($work).Count
$total = ($work | Measure-Object -Property duration_minutes -Sum).Sum

Write-Host ""
Write-Host ("Pomodoros ({0}): {1} sessions, {2} min total" -f $Range, $count, $total)
Write-Host ("-" * 50)

$work |
    Group-Object -Property label |
    Sort-Object -Property @{Expression = { ($_.Group | Measure-Object -Property duration_minutes -Sum).Sum }; Descending = $true } |
    ForEach-Object {
        $labelTotal = ($_.Group | Measure-Object -Property duration_minutes -Sum).Sum
        '{0,3} sessions  {1,4} min  {2}' -f $_.Count, $labelTotal, $_.Name
    }
