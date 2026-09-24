# Localisation and gameplay audit harness

This is a disposable Arma 3 audit for the player-facing localisation introduced by PR #53. It stages the real mission, loads its real `description.ext`, dialogs and functions, captures every declared surface in each supported language, exercises the round state machine, and rejects script/config/RPT errors. It never patches the source mission or treats the role crest initials (`I`, `T`, `D`, `J`) as translated words.

## Safe setup check (does not open Arma)

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  .\tools\qa\localisation_gameplay_audit\launch_audit.ps1
```

Without `-Run`, the launcher only assembles a disposable mission under `.qa/Missions` and exits. This is the command to use while developing the harness.

The launcher discovers `python`, `python3`, or the Windows `py` launcher. If Python 3 is installed outside `PATH`, pass its full path with `-PythonExecutable`.

## Run the full audit later

Close any existing Arma client/server first, then run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  .\tools\qa\localisation_gameplay_audit\launch_audit.ps1 -Run
```

The full run uses a fresh profile for every language, a 3840x2160 window, `-noBattlEye`, `-filePatching`, and `-showScriptErrors`. It launches the staged mission directly rather than Eden. Each capture is made externally from the DPI-aware foreground window because Arma's `screenshot` command omits some GUI layers and `PrintWindow` can return partial DirectX frames.

Use `-Languages English,German` for a focused run. The default is all 13 stringtable languages. Results are written beneath `.qa/localisation-gameplay-audit/run-<timestamp>/`; every language gets its screenshots, fresh profile, and RPT.

## What is gated

- Every player-facing word key must contain a non-empty value for all 13 languages, preserve its format placeholders, and resolve in the active game language at runtime. The manifest explicitly allowlists six canonical/format-only fallbacks (the mission/WMP names and punctuation-only templates); role crest initials are not stringtable entries.
- All surfaces in `audit_manifest.json` must emit a capture marker and produce a non-empty PNG.
- Mission initialisation, role assignment/rosters, round timers, all four win outcomes, reset, and a subsequent round start must pass through the shipped functions.
- Both UI and round suites must reach their completion markers.
- The RPT must not contain the configured script, missing-file, config-entry, or explicit QA-failure patterns.

`validate_results.py` is run automatically at the end. Screenshots remain the visual evidence for translation quality, clipping, overflow, and font rendering; the automated gate proves coverage and runtime resolution, not linguistic taste.
