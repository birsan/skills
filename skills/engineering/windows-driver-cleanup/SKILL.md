---
name: windows-driver-cleanup
description: Find and remove old, duplicate third-party drivers on Windows by keeping only the newest version of each OEM driver package. Use when the user wants to clean up Windows drivers, reclaim disk space from stale driver versions, remove duplicate OEM drivers, or trim the DriverStore.
---

# Windows driver cleanup

Removes older copies of third-party drivers (`oem*.inf`) from the Windows DriverStore, keeping only the newest version of each driver package. Windows accumulates these copies every time a driver is updated, and they are never pruned automatically.

## ⚠ This is a destructive operation — confirm with the user first

Deleting driver packages is **not reversible without reinstalling the driver**. Before running the actual deletion you MUST:

1. **Always run the dry run first** (`-WhatIf`) and show the user the full list of packages that would be removed.
2. **Get explicit confirmation** from the user — quoting the exact list — before invoking the script without `-WhatIf`. Do not infer consent from an earlier "clean up my drivers" request.
3. **Recommend a System Restore point** before the destructive run, especially on a machine the user depends on (work laptop, production host).
4. **Do NOT pass `-Force` by default.** The script defaults to a safe deletion that skips drivers bound to a present device. Only pass `-Force` if the user has *explicitly* asked to remove in-use drivers — for example: "force it", "remove even if in use", "use /force". A general "clean it up" or "remove all old drivers" is **not** a request for force.

Never silently chain the dry run into the real deletion in the same step.

## Prerequisites

- Windows 10 / 11 (or Windows Server with the matching cmdlets).
- **PowerShell must be run as Administrator** — both `Get-WindowsDriver -Online` and `pnputil /delete-driver` require elevation.
- Recommended: create a System Restore point before running, in case a still-in-use driver is removed.

## Workflow

1. Open PowerShell as Administrator.
2. Run [`scripts/cleanup-old-drivers.ps1`](scripts/cleanup-old-drivers.ps1) **with `-WhatIf`** and show the user the proposed deletions.
3. Pause and ask the user, in plain language, whether to proceed — list how many packages and which devices are affected.
4. Only after explicit "yes", run the script without `-WhatIf`. The script will still prompt per-package (`ConfirmImpact='High'`); use `-Confirm:$false` only if the user has explicitly said "delete all of them without prompting".
5. **Do not add `-Force`** unless the user explicitly asked to remove drivers that are currently in use. Without `-Force`, `pnputil` skips any package bound to a present device, which is the safe default.

```powershell
# Step 1 — dry run. Always run this first.
.\scripts\cleanup-old-drivers.ps1 -WhatIf

# Step 2 — destructive run, safe mode (no /force). Only after user confirmation.
#          PowerShell prompts before each deletion. In-use drivers are skipped.
.\scripts\cleanup-old-drivers.ps1

# Step 3 (optional) — user has reviewed the list and wants no per-item prompts.
.\scripts\cleanup-old-drivers.ps1 -Confirm:$false

# Forced mode — ONLY if the user explicitly asked to remove in-use drivers.
.\scripts\cleanup-old-drivers.ps1 -Force
```

## What the script does

1. Lists every third-party driver package currently in the DriverStore via `Get-WindowsDriver -Online -All`, filtered to `oem*.inf`.
2. Groups packages by `OriginalFileName` (the original `.inf` name) so each group represents the same driver across versions.
3. For groups with more than one entry, sorts by `Date` descending and **keeps only the newest**.
4. Runs `pnputil /delete-driver <oemNN.inf>` on each older package — **without** `/force` by default. Pass `-Force` only on explicit user request.

## The core logic (safe mode, default)

```powershell
# Get all third-party drivers
$drivers = Get-WindowsDriver -Online -All | Where-Object { $_.Driver -like "oem*.inf" }

# Group by the original file name to find duplicates (older versions)
$grouped = $drivers | Group-Object OriginalFileName | Where-Object { $_.Count -gt 1 }

foreach ($group in $grouped) {
    # Sort by date and keep the newest one, select the older ones
    $oldDrivers = $group.Group | Sort-Object Date -Descending | Select-Object -Skip 1

    foreach ($old in $oldDrivers) {
        Write-Host "Deleting old driver: $($old.Driver) ($($old.OriginalFileName))"
        pnputil /delete-driver $old.Driver   # no /force — skips drivers in use
    }
}
```

## About the `-Force` flag (opt-in only)

By default the script runs `pnputil /delete-driver` **without** `/force`. `pnputil` will then refuse to delete any package bound to a present device, which is the safe behavior — pick this whenever the user says "clean up", "remove old drivers", or anything similar.

Pass `-Force` to the script **only when the user explicitly asks** for it (e.g. "force delete", "remove even if in use", "use /force"). With `-Force`, `pnputil /delete-driver ... /force` will remove the package even if a device is currently using it. Because the script always preserves the newest version, the affected device should fall back to that newer copy, but you should still:

- Reboot after a forced cleanup so any in-use drivers are released cleanly.
- Avoid forced cleanup right before something critical (production, a presentation, etc.).

## Verifying the result

```powershell
# Count of installed third-party driver packages (should drop after cleanup)
(pnputil /enum-drivers | Select-String "Published Name").Count

# Or via the cmdlet
(Get-WindowsDriver -Online -All | Where-Object { $_.Driver -like "oem*.inf" }).Count
```

## Troubleshooting

- **"Access is denied" / nothing happens** — PowerShell is not elevated. Re-launch as Administrator.
- **`pnputil` reports "in use"** — only happens without `/force`; reboot and rerun, or accept the `/force` behavior described above.
- **Driver reappears after cleanup** — Windows Update reinstalled it. That is expected; the cleanup keeps the install slim, it does not block future updates.
