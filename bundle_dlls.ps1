# bundle_dlls.ps1
# Copies the GNU runtime DLLs a .pyd depends on into a distributable folder,
# so a C++ .pyd can run OUTSIDE the conda environment.
#
# Usage:   .\bundle_dlls.ps1 compiled\your_module.cp311-win_amd64.pyd
#          .\bundle_dlls.ps1 compiled\your_module.cp311-win_amd64.pyd -Clean
#          .\bundle_dlls.ps1 compiled\your_module.cp311-win_amd64.pyd -ForceBundle
#
# Output:  creates dist/ containing the .pyd + its required runtime DLLs
#
# Run from the project root with py_pyd_modern ACTIVE.
# NOTE: Pure-Cython/C .pyd files usually need NO bundling. This is mainly for
#       C++ modules that link libstdc++ / libgcc.
# MULTI-MODULE: You can run this repeatedly for several .pyd files into the SAME
#       dist/. Each .pyd is added; shared runtime DLLs already present are SKIPPED
#       (not re-copied), so dist/ ends up with one copy of each needed DLL.
# -Clean: Wipes dist/ contents before bundling, for a fresh single- or
#       multi-module bundle with no leftover files from previous runs.
# -ForceBundle: Copies ALL candidate runtime DLLs that exist in the env,
#       bypassing objdump import detection. Use as an escape hatch when you
#       know a module needs the GNU runtimes but detection reports none.
#       NOTE: still limited to the candidate DLL list below — a dependency
#       outside that list is not copied even with -ForceBundle.
param(
    [Parameter(Mandatory=$true)]
    [string]$PydPath,

    [switch]$Clean,

    [switch]$ForceBundle
)
$ErrorActionPreference = "Stop"

if (-not (Test-Path $PydPath)) {
    Write-Error "File not found: $PydPath"
    exit 1
}

# Where the env's runtime DLLs live
$envBin = Join-Path $env:CONDA_PREFIX "Library\bin"
if (-not (Test-Path $envBin)) {
    Write-Error "Cannot find env Library\bin. Is py_pyd_modern activated? (CONDA_PREFIX=$env:CONDA_PREFIX)"
    exit 1
}

# The GNU runtime DLLs a GCC/G++-built .pyd may depend on
$candidateDlls = @(
    "libstdc++-6.dll",
    "libgcc_s_seh-1.dll",
    "libwinpthread-1.dll"
)

Write-Host "=== Inspecting dependencies of $PydPath ===" -ForegroundColor Cyan
# Use objdump (from the GNU toolchain) to list the .pyd's DLL imports
$deps = & objdump -p $PydPath 2>$null | Select-String "DLL Name:" |
        ForEach-Object { ($_ -split "DLL Name:")[1].Trim() }
if (-not $deps) {
    Write-Warning "objdump returned no dependency info (or objdump not found). Falling back to copying all candidate runtime DLLs."
    $deps = $candidateDlls
}
Write-Host "Detected imports:" -ForegroundColor Gray
$deps | ForEach-Object { Write-Host "  $_" }

if ($ForceBundle) {
    Write-Host "`n-ForceBundle specified: copying all candidate runtime DLLs regardless of detection." -ForegroundColor Yellow
}

# Prepare dist/ output folder
if (-not (Test-Path "dist")) {
    New-Item -ItemType Directory -Path "dist" | Out-Null
}

# -Clean: wipe dist/ contents first for a fresh bundle (opt-in)
if ($Clean) {
    $existing = Get-ChildItem "dist\*" -File
    if ($existing.Count -gt 0) {
        Write-Host "`nNOTICE: -Clean specified. Clearing all existing files from dist/." -ForegroundColor Yellow
        $existing | ForEach-Object {
            Write-Host ("  Removing: {0}" -f $_.Name) -ForegroundColor DarkGray
            Remove-Item $_.FullName -Force
        }
    }
}

# Copy the .pyd itself (always refresh it; notify if replacing an existing one)
$destPyd = Join-Path "dist" (Split-Path $PydPath -Leaf)
if (Test-Path $destPyd) {
    Write-Host ("`nNOTICE: Replacing existing {0} in dist\." -f (Split-Path $PydPath -Leaf)) -ForegroundColor Yellow
}
Copy-Item $PydPath -Destination "dist\" -Force
Write-Host "`nCopied .pyd -> dist\" -ForegroundColor Green

# Copy the required GNU runtime DLLs that exist in the env.
# Normally only DLLs the .pyd imports (per objdump) are copied; -ForceBundle
# overrides detection and copies every candidate that exists in the env.
# Skip DLLs already present in dist/ so multi-module runs don't re-copy shared runtimes.
$copiedCount  = 0
$skippedCount = 0
foreach ($dll in $candidateDlls) {
    if ($ForceBundle -or ($deps -contains $dll)) {
        $destDll = Join-Path "dist" $dll
        if (Test-Path $destDll) {
            Write-Host "Already present, skipped: $dll" -ForegroundColor DarkGray
            $skippedCount++
            continue
        }
        $srcDll = Join-Path $envBin $dll
        if (Test-Path $srcDll) {
            Copy-Item $srcDll -Destination "dist\" -Force
            Write-Host "Bundled: $dll" -ForegroundColor Green
            $copiedCount++
        } else {
            Write-Warning "Dependency $dll not found in env bin — may already be on target system."
        }
    }
}

if (($copiedCount -eq 0) -and ($skippedCount -eq 0)) {
    Write-Host "`nNo GNU runtime DLLs from the candidate list were detected as imports." -ForegroundColor Yellow
    Write-Host "This .pyd likely runs standalone (pure Cython/C modules typically need only python3XX.dll)." -ForegroundColor Yellow
    Write-Host "If you know it needs runtimes anyway, re-run with -ForceBundle to copy all candidates." -ForegroundColor Yellow
}

Write-Host "`n=== dist/ contents ===" -ForegroundColor Cyan
Get-ChildItem "dist\" | Format-Table Name, Length