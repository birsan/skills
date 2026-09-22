[CmdletBinding()]
param(
    [string]$Remote,
    [string]$Path,
    [string]$Branch = 'main',
    [switch]$People,
    [switch]$SameRepo
)

$ErrorActionPreference = 'Stop'

if ($SameRepo -and -not $People) { throw "-SameRepo applies to -People only" }
if (-not $SameRepo -and -not $Remote -and -not $Path) { throw "-Remote or -Path is required" }

function New-PeopleScaffold {
    param([string]$Root, [string]$Dir)

    $target = Join-Path $Root $Dir
    New-Item -ItemType Directory -Force $target | Out-Null

    Set-Content (Join-Path $target 'README.md') @'
# People store

**This repository cannot be shared.** It holds 1:1 notes, growth evidence and performance
observations alongside delivery state. GitHub grants access per repository, not per directory,
so adding any collaborator - a stand-in covering leave, a peer manager, a skip-level who only
wants the dependency rows - grants them this directory too. Git history is permanent, so a
mistake here is a history rewrite rather than a deletion.

If delivery state ever needs sharing, extract `state/` into a separate repository. Do not add
access to this one.

One file per person, named by the `Key` in `state/team.md`. Never referenced from delivery
state, never quoted in a report.
'@

    Set-Content (Join-Path $target 'inbox.md') @'
## Notes

## Open questions

## Processed
'@
}

function New-DeliveryScaffold {
    param([string]$Root)

    New-Item -ItemType Directory -Force (Join-Path $Root 'state') | Out-Null
    New-Item -ItemType Directory -Force (Join-Path $Root 'reports') | Out-Null

    Set-Content (Join-Path $Root 'state/team.md') @'
| Person | Key | Git | Level | Focus area | Alloc % | Ramp | Away | On-call | Notes |
|---|---|---|---|---|---|---|---|---|---|
'@
    Set-Content (Join-Path $Root 'state/initiatives.md') @'
| ID | Initiative | Goal | Owner | Status | Target | Deadline | Remaining | Confidence | Stakeholder | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
'@
    Set-Content (Join-Path $Root 'state/dependencies.md') @'
| ID | Direction | Counterparty | Item | Our owner | Their owner | Due | Status | Blocker |
|---|---|---|---|---|---|---|---|---|
'@
    Set-Content (Join-Path $Root 'state/risks.md') @'
| ID | Type | Opened | Description | Impact | Owner | Mitigation / Ask | Status | Closed |
|---|---|---|---|---|---|---|---|---|
'@
    Set-Content (Join-Path $Root 'state/inbox.md') @'
## Notes

## Open questions

## Processed
'@
    Set-Content (Join-Path $Root 'state/stakeholders.md') @'
## self
- Surface first:
- Attention horizon: 2 weeks
- Ask age limit: 14
- Stale after: 2 cycles
- Cycle: weekly

## capacity
- Horizon: 8 weeks
- On-call factor: 0.5
- Ramp factor: 0.5
- Notice factor: 0.5
- No-slack threshold: 0.85

## exec
- Who:
- Cadence:
- Delivery: user sends by hand
- Cares about:
- Omit:
- Tone:
- Never include: anything about individual performance

## product
- Who:
- Cadence:
- Delivery: user sends by hand
- Cares about:
- Omit:
- Tone:

## peer
- Counterparties:
- Cadence:
- Delivery: user sends by hand
- Tone:

## team
- Cadence:
- Delivery: user sends by hand
- Tone:
'@
}

$configPath = Join-Path $HOME '.claude/em/config.json'
$configDir = Split-Path $configPath -Parent
if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Force $configDir | Out-Null }

$config = if (Test-Path $configPath) {
    Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
}
else {
    @{
        identity = @{ name = ''; team = '' }
        delivery = @{ remote = ''; path = ''; branch = 'main' }
        people   = @{ enabled = $false; sameRepo = $true; dir = 'people'; remote = ''; path = ''; branch = 'main' }
        sources  = @{ repos = @() }
    }
}

if ($SameRepo) {
    $deliveryPath = $config['delivery']['path']
    if (-not $deliveryPath -or -not (Test-Path (Join-Path $deliveryPath '.git'))) {
        throw "delivery store must be initialized first"
    }
    $dir = if ($config['people']['dir']) { $config['people']['dir'] } else { 'people' }

    if (Test-Path (Join-Path $deliveryPath $dir)) {
        Write-Output "already initialized: $(Join-Path $deliveryPath $dir)"
    }
    else {
        New-PeopleScaffold -Root $deliveryPath -Dir $dir
        git -C $deliveryPath add $dir
        git -C $deliveryPath commit -m "em: scaffold people store"
        git -C $deliveryPath push origin $config['delivery']['branch']
        if ($LASTEXITCODE -ne 0) { throw "push failed; scaffold is committed locally at $deliveryPath" }
        Write-Output "scaffolded $dir inside the delivery repo"
    }

    $config['people']['enabled'] = $true
    $config['people']['sameRepo'] = $true
    $config['people']['dir'] = $dir
    $config | ConvertTo-Json -Depth 6 | Set-Content $configPath
    Write-Output "config written: $configPath"
    return
}

$tier = if ($People) { 'people' } else { 'delivery' }
$dir = if ($config['people']['dir']) { $config['people']['dir'] } else { 'people' }
if (-not $Path) { $Path = Join-Path $configDir $(if ($People) { 'people' } else { 'state' }) }

$existing = Test-Path (Join-Path $Path '.git')

if (-not $existing) {
    $heads = git ls-remote --heads $Remote 2>$null
    if ($LASTEXITCODE -ne 0) { throw "cannot reach remote: $Remote" }

    if ($heads) {
        git clone $Remote $Path
        if ($LASTEXITCODE -ne 0) { throw "clone failed: $Remote" }
        Write-Output "cloned $Remote -> $Path"
    }
    else {
        New-Item -ItemType Directory -Force $Path | Out-Null
        git -C $Path init -b $Branch
        git -C $Path remote add origin $Remote
        Write-Output "initialized empty repo at $Path"
    }
}

if (-not $Remote) {
    $Remote = (git -C $Path remote get-url origin).Trim()
}
$resolved = (git -C $Path symbolic-ref --short HEAD 2>$null)
if ($resolved) { $Branch = $resolved.Trim() }

$scaffoldTarget = if ($People) { Join-Path $Path $dir } else { Join-Path $Path 'state' }

if (Test-Path $scaffoldTarget) {
    Write-Output "already scaffolded: $scaffoldTarget"
}
else {
    if ($People) { New-PeopleScaffold -Root $Path -Dir $dir } else { New-DeliveryScaffold -Root $Path }
    git -C $Path add .
    git -C $Path commit -m "em: scaffold $tier store"
    if ($LASTEXITCODE -ne 0) { throw "commit failed" }
    git -C $Path push -u origin $Branch
    if ($LASTEXITCODE -ne 0) { throw "push failed; scaffold is committed locally at $Path" }
    Write-Output "scaffolded and pushed $tier store -> $Remote"
}

$config[$tier]['remote'] = $Remote
$config[$tier]['path'] = $Path
$config[$tier]['branch'] = $Branch
if ($People) {
    $config['people']['enabled'] = $true
    $config['people']['sameRepo'] = $false
}

$config | ConvertTo-Json -Depth 6 | Set-Content $configPath
Write-Output "config written: $configPath"
