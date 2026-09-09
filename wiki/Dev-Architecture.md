# Architecture

## Function library layout

Everything lives as `Waldo_fnc_*` functions compiled by the `CfgFunctions` block in `description.ext`. A file at `functions/<group>/fn_<name>.sqf` becomes `Waldo_fnc_<name>`. The engine entry points are thin on purpose:

- `init.sqf` (server): compiles `config.sqf`, calls `Waldo_fnc_loadParams` synchronously, then spawns `Waldo_fnc_initServer` to orchestrate the round.
- `initPlayerLocal.sqf`: spawns `Waldo_fnc_initClient` for per-client setup.
- `onPlayerRespawn.sqf` (mission root): the engine's per-respawn hook, used only to re-home a revived player's state onto their new unit (see below).

| Group | Runs on | Covers |
|---|---|---|
| `config` | server | Lobby parameter reads, the dynamic arsenal |
| `core` | server / client | Round (re)init, server/client orchestration, spawn loadout |
| `arena` | server (confine: client) | Arena selection, wall construction, loot scatter, keeping players inside |
| `env` | server | Weather and time of day |
| `round` | server | Role assignment, the round loop, win checks, kill handling, revive relinking, MVP |
| `systems` | server | Airdrops, karma, C4, Identify Body, DNA contamination, the Dead Ringer decoy |
| `ui` | client | Shop dialogs, HUD, scoreboard, title sequence, MVP celebration |
| `roles` | client | Everything a player presses Y or a hotkey for |
| `debug` | every machine / client / server | The dev/test registry, its renderer, and its server dispatch |

## Round lifecycle and state

Each round ends with `BIS_fnc_endMissionServer`, which restarts the mission. The engine wipes `missionNamespace` on every restart, so `Waldo_fnc_resetState` rebuilds round state at the start of `Waldo_fnc_initServer`. Clients wait for `Waldo_configReady` before reading config from the server.

Karma is the one exception. The mission stores it in `profileNamespace`, keyed by player UID, so it survives a restart. `Waldo_fnc_applyKarma` decays it toward neutral and removes UIDs that no longer appear.

The mission logs `[Waldo][server]` and `[Waldo][client]` phase markers to the `.rpt`. Testing Mode also echoes them to chat, which identifies the phase where a replay stalled.

## Why respawn needs special handling

Arma has no "undo death." After a unit reaches `damage` 1 and fires `Killed`, the engine cannot restore it in place. Respawn creates a new object, so the mission moves per-life state onto that object:

- **Role, credits, kill count, purchase log** - `onPlayerRespawn.sqf` copies these values from the old unit to the new one.
- **`TraitorList` / `DetectiveList` / `JesterList` membership** - the server-side `Waldo_fnc_reviveRelink` replaces the dead reference. These authoritative lists drive win checks and credit awards.
- **Per-life event handlers** - `addMPEventHandler` and `addEventHandler` attach to one object. `Waldo_fnc_initClient` reinstalls the `MPKilled` handler and Dead Ringer's `HandleDamage` guard on the new unit.
- **Loadout** - a freshly respawned unit is otherwise bare. `Waldo_fnc_applySpawnLoadout` (shared with the initial spawn) gives it a random uniform/vest/headgear from the discovered pools.

Code that reads the `player` command at call time already tracks a respawn. It does not need this relinking. For example, the `ace_unconscious` watchdog in `initClient` evaluates `player` on every loop tick and follows the currently controlled unit.

## Terrain independence

The mission handles terrain independence at runtime and during release packaging.

**At runtime**, `Waldo_fnc_selectArena` scores live candidate positions. `Waldo_fnc_selectHoldingPos` picks a fast, `surfaceIsWater`-checked position for the pre-arena wait. `Waldo_fnc_initClient` disables damage before either wait. That protects a player during relocation, but it cannot hide a bad spawn for the first moment.

`Waldo_fnc_selectArena` scores lootable buildings, not end-to-end walkability. A property fence or walled compound can split a good arena. After `Waldo_fnc_buildArena`, `Waldo_fnc_clearArenaPaths` sweeps parallel chords across the full width at three angles. Ground-hugging sub-segments keep hills from hiding a fence.

Dense towns contain ordinary clutter. The path check ignores buildings and counts only `CfgVehicles` objects based on `Wall`. A blocked run must span at least 55% of the sweep width before it counts as a divider. That threshold filters normal yard fencing.

One qualifying run causes `Waldo_fnc_initServer` to reroll the arena. On the final retry, the mission removes each blocking object and its immediate neighbours. It does not delete the whole obstruction.

**During release packaging**, the workflow accounts for the 128 player starts in `mission.sqm`. Eden stores them as raw Altis world coordinates. Smaller terrains can place those coordinates outside the map. `.github/workflows/release.yml` resolves each terrain in this order:

1. Use `terrains/<Terrain>/mission.sqm` when present. A contributor built and verified this file in Eden on that terrain.
2. Otherwise, read an anchor point from `.github/terrains.json`. `.github/scripts/patch_mission_positions.py` recentres the 128-position grid on that spacious, dry landmark. It preserves the layout and raises the starting height so players drop safely onto the terrain.
3. For Altis, ship the root `mission.sqm` as authored.

`terrains/README.md` explains how to replace an anchor-based layout with an Eden-verified file. The workflow packages one result per terrain as `TroubleInArmaville_<version>.<Terrain>`. Arma reads the terrain from the mission folder name, not from `mission.sqm`.
