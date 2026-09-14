[CmdletBinding()]
param(
    [ValidateSet('pull', 'push', 'status')][string]$Action = 'status',
    [string]$Message,
    [switch]$People
)

$ErrorActionPreference = 'Stop'

$configPath = Join-Path $HOME '.claude/em/config.json'
if (-not (Test-Path $configPath)) { throw "no config at $configPath - run em_init.ps1 first" }

$config = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable

if ($People) {
    $repo = $config['people']
    if (-not $repo -or -not $repo['enabled']) { throw "people store not enabled - run em_init.ps1 -People first" }
    $dir = if ($repo['dir']) { $repo['dir'] } else { 'people' }
    if ($repo['sameRepo']) {
        $path = $config['delivery']['path']
        $branch = $config['delivery']['branch']
    }
    else {
        $path = $repo['path']
        $branch = $repo['branch']
    }
    $dirs = @($dir)
    $tier = 'people'
}
else {
    $repo = $config['delivery']
    if (-not $repo -or -not $repo['path']) { throw "delivery store not configured - run em_init.ps1 first" }
    $path = $repo['path']
    $branch = $repo['branch']
    $dirs = @('state', 'reports')
    $tier = 'delivery'
}

if (-not $path) { throw "$tier store has no path - run em_init.ps1 first" }
if (-not (Test-Path (Join-Path $path '.git'))) { throw "not a git clone: $path" }

switch ($Action) {
    'status' {
        $dirty = git -C $path status --porcelain
        $lastChange = git -C $path log -1 --format=%cs -- $dirs
        $lastReport = Get-ChildItem (Join-Path $path 'reports') -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name | Select-Object -Last 1
        Write-Output "tier: $tier ($($dirs -join ', '))"
        Write-Output "repo: $path ($branch)"
        Write-Output "head: $(git -C $path log -1 --oneline)"
        Write-Output "last change: $(if ($lastChange) { $lastChange } else { 'never' })"
        if (-not $People) {
            Write-Output "last report: $(if ($lastReport) { $lastReport.Name } else { 'never' })"
        }
        if ($dirty) { Write-Output "uncommitted:"; $dirty } else { Write-Output "clean" }
    }

    'pull' {
        $dirty = git -C $path status --porcelain
        if ($dirty) {
            Write-Output "STOP: uncommitted changes in $path"
            $dirty
            exit 1
        }
        git -C $path fetch origin $branch
        if ($LASTEXITCODE -ne 0) { throw "fetch failed" }
        git -C $path merge --ff-only "origin/$branch"
        if ($LASTEXITCODE -ne 0) {
            Write-Output "STOP: local and remote have diverged - resolve manually, do not discard either side"
            exit 1
        }
        Write-Output "at $(git -C $path log -1 --oneline)"
    }

    'push' {
        if (-not $Message) { throw "-Message is required for push" }
        foreach ($d in $dirs) {
            if (Test-Path (Join-Path $path $d)) { git -C $path add $d }
        }
        $staged = git -C $path diff --cached --name-only
        if (-not $staged) { Write-Output "nothing to commit"; exit 0 }
        git -C $path commit -m $Message
        if ($LASTEXITCODE -ne 0) { throw "commit failed" }
        git -C $path push origin $branch
        if ($LASTEXITCODE -ne 0) { throw "push failed; commit is local at $path" }
        Write-Output "pushed $(git -C $path log -1 --oneline)"
        $staged | ForEach-Object { Write-Output "  $_" }
    }
}
