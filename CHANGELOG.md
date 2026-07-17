# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/).
This project uses [Semantic Versioning](https://semver.org/).

## [2.2.3] - 2026-07-17
### Fixed
- Restored the correct example module `compiled/cython_test_module.cp311-win_amd64.pyd`
  (the one referenced by `README.md` and `example_usage.py`) and removed a stray
  leftover test artifact, `compiled/cython_test_module_2.cp311-win_amd64.pyd`,
  that had been committed by mistake since an early commit. `compiled/` now
  contains exactly the single canonical example module.

## [2.2.2] - 2026-07-17
### Fixed
- README: corrected the Requirements summary from "Cython 3.11.x" back to
  "CPython 3.11.x" (running compiled modules needs CPython, not Cython), and
  fixed a "provide a the" typo in the "Why This Template Package Exists"
  section.

### Changed
- `env/environment.yml`: removed the `defaults` channel so the recipe matches
  the documented conda-forge-only setup.
- `bundle_dlls.ps1`: removed two unreachable `exit 1` statements (with
  `$ErrorActionPreference = "Stop"`, `Write-Error` already terminates).

### Documentation
- `docs/PYD_Workflow_Guide.md`: fixed a stale example path
  (`pyd_building` → `pyd_builder`).
- `CHANGELOG.md`: added a note under `[2.2.0]` recording that the public
  `v2.2.0` tag points at the `v2.1.1` commit and that `-ForceBundle` landed in
  a later commit.

## [2.2.1] - 2026-07-17
### Changed
- README reorganized so the "Why Compile to a `.pyd`?" and "Why This Exists"
  sections lead, ahead of Quick Start — giving new readers the purpose and
  rationale before the commands. Also documented the `-ForceBundle` option in
  the distribution section.

## [2.2.0] - 2026-07-17
> **Tag note:** The public `v2.2.0` git tag points at the same commit as
> `v2.1.1`; the `-ForceBundle` change described below actually landed in a
> later commit. The tag is left in place (public tags are treated as
> immutable); the feature is present from `v2.2.1` onward. Recorded here for
> an accurate history.

### Added
- `bundle_dlls.ps1` gains a `-ForceBundle` switch that copies all candidate GNU
  runtime DLLs present in the environment, bypassing `objdump` import detection.
  This is an escape hatch for cases where a module needs the runtimes but
  detection reports none. (Note: still limited to the script's candidate DLL
  list — a dependency outside that list is not copied even with `-ForceBundle`.)

### Changed
- `bundle_dlls.ps1` "runs standalone" message softened: it no longer over-states
  the conclusion, clarifies that it is based on `objdump` detection, and points
  users to `-ForceBundle` when they know runtimes are needed anyway.

### Documentation
- README: added a "Why Compile to a `.pyd`?" section ahead of "Why This Exists,"
  explaining the purpose of compiling (source protection, performance, clean
  distribution, bridging C/C++) and deferring depth to
  `docs/Compiling_Guidance.md`.

## [2.1.1] - 2026-07-16
### Fixed
- `build.ps1` no longer emits a false "No freshly-built .pyd found" warning on
  rebuilds where setuptools skipped recompilation. The script now clears stale
  `.pyd` files from the project root before building and runs `build_ext` with
  `--force`, guaranteeing a fresh artifact is produced on success. Removed the
  fragile build-start timestamp filter that caused the false warning.

### Changed
- `build.ps1` now performs a CLEAN build every run: it clears all `.pyd` from
  `compiled/` at the start (with a visible notice) before recompiling, so
  `compiled/` always reflects exactly the current build's output. This removes
  any chance of stale or duplicate artifacts being silently retained.
- `bundle_dlls.ps1` is now idempotent for multi-module use: when bundling
  several `.pyd` files into the same `dist/`, shared GNU runtime DLLs already
  present are skipped rather than re-copied, and replacing an existing `.pyd`
  in `dist/` prints a visible notice. Added an optional `-Clean` switch to wipe
  `dist/` before bundling for a fresh single- or multi-module bundle.
- README clarified: documented the clean-build behavior of `build.ps1`
  (`compiled/` is an output directory, cleared each run) and added a decision
  guide for when bundling runtime DLLs is needed.

## [2.1.0] - 2026-07-15
### Added
- `REQUIREMENTS.md` — full requirements spec, including the strict
  CPython 3.11.x version rule (build vs. runtime requirements).
- `CHANGELOG.md` — this file, and added a note in the README.
- Quick Start section and a "Distributing a C++ .pyd" section in README.

### Changed
- LICENSE corrected to the standard DOC/NOAA public-domain notice
  (U.S. Government work, 17 U.S.C. § 105); reformatted with line breaks
  for readability.
- README updated: license section reflects public-domain status; added
  environment-variable dependency notes and REQUIREMENTS reference.

## [2.0.0] - 2026-07-15
### Added
- Multi-module build: `setup.py` compiles all `.py` files in `src/` via
  glob (drop in any source; filename becomes the module name).
- `bundle_dlls.ps1` — bundles a C++ `.pyd`'s GNU runtime DLLs into `dist/`
  for use outside the build environment (validated standalone).
- `example_usage.py` — demonstrates importing a compiled module.
- Environment definitions (`env/`), guidance docs (`docs/`), and portable
  `.vscode` IntelliSense config (uses `${env:CONDA_PREFIX}`, no hardcoded paths).

### Changed
- Project restructured: `src/` (sources), `compiled/` (deliverable .pyd),
  `build/` (transient, gitignored), `env/`, `docs/`.
- Build output collection scoped to fresh artifacts only (`build.ps1`).

## [1.0.0] - Initial (unpublished)
- Basic proof-of-concept: GNU-toolchain `.pyd` build working under conda
  with no admin rights. C, C++, and Cython build paths validated.