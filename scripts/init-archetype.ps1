# Scaffold an archetype into the project.
# Usage: .\scripts\init-archetype.ps1 <archetype> <project_name>
#   e.g. powershell -File scripts\init-archetype.ps1 shared my_app

param(
    [Parameter(Mandatory = $true)]
    [string]$Archetype,

    [Parameter(Mandatory = $true)]
    [string]$Project
)

$ErrorActionPreference = "Stop"

$SkellRoot = "archetypes/skeletons/${Archetype}"

if (-not (Test-Path $SkellRoot)) {
    $available = Get-ChildItem -Directory "archetypes/skeletons/" | ForEach-Object { $_.Name }
    Write-Error "archetype '${Archetype}' not found at ${SkellRoot}/"
    Write-Error "Available: $($available -join ', ')"
    exit 1
}

# Derive naming variants
$ProjLower  = $Project.ToLower().Replace("-", "_")
$ProjUpper  = $Project.ToLower().Replace("-", "_").ToUpper()
$ProjCamel  = $Project -replace '(-|^)([a-z])', { param($m) $m.Matches[0].Groups[2].Value.ToUpper() }

Write-Host "==> Archetype : $Archetype"
Write-Host "==> Project  : $Project ($ProjLower / $ProjUpper / $ProjCamel)"
Write-Host ""

# Build the full set of replacements
$Replacements = @(
    @{ pattern = 'hello';            replacement = $ProjLower  },
    @{ pattern = 'hello_';           replacement = "${ProjLower}_" },
    @{ pattern = 'HELLO';            replacement = $ProjUpper  },
    @{ pattern = 'template_cpp';     replacement = $ProjLower  },
    @{ pattern = 'TEMPLATE_CPP';     replacement = $ProjUpper  },
    @{ pattern = 'Hello';            replacement = $ProjCamel  },
    @{ pattern = 'example_lib';      replacement = $ProjLower  },
    @{ pattern = 'ExampleLib';       replacement = $ProjCamel  },
    @{ pattern = 'plugin';           replacement = $ProjLower  },
    @{ pattern = 'Plugin';           replacement = $ProjCamel  },
    @{ pattern = 'ModuleCard';       replacement = $ProjCamel  },
    @{ pattern = 'myapp';            replacement = $ProjLower  },
    @{ pattern = 'MyApp';            replacement = $ProjCamel  },
)

# Replace template markers in a file and write to target
function Apply-Template {
    param(
        [string]$Src,
        [string]$Target
    )

    # Skip if target already exists (never overwrite user files)
    if (Test-Path $Target) {
        Write-Host "   SKIP  ${Target} (already exists)"
        return
    }

    $content = Get-Content $Src -Raw -Encoding UTF8
    foreach ($r in $Replacements) {
        $content = $content -replace $r.pattern, $r.replacement
    }

    $dir = Split-Path $Target -Parent
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    Set-Content $Target -Value $content -Encoding UTF8
    Write-Host "   created ${Target}"
}

# Process a directory into a destination
function Process-Dir {
    param(
        [string]$SrcDir,
        [string]$DestDir
    )

    if (-not (Test-Path $SrcDir)) { return }

    Get-ChildItem -Path $SrcDir -File | ForEach-Object {
        Apply-Template -Src $_.FullName -Target "${DestDir}/$($_.Name)"
    }
}

# 1) Top-level skeletons -> src/
Process-Dir -SrcDir $SkellRoot -DestDir "src"

# 2) Platform-specific subdirectories
foreach ($subdir in @("linux", "windows", "macos", "win32", "posix")) {
    Process-Dir -SrcDir "${SkellRoot}/${subdir}" -DestDir "src"
}

# 3) Header-only puts everything in include/
if ($Archetype -eq "header_only") {
    Process-Dir -SrcDir $SkellRoot -DestDir "include/aw/${ProjLower}"
}

# 4) Module archetype has a tests/ skeleton
if (Test-Path "${SkellRoot}/tests") {
    Process-Dir -SrcDir "${SkellRoot}/tests" -DestDir "tests"
}

# 5) Migrate tests/ and examples/ — overwrite default hello/example files
function Migrate-Tests {
    $skelTests = "${SkellRoot}/tests"
    if (-not (Test-Path $skelTests)) { return }

    # Remove old default test files
    Remove-Item -Force "tests/test_hello.cpp" -ErrorAction SilentlyContinue
    Remove-Item -Force "tests/test_example.cpp" -ErrorAction SilentlyContinue

    Get-ChildItem -Path $skelTests -File | ForEach-Object {
        $targetName = $_.Name -replace '\.in$', ''
        Apply-Template -Src $_.FullName -Target "tests/${targetName}"
    }
}

function Migrate-Examples {
    $skelExamples = "${SkellRoot}/examples"
    if (-not (Test-Path $skelExamples)) { return }

    # Remove old default example files
    Remove-Item -Force "examples/01_hello.cpp" -ErrorAction SilentlyContinue
    Remove-Item -Force "examples/example_*.cpp" -ErrorAction SilentlyContinue

    Get-ChildItem -Path $skelExamples -File | ForEach-Object {
        $targetName = $_.Name -replace '\.in$', ''
        Apply-Template -Src $_.FullName -Target "examples/${targetName}"
    }
}

Migrate-Tests
Migrate-Examples

Write-Host ""
Write-Host "==> Done. Edit CMakeLists.txt to use the '${Archetype}' archetype helper."
