# build.ps1 — Build the extension and place the deliverable .pyd in compiled/
# Run from the project root with the py_pyd_modern conda env ACTIVE.
#
# This performs a CLEAN build every run:
#   - removes stale .pyd from the project root,
#   - clears all .pyd from compiled/,
#   - force-recompiles so a fresh .pyd is always produced on success.
$ErrorActionPreference = "Stop"

Write-Host "=== Verifying compiler ===" -ForegroundColor Cyan
$gccVersion = (gcc --version | Select-Object -First 1)
Write-Host $gccVersion
if ($gccVersion -notmatch "conda-forge") {
    Write-Warning "gcc does not appear to be the conda-forge compiler! Check env activation and shims."
}

# --- Clean stale root .pyd so every build is deterministic (no timestamp guessing) ---
Write-Host "`n=== Cleaning stale root .pyd files ===" -ForegroundColor Cyan
Get-ChildItem -Path "." -Filter "*.pyd" | ForEach-Object {
    Write-Host ("Removing stale: {0}" -f $_.Name) -ForegroundColor DarkGray
    Remove-Item $_.FullName -Force
}

# --- Clean compiled/ so the fresh build always lands in a known-empty target ---
Write-Host "`n=== Preparing compiled/ ===" -ForegroundColor Cyan
if (Test-Path "compiled") {
    $existing = Get-ChildItem "compiled\*.pyd"
    if ($existing.Count -gt 0) {
        Write-Host "NOTICE: Clearing all existing .pyd files from compiled/ (fresh build)." -ForegroundColor Yellow
        $existing | ForEach-Object {
            Write-Host ("  Removing: {0}" -f $_.Name) -ForegroundColor DarkGray
            Remove-Item $_.FullName -Force
        }
    }
} else {
    New-Item -ItemType Directory -Path "compiled" | Out-Null
}

Write-Host "`n=== Building extension ===" -ForegroundColor Cyan
# --force ensures setuptools re-emits the .pyd even if it thinks it's up to date
python setup.py build_ext --inplace --force --compiler=mingw32

Write-Host "`n=== Collecting .pyd into compiled/ ===" -ForegroundColor Cyan
# Root was cleaned pre-build, so anything here IS this build's output. No timestamp filter.
$pyds = Get-ChildItem -Path "." -Filter "*.pyd"   # no -Recurse

if ($pyds.Count -eq 0) {
    Write-Warning "No .pyd produced. The build likely FAILED - check output above."
} else {
    foreach ($pyd in $pyds) {
        Move-Item $pyd.FullName -Destination "compiled\"   # target is clean; no -Force needed
        Write-Host ("Moved: {0} -> compiled\" -f $pyd.Name) -ForegroundColor Green
    }
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
Get-ChildItem "compiled\*.pyd" | Format-Table Name, Length, LastWriteTime