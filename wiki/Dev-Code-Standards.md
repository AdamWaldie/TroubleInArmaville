# Code Standards

These are the conventions used by the codebase. A pull request should follow them. SQF has no reliable linter for these rules, so reviewers check them before merge.

## File and function naming

A file at `functions/<group>/fn_<name>.sqf` becomes `Waldo_fnc_<name>`. Keep one function per file. Register every new file under its group in the `CfgFunctions` block in `description.ext`. Add a trailing comment with the function name and purpose:

```cpp
class revive {};            // Waldo_fnc_revive
class reviveRelink {};      // Waldo_fnc_reviveRelink (server: relinks role/lists onto a revived unit's NEW object)
```

Nothing scans the `functions/` folder automatically. Without a `CfgFunctions` entry, the engine does not compile the file into a callable function. The failure appears only when code tries to call it.

Two functions use `{ preInit = 1; };`: `initShops` defines the shop catalogs, and `debugInit` creates the dev/test registry. Other preInit and init-time code depends on them. Both run on every machine.

## Guard clauses

Start each function with the guard that defines where it may run:

```sqf
if (!isServer) exitWith {};
```
```sqf
if (!hasInterface) exitWith {};   // dedicated server / headless: nothing to do
```

Functions rarely contain separate server and client paths. When one does, add a comment that explains the split.

## Params and privacy

`params` immediately follows any guard clause, using the `["_name", default]` form for anything optional:

```sqf
params ["_newUnit", "_oldUnit", "_respawn", "_respawnDelay"];
params [["_dir", 0]];
```

Declare every local variable as `private`. The unprefixed unit globals `role`, `points`, and `tested` predate the `Waldo_` convention. Many systems treat them as public API, so do not rename them.

Prefix every new global with `Waldo_`. This prevents collisions and separates mission state from engine or mod state.

## Broadcasting state

Choose the third `setVariable` argument from the ownership requirement:

- Use `true` when another machine needs the value. Examples include roles, points, list membership, and forensic tags on bodies.
- Omit it for per-client state that no other machine reads. Examples include activation slots, UI handler IDs, and debug toggles.

If code on another machine will call `getVariable` on the value, broadcast it.

## remoteExec targeting

The target argument routes execution. This project uses four forms:

- An object routes to the machine that owns it. Use this for `setPlayerRespawnTime` and per-player UI refreshes.
- `0` targets every connected machine. These calls do not use JIP persistence, so later joiners receive no replay.
- `2` targets the server. Use it for authoritative list changes and networked object creation.
- `-2` targets every client except the caller.

Choose the target that owns the operation.

## Event handlers don't stack themselves

Code that installs a `Draw3D`, `Fired`, `HandleDamage`, or CBA per-frame handler must prevent duplicates. Store the handler ID in a variable and remove the previous handler before installing another:

```sqf
private _old = player getVariable ["Waldo_radarEH", -1];
if (_old >= 0) then { removeMissionEventHandler ["Draw3D", _old]; };
```

Without this guard, each repeat adds another permanent handler. This has caused duplicate-handler bugs before.

Install `MPKilled` with `addMPEventHandler`. Its server-gated callback handles credit awards, Karma, and the Jester win check. Use `addEventHandler` or `CBA_fnc_addEventHandler` for client-local reactions.

## A unit's identity doesn't survive a respawn

If code captures a unit object for later use, read [Architecture](Dev-Architecture) first. Arma's respawn creates a new object. A reference to the old unit remains a corpse, and later calls against it fail silently.

## Equipment: no hardcoded classnames outside the arsenal

Keep mod-specific and DLC-specific classnames inside `Waldo_fnc_buildArsenal`. Use them there only as documented vanilla fallbacks.

Other systems read the published arsenal globals with `missionNamespace getVariable` and a safe default. Examples include `ShopArmorVest`, `TraitorRifle`, and `uniformsConfig`. When a feature needs new gear, extend `buildArsenal` and publish another global.

## Extending the dev/test menu

Never edit `WaldoDebug`'s `.hpp` or hand-add a case to `fn_debugMenu.sqf`. Register a tool instead, from code that runs at preInit on every machine:

```sqf
["Category", "Label", "Tooltip", "local"|"server", { /* _this = the acting unit */ }] call Waldo_debugRegister;
```

See [Dev and Test Mode](Dev-Test-Mode) for the `"local"` and `"server"` execution contract.

## Comments explain why, not what

The line `player setDamage 1;` needs no comment. Comment constraints, engine behaviour, previous bugs, and the reason an obvious alternative fails. When fixing a non-obvious defect, record the failure the new code prevents.

## Before you commit

SQF has no compiler. A mismatched brace or bracket may fail only when Arma reaches that path, sometimes mid-round. The engine records the abort in `.rpt`.

Before committing, check balanced `()`, `{}`, `[]`, and quotes in every changed file. A per-file character count catches most mistakes before an Arma test.
