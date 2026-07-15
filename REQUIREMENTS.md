# Requirements

This document specifies the requirements for **building** `.pyd` modules with
this template, and for **running** the compiled modules it produces.

---

## ⚠️ Python Version — STRICT: CPython 3.11.x ONLY

The compiled `.pyd` modules produced (and the included example) are built for
**CPython 3.11** and will **ONLY** import into a **CPython 3.11.x** interpreter.  In other words, it works under Python 3.11.* only.

| Target Python | Works? |
|---------------|--------|
| 3.11.0 – 3.11.x (any patch) | ✅ Yes |
| 3.12.x | ❌ No |
| 3.13.x | ❌ No |
| 3.10.x or older | ❌ No |
| PyPy / non-CPython | ❌ No |

**Why:** A compiled Python extension is locked to the Python **minor version**
that built it (the `cp311` tag in the filename). The `.pyd` links against
`python311.dll` specifically; other Python versions ship a different runtime
DLL (`python312.dll`, etc.) and cannot load a `cp311` module. This is standard
behavior for **all** Python compiled extensions (numpy, pandas, etc.) — not a
limitation of this template.

- **Patch version is flexible:** 3.11.0, 3.11.9, 3.11.15 — any 3.11.x works.
- **Minor version is fixed:** 3.10, 3.12, 3.13 will not work.

**To target a different Python version:** rebuild everything under an
environment of that version (e.g., create a Python 3.12 conda env with the
toolchain, then rebuild — the output would be tagged `cp312` and require Python 3.12.*).

---

## Build Requirements

To **build** `.pyd` modules with this template:

| Requirement | Details |
|-------------|---------|
| conda | Miniconda or Anaconda |
| OS | Windows x64 |
| PowerShell (preferably v7.x) | TO run `build.ps1` |
| Build environment | See [REBUILD.md](REBUILD.md) and [env/](env/) |

The build environment provides:
- **Python 3.11** (conda-forge)
- **GCC / G++ 15.2** (conda-forge, UCRT) — packages `gcc_win-64`, `gxx_win-64`
- **libpython** — provides the Python import library
- **Cython** — for compiling `.py`/`.pyx` sources

Full environment definitions: [env/environment.yml](env/environment.yml)
(portable recipe) and [env/py_pyd_modern_lock.yml](env/py_pyd_modern_lock.yml)
(exact lockfile).

> **One-time setup step:** After creating the environment, a compiler shim is
> required. See [REBUILD.md](REBUILD.md).

---

## Runtime Requirements (for using a compiled `.pyd`)

To **run/import** a `.pyd` produced by this template:

| Requirement | Details |
|-------------|---------|
| Python | **CPython 3.11.x** (see version table above) |
| OS | Windows x64 |

### Additional for C++ modules
C++ `.pyd` files depend on GNU runtime DLLs (`libstdc++-6.dll`,
`libgcc_s_seh-1.dll`). These are found automatically **inside** the build
environment. To run a C++ `.pyd` **outside** that environment, bundle the DLLs
alongside it — see `bundle_dlls.ps1` and the README's distribution section.

> Pure Cython/C modules typically require no extra DLLs beyond `python311.dll`,
> which is present wherever CPython 3.11 is installed.

---

## Platform Note

All artifacts are **Windows x64** specific. A `.pyd` built here will not run on
Linux or macOS.