# PYD Build Workflow — What to Change and What Not To

Quick reference for using the pyd_building template across projects.
Focus: which names/files are safe to change, and which will break things.

---

## THE ONE-LINE MENTAL MODEL

> Change your SOURCE FILES. Leave the BUILD MACHINERY alone.
> The .pyd's name and behavior come from the source file's NAME and CONTENTS.

---

## ✅ SAFE TO CHANGE (per project / per module)

### 1. The source filename → controls the module name
`src\anything.py`  →  builds  →  `anything.cp311-win_amd64.pyd`  →  `import anything`

- Name the source file whatever you want the MODULE to be called.
- Example: rename `src\cython_module.py` → `src\coord_xform.py`,
  rebuild → get `coord_xform...pyd`, use `import coord_xform`.
- RULE: must be a valid Python identifier:
    OK:  geo_utils.py, calc2.py, transform_grid.py
    NO:  geo-utils.py (hyphen), 2d.py (leading digit), my file.py (space)

### 2. The source file CONTENTS
Write whatever Python you want. Functions, classes, logic — all compiles.
The definitions live inside the .pyd after building.

### 3. Number of modules
Drop multiple .py files in src/ (with the glob setup.py) — each becomes its
own .pyd. One file = one module.

---

## 🔴 DO NOT CHANGE (breaks import or build)

### 1. The compiled .pyd filename — NEVER rename it manually
    coord_xform.cp311-win_amd64.pyd
         |            |
      module       ABI tag (cp311 = Python 3.11, win_amd64 = 64-bit Windows)

- The ABI tag is REQUIRED — Python's loader uses it to verify compatibility.
- The module-name portion must match the PyInit_<name> baked into the binary.
- Renaming the file → ImportError (PyInit mismatch) or the loader refuses it.
- TO CHANGE THE NAME: rename the SOURCE .py and REBUILD. Never touch the .pyd.

### 2. The Python version match
- A 3.11-built .pyd imports ONLY into Python 3.11.
- Build env and run env must be the SAME Python minor version.
- Move to 3.12? Rebuild everything under a 3.12 env.

### 3. The build machinery (leave alone unless intentionally reconfiguring)
- setup.py           — the build recipe (glob logic, Cython directives)
- build.ps1          — build + move .pyd to compiled/
- .vscode/*.json     — IntelliSense + task config
- The compiler shims — gcc.exe / g++.exe in the env's Library\bin

---

## 📁 FOLDER ROLES (don't repurpose these)

    src/         SOURCES you edit (.py to compile). Name = module name.
    compiled/    DELIVERABLE .pyd files ONLY. This is what you hand off.
    build/       TRANSIENT junk (generated .c, .o, temp). Gitignored.
                 NEVER ship anything from here (esp. the generated .c).

---

## 🔁 THE STANDARD WORKFLOW (every time)

1. Put/rename your source in src/ with the desired module name.
       e.g., src\coord_xform.py
2. Build:
       conda activate py_pyd_modern
       cd <project>\pyd_builder
       .\build.ps1
   (or use the Conda PyD Build terminal, which auto-activates the env)
3. Collect the .pyd from compiled/.
4. Use it:  import coord_xform
5. Deliver ONLY the .pyd (never the src .py or the build/ .c, if obfuscating).

---

## ⚠️ COMMON GOTCHAS

- "Undefined" squiggles when calling an imported .pyd's functions:
  Pylance can't read compiled binaries. It RUNS fine. Optionally add a
  .pyi stub file for editor autocomplete.

- ModuleNotFoundError after building:
  A running Python process caches the old module. Restart Python / open a
  fresh terminal after rebuilding.

- Import works but you edited the source and see no change:
  Same caching issue, OR you imported the old .pyd. Rebuild + fresh process.

- Wrong compiler / weird link errors:
  Confirm you're in py_pyd_modern and `gcc --version` says conda-forge 15.2
  (NOT MSYS2's 16.1). If wrong, the env isn't active or the shim is missing.

- C++ specifics:
  * Module init MUST be:  extern "C" PyMODINIT_FUNC PyInit_<name>(void)
  * Extension() needs:    language="c++"
  * C++ .pyd needs libstdc++-6.dll etc. at runtime — auto inside the env,
    must be bundled if run outside it (see DLL bundling notes).

---

## 🚫 NEVER

- Never rename a compiled .pyd file to shorten it. Rename the source, rebuild.
- Never ship the generated Cython .c (from build/) — defeats obfuscation.
- Never build in the MSYS2 shell or against system Python — ABI mismatch.
- Never assume a .pyd works across Python versions — it's locked to one.