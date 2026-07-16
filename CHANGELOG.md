# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/).
This project uses [Semantic Versioning](https://semver.org/).

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