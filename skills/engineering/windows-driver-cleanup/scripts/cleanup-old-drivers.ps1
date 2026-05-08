<#
.SYNOPSIS
    Removes older duplicate third-party drivers from the Windows DriverStore.

.DESCRIPTION
    Lists all third-party (oem*.inf) driver packages, groups them by their
    original .inf filename, and for each group keeps the newest version while
    deleting the older copies via pnputil /delete-driver.

    By default the script does NOT pass /force to pnputil. pnputil will
    therefore refuse to remove any driver package that is currently bound
    to a present device. Pass -Force to override this and delete in-use
    packages too — only do that when the user has explicitly asked for it.

    THIS IS A DESTRUCTIVE, NOT-EASILY-REVERSIBLE OPERATION.
    The script declares ConfirmImpact='High', so PowerShell prompts before
    every deletion unless the caller passes -Confirm:$false. Always run
    with -WhatIf first and review the list before doing the real run.

    Must be run from an elevated PowerShell session.

.PARAMETER Force
    Pass /force to pnputil so packages bound to present devices are also
    removed. Off by default. Only enable when the user has explicitly
    requested forced deletion.

.PARAMETER WhatIf
    Shows which driver packages would be removed without actually deleting them.

.PARAMETER Confirm
    Default behavior: prompt before each deletion. Pass -Confirm:$false only
    after the user has reviewed the dry-run output and explicitly approved
    deleting everything without further prompts.

.EXAMPLE
    PS> .\cleanup-old-drivers.ps1 -WhatIf
    Lists every old duplicate that would be removed. Always run this first.

.EXAMPLE
    PS> .\cleanup-old-drivers.ps1
    Safe cleanup: skips drivers bound to a present device, prompts before
    each removal.

.EXAMPLE
    PS> .\cleanup-old-drivers.ps1 -Force
    Forced cleanup: also removes driver packages currently in use. Only
    use after explicit user approval.

.EXAMPLE
    PS> .\cleanup-old-drivers.ps1 -Confirm:$false
    Performs the safe cleanup with no per-item prompts. Only use after
    reviewing the dry-run output.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$Force
)

# Require elevation
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

Write-Host "Scanning DriverStore for duplicate third-party drivers..." -ForegroundColor Cyan

# Get all third-party drivers
$drivers = Get-WindowsDriver -Online -All | Where-Object { $_.Driver -like "oem*.inf" }

# Group by the original file name to find duplicates (older versions)
$grouped = $drivers | Group-Object OriginalFileName | Where-Object { $_.Count -gt 1 }

if (-not $grouped) {
    Write-Host "No duplicate third-party drivers found. Nothing to clean up."
    return
}

# Build the candidate list and show it before doing anything destructive
$candidates = foreach ($group in $grouped) {
    $group.Group | Sort-Object Date -Descending | Select-Object -Skip 1
}

Write-Host ""
Write-Host "The following $($candidates.Count) old driver package(s) are candidates for deletion:" -ForegroundColor Yellow
$candidates | Select-Object Driver, OriginalFileName, ProviderName, Date, Version |
    Format-Table -AutoSize | Out-Host

$mode = if ($Force) { "FORCED (will remove drivers in use)" } else { "safe (skips drivers in use)" }
Write-Host "Deletion mode: $mode" -ForegroundColor Yellow

if (-not $WhatIfPreference) {
    Write-Host "WARNING: deletion via 'pnputil /delete-driver' cannot be undone without reinstalling the driver." -ForegroundColor Red
    Write-Host "         You will be prompted before each deletion. Pass -WhatIf to preview only." -ForegroundColor Red
    Write-Host ""
}

$removed = 0
foreach ($old in $candidates) {
    $target = "$($old.Driver) ($($old.OriginalFileName), $($old.Date))"
    $action = if ($Force) {
        "Delete old driver via pnputil /delete-driver /force"
    } else {
        "Delete old driver via pnputil /delete-driver"
    }

    if ($PSCmdlet.ShouldProcess($target, $action)) {
        Write-Host "Deleting old driver: $target"
        if ($Force) {
            pnputil /delete-driver $old.Driver /force
        } else {
            pnputil /delete-driver $old.Driver
        }
        if ($LASTEXITCODE -eq 0) { $removed++ }
    }
    else {
        Write-Host "Would delete: $target"
    }
}

Write-Host ""
if ($WhatIfPreference) {
    Write-Host "Dry run complete. Re-run without -WhatIf (and after user confirmation) to actually delete." -ForegroundColor Cyan
}
else {
    Write-Host "Cleanup complete. Removed $removed old driver package(s)." -ForegroundColor Green
    if (-not $Force) {
        Write-Host "Note: any package bound to a present device was skipped. Re-run with -Force only if the user has explicitly approved removing in-use drivers." -ForegroundColor Cyan
    }
}
