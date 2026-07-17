# PYD Builder for Python 3.11 on Windows x64

**A template package for building Windows Python extension modules (`.pyd`)
using GNU tools (MinGW/GCC) inside conda — no administrator rights required.**

Compile Python (via Cython), C, or C++ sources into importable `.pyd` modules on
one machine for use on any other Windows machine with a Python 3.11.* environment.  The use of GNU tools instead of Microsoft Visual Studio build tools or extension eliminates any need for administrator credentials or admin-only installable tools.

---

## Why Compile to a `.pyd`?

Compiling a Python module to a `.pyd` turns your source into a binary extension
module — one you `import` exactly like any normal Python module, but that ships
as compiled machine code rather than readable `.py` source. Common reasons to do
this:

- **Protect source.** The distributed `.pyd` is compiled binary, not human-readable
  `.py` — useful when sharing a module without exposing the source.
- **Performance.** Cython-compiled code can run faster than pure Python for
  compute-heavy work.
- **Clean distribution.** Ship a single importable binary module instead of
  loose source files.
- **Bridge C/C++.** Compile C or C++ directly into an importable Python module.

Compiling isn't always the right call — see
[docs/Compiling_Guidance.md](docs/Compiling_Guidance.md) for when it's worthwhile
and when it isn't.

---

## Why This Exists

On Windows, Python normally expects the MSVC toolchain (VS Build Tools) to build extensions, which always requires admin rights to install. This template uses **conda** to provide a complete, modern **GNU toolchain (GCC 15.2, UCRT)** plus the Python import library, all installed at the user level without the need for administrator credentials.

---

## Quick Start

```powershell
# 1. Create + activate the build environment (one-time — see REBUILD.md for the
#    required compiler shim step)
conda create -n py_pyd_modern -c conda-forge python=3.11 libpython gcc_win-64 gxx_win-64 cython
conda activate py_pyd_modern

# 2. Put your Python source in src/ (filename = module name)
#    Then build:
.\build.ps1

# 3. Your compiled .pyd is in compiled/. Try the included example:
python example_usage.py
```

**First time?** Read [REBUILD.md](REBUILD.md) — the environment needs a one-time
compiler shim to work.

> ⚠️ **Compiled modules require CPython 3.11.x specifically.** See
> [REQUIREMENTS.md](REQUIREMENTS.md).

---

## Requirements

**Summary:** conda, Windows x64, and **CPython 3.11.x** for running compiled modules.

See **[REQUIREMENTS.md](REQUIREMENTS.md)** for the complete specification,
including the strict Python-version rule and build vs. runtime requirements.

---

## Environment Setup

Full setup — including the **required compiler shim** — is documented in
**[REBUILD.md](REBUILD.md)**. Read that first.

Environment definitions live in **[env/](env/)**:

- `env/environment.yml` — portable recipe (`--from-history`)
- `env/py_pyd_modern_lock.yml` — exact lockfile (all resolved versions)

---

## How the Build Config Finds Your Compiler

The build and IntelliSense configuration is **portable by design** — it uses
the `CONDA_PREFIX` environment variable rather than hardcoded paths, so it
works on any machine without editing.

**This means the following MUST be true for it to work:**

1. You have created the conda environment (see [REBUILD.md](REBUILD.md) and
   [env/](env/)) with the GNU toolchain packages.
2. **That environment is ACTIVATED** before you build or open the project —
   activation is what sets `CONDA_PREFIX`:
   ```powershell
   conda activate py_pyd_modern
   ```
3. The compiler shims (`gcc.exe` / `g++.exe`) have been applied inside the
   environment (one-time step — see [REBUILD.md](REBUILD.md)).

If IntelliSense can't find `Python.h`, or the build can't find `gcc`, the most
common cause is **the conda environment is not activated** (so `CONDA_PREFIX`
is unset or points at the wrong environment).

> **VS Code note:** If IntelliSense doesn't resolve after activating the env,
> select the conda interpreter (*Python: Select Interpreter*) and reload the
> window (*Developer: Reload Window*) so VS Code picks up `CONDA_PREFIX`.

---

## Build Workflow

1. **Add your source** to `src/`. The **filename becomes the module name**, so
   name it what you want to `import` (must be a valid Python identifier).
   Drop multiple `.py` files in `src/` and each becomes its own `.pyd`.
   ```
   src\python_module.py   →   import python_module
   ```
2. **Build:**
   ```powershell
   conda activate py_pyd_modern
   .\build.ps1
   ```
3. **Collect** the compiled `.pyd` from **`compiled/`**.

> ⚠️ **`build.ps1` performs a CLEAN build every run.** Before compiling, it
> **deletes all existing `.pyd` files from `compiled/`** (and clears any stale
> `.pyd` from the project root), then force-recompiles. This guarantees
> `compiled/` always contains exactly the current build's output — no stale or
> leftover modules.
>
> **What this means for you:** `compiled/` is a build *output* directory, not a
> storage location. Do not keep anything in `compiled/` you aren't willing to
> lose on the next build. If you need to archive a specific `.pyd`, copy it
> somewhere else first.

