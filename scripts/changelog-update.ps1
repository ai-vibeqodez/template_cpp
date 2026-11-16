<#
.SYNOPSIS
    Update CHANGELOG.md [Unreleased] from git log (Windows; Linux/macOS: scripts/changelog-update.sh).

.DESCRIPTION
    Scans commits since the latest tag, groups them by conventional commit prefix,
    and writes them into ## [Unreleased] in CHANGELOG.md.

.PARAMETER DryRun
    Print what would be added without modifying files.

.PARAMETER Force
    Overwrite [Unreleased] even if it already has entries.

.EXAMPLE
    .\scripts\changelog-update.ps1
    .\scripts\changelog-update.ps1 -DryRun
    .\scripts\changelog-update.ps1 -Force
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
    [Console]::Error.WriteLine("error: $Message")
    exit 1
}

function Get-GitOutput {
    $out = & git @args
    if ($LASTEXITCODE -ne 0) { Fail "git $($args -join ' ') failed (exit code $LASTEXITCODE)" }
    return $out
}

$root = (Get-GitOutput rev-parse --show-toplevel | Select-Object -First 1)
Set-Location $root

$changelog = 'CHANGELOG.md'
if (-not (Test-Path -LiteralPath $changelog)) { Fail "$changelog not found" }

# Determine the previous tag.
$prevTag = (Get-GitOutput tag -l 'v*' --sort=-version:refname | Select-Object -First 1)
if ($prevTag) {
    $range = "$prevTag..HEAD"
} else {
    $range = 'HEAD'
}

# Collect commit subjects.
$commits = Get-GitOutput log --pretty=format:'%s' $range
if (-not $commits) { Write-Host "No commits found in $range"; exit 0 }

# Skip keywords for infra-only ci/chore commits.
$skipKeywords = @('workflow', 'github', 'action', 'deps', 'dependency', 'format', 'lint', 'prettier', 'eslint')

function ShouldSkip([string]$subject) {
    foreach ($p in @('ci', 'chore')) {
        if ($subject.StartsWith("$p(")) {
            foreach ($k in $skipKeywords) {
                if ($subject -ilike "*$k*") { return $true }
            }
        }
    }
    return $false
}

function Clean-Entry([string]$subject) {
    return $subject -replace '^[a-z]+\([^)]*\): *', '' -replace '^[a-z]+: *', ''
}

# Categories as ordered dictionary.
$categories = [ordered]@{
    breaking = [System.Collections.Generic.List[string]]::new()
    feature  = [System.Collections.Generic.List[string]]::new()
    fix      = [System.Collections.Generic.List[string]]::new()
    change   = [System.Collections.Generic.List[string]]::new()
    remove   = [System.Collections.Generic.List[string]]::new()
}

foreach ($line in $commits) {
    if (-not $line) { continue }

    $isBreaking = $false
    $cleanLine = $line

    # Check for breaking change: !: suffix
    if ($cleanLine -match '^[a-z]+\([^)]*\)!: ') {
        $isBreaking = $true
        $cleanLine = $cleanLine -replace '!:', ':'
    } elseif ($cleanLine -match '^[a-z]+!: ') {
        $isBreaking = $true
        $cleanLine = $cleanLine -replace '!: ', ': '
    }

    if ($cleanLine -match 'BREAKING CHANGE') {
        $isBreaking = $true
    }

    # Skip infra-only ci/chore
    if (ShouldSkip $cleanLine) { continue }

    $category = 'change'
    if ($cleanLine -match '^feat(\(|:)') { $category = 'feature' }
    elseif ($cleanLine -match '^fix(\(|:)') { $category = 'fix' }
    elseif ($cleanLine -match '^(perf|refactor|docs|style|chore|ci|build)(\(|:)') { $category = 'change' }
    elseif ($cleanLine -match '^test(\(|:)') { $category = 'fix' }
    elseif ($cleanLine -match '^revert(\(|:)') { $category = 'remove' }

    if ($isBreaking) {
        $categories.breaking.Add((Clean-Entry $cleanLine))
    } else {
        $categories[$category].Add((Clean-Entry $cleanLine))
    }
}

# --dry-run: print what would be added.
if ($DryRun) {
    Write-Host "=== What would be added to [Unreleased] ==="
    $catDisplay = @{
        breaking = 'Breaking'; feature = 'Added'; fix = 'Fixed'
        change = 'Changed'; remove = 'Removed'
    }
    foreach ($key in $categories.Keys) {
        $entries = $categories[$key]
        if ($entries.Count -eq 0) { continue }
        Write-Host ""
        Write-Host "### $($catDisplay[$key])"
        Write-Host ""
        foreach ($e in $entries) { Write-Host "- $e" }
    }
    exit 0
}

# Check if [Unreleased] already has entries.
$hasUnreleased = Select-String -Path $changelog -Pattern '^## \[Unreleased\]' -Quiet
if ($hasUnreleased -and -not $Force) {
    Fail '[Unreleased] already has entries. Use -Force to overwrite, or run release.sh to cut a release first.'
}

# Build the [Unreleased] section content.
$sectionLines = [System.Collections.Generic[List[string]]]::new()
$sectionLines.Add('## [Unreleased]')

$catDisplay = @{
    breaking = 'Breaking'; feature = 'Added'; fix = 'Fixed'
    change = 'Changed'; remove = 'Removed'
}

foreach ($key in $categories.Keys) {
    $entries = $categories[$key]
    if ($entries.Count -eq 0) { continue }

    $sectionLines.Add('')
    $sectionLines.Add("### $($catDisplay[$key])")
    $sectionLines.Add('')
    foreach ($e in $entries) { $sectionLines.Add("- $e") }
}

$sectionContent = ($sectionLines -join "`n") + "`n"

# Read the changelog.
$raw = [System.IO.File]::ReadAllText((Join-Path $root $changelog))
$crlf = $raw.Contains("`r`n")
$lines = [System.Collections.Generic[List[string]]]::new()
$lines.AddRange([string[]]($raw -split "\r?\n"))
if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') { $lines.RemoveAt($lines.Count - 1) }

$result = [System.Collections.Generic[List[string]]]::new()

if ($hasUnreleased) {
    # Replace existing [Unreleased] section.
    $startIdx = -1
    $endIdx = $lines.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^## \[Unreleased\]') { $startIdx = $i; break }
    }
    if ($startIdx -ge 0) {
        for ($i = $startIdx + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^## \[') { $endIdx = $i; break }
        }
        $result.AddRange($lines.GetRange(0, $startIdx + 1))
        $result.AddRange(($sectionContent -split "`n"))
        $result.AddRange($lines.GetRange($endIdx, $lines.Count - $endIdx))
    }
} else {
    # Insert after "# Changelog" header.
    $inserted = $false
    foreach ($line in $lines) {
        $result.Add($line)
        if (-not $inserted -and $line -match '^# Changelog$') {
            $result.Add('')
            $result.AddRange(($sectionContent -split "`n"))
            $inserted = $true
        }
    }
}

# Write back.
$newline = if ($crlf) { "`r`n" } else { "`n" }
$text = ($result -join $newline) + $newline
[System.IO.File]::WriteAllText((Join-Path $root $changelog), $text, (New-Object System.Text.UTF8Encoding($false)))

$total = 0
foreach ($key in $categories.Keys) { $total += $categories[$key].Count }
Write-Host "Updated CHANGELOG.md: $total commit(s) added to [Unreleased]."