---

## Try the Included Example

The repo ships with a pre-built example module. Run:

```powershell
python example_usage.py
```

This imports the compiled example `.pyd` from `compiled/` and calls its
functions — demonstrating the full flow from source to importable module.

---

## Distributing a `.pyd` Outside the Build Environment

**When do you need this?** Only when you will run a compiled `.pyd` on a machine
or in a folder that does **not** have the conda build environment active.

Use this decision guide:

| Your module is... | Running where? | Do you need to bundle? |
|-------------------|----------------|------------------------|
| Pure Cython (`.py`) or C | Anywhere with CPython 3.11.x | **No** — needs only `python311.dll` |
| **C++** | Inside the conda env | **No** — DLLs are already on the path |
| **C++** | Outside the env (another machine/folder) | **Yes** — bundle the GNU runtime DLLs |

C++ modules depend on GNU runtime DLLs (`libstdc++-6.dll`,
`libgcc_s_seh-1.dll`) that live in the build environment. Outside that
environment they won't be found, and the import will fail. Bundling copies them
next to the `.pyd`.

**How to bundle:**

```powershell
.\bundle_dlls.ps1 compiled\your_module.cp311-win_amd64.pyd
```

This creates a `dist/` folder containing the `.pyd` and its required GNU runtime
DLLs. **Copy the whole `dist/` folder to the target machine and run from within
it — the DLLs must sit alongside the `.pyd` wherever it runs.**

> **Notes:**
> - Bundling is a **separate, deliberate step** — the normal `build.ps1` does
>   *not* bundle. Reach for `bundle_dlls.ps1` only when you're shipping a C++
>   module out of the environment.
> - Bundling a pure Cython/C module is harmless but unnecessary — it only adds
>   files those modules never use.
> - If a module needs the GNU runtimes but detection reports none, re-run with
>   `-ForceBundle` to copy all candidate DLLs regardless of detection.
> - The target machine still requires **CPython 3.11.x** (see
>   [REQUIREMENTS.md](REQUIREMENTS.md)).
> - For production-scale distribution, consider a dedicated tool like
>   `delvewheel`.

---

## Project Structure

```
src/          Sources to compile (filename = module name)
compiled/     Deliverable .pyd output — CLEARED and repopulated each build
              (the example .pyd is committed here)
build/        Transient build artifacts — regenerated each build (gitignored)
dist/         Bundled distributable output from bundle_dlls.ps1 (gitignored)
env/          conda environment definitions (recipe + lockfile)
docs/         Guidance documents
.vscode/      IntelliSense configuration
build.ps1     Clean-builds: clears compiled/, force-recompiles, moves .pyd to compiled/
bundle_dlls.ps1    Bundles a C++ .pyd's runtime DLLs into dist/
setup.py      Build recipe (Cython + setuptools; compiles all src/*.py)
example_usage.py   Demonstrates importing the compiled module
REQUIREMENTS.md    Full requirements, incl. the strict Python-version rule
REBUILD.md    How to recreate the environment (READ THIS FIRST)
```

---

## Documentation

- **[REQUIREMENTS.md](REQUIREMENTS.md)** — Full requirements; the strict Python
  3.11.x rule, build vs. runtime needs.
- **[REBUILD.md](REBUILD.md)** — Recreate the build environment, including the
  critical compiler shim step. **START HERE.**
- **[docs/PYD_Workflow_Guide.md](docs/PYD_Workflow_Guide.md)** — What you can and
  cannot change (filenames, module names, etc.) and common gotchas.
- **[docs/Compiling_Guidance.md](docs/Compiling_Guidance.md)** — When compiling
  to `.pyd` is worthwhile, and when it isn't.
- **[CHANGELOG.md](CHANGELOG.md)** — Version history and notable changes.

---

## Key Things to Know

- **A `.pyd` is locked to CPython 3.11.x** — it will only import into Python
  3.11 (any patch). See [REQUIREMENTS.md](REQUIREMENTS.md).
- **Never rename a compiled `.pyd`** to change its module name — the name is
  baked into the binary. Rename the **source** file and rebuild instead.
- **Keep all work inside the conda env.** Do not build in an MSYS2 shell or
  against system Python — it causes ABI mismatches.
- **This is Windows x64 specific.** A `.pyd` built here will not run on Linux or macOS.

---

## Toolchain (verified working)

| Component | Version |
|-----------|---------|
| Python    | 3.11 (conda-forge) |
| Compiler  | GCC / G++ 15.2 (conda-forge, UCRT) |
| Cython    | 3.x |
| Platform  | Windows x64 |

---

## License

Software code created by U.S. Government employees is not subject to copyright
in the United States (17 U.S.C. § 105). This work is in the public domain in the
United States — free to use, copy, modify, and build upon.

See [LICENSE](LICENSE) for the full notice, including terms regarding
copyright outside the United States.