# Dev and Test Mode

Turn on **Enable Testing Mode** in the lobby to test the game alone. The setting controls every tool on this page. When it is off, the menu key does nothing, the server rejects test actions, and the player-count override has no effect. Normal rounds keep their standard behaviour.

## Opening it

Press **[** in-round to open the menu, or **]** to instantly cycle your own role (Innocent -> Traitor -> Detective -> Jester -> Innocent) without opening anything. Both only work under Testing Mode.

## How the menu works

The menu reads from a registry. Code that runs at preInit on every machine can register a tool with one call:

```sqf
["Category", "Label", "Tooltip", "local"|"server", { /* _this = the acting unit */ }]
    call Waldo_debugRegister;
```

`"local"` code runs on the clicking client. `"server"` code sends only the registry index to the server, where the clicking unit becomes `_this`. The server therefore owns state such as `TraitorList` and the round timer. `Waldo_fnc_debugMenu` renders the registry and dispatches by index. A new tool needs no UI or `description.ext` change.

## What's built in

- **Roles** - become any role directly, or re-run role assignment for the whole lobby. A 3D overlay can reveal every unit's true role for debugging.
- **Loadout & Shops** - grant credits, open either shop to inspect or buy-test it, or run every catalog item's purchase effect at once.
- **Abilities** - fire Traitor/Detective role powers directly (radars, warp smoke, flower power, health station, suicide bomb, holster) without buying them first.
- **Test Dummies** - captive AI whose deaths route through the real kill handler (`Waldo_fnc_onKilled`). Use them to verify kill credit, the Jester clean-kill check, and karma. They do not count toward win conditions.
- **Simulated Players** - the category that counts toward win conditions. Traitor sims join `TraitorList`, while non-Traitor sims mark that a non-Traitor side exists. Build a roster, kill one side, and verify the matching ending. "Clear Sim Players" removes the scenario and repairs the authoritative lists.
- **Round Flow** - skip warmup, freeze the clock, adjust the time, or force any ending. A freeze pauses the timer, airdrops, and win checks for mid-round inspection.
- **Arena & World** - rebuild or reselect the arena, repopulate loot, and set weather or time of day on demand.
- **Karma & Sim** - set your stored karma or override the effective player count. The override drives arena radius, Traitor count, and starting credits without needing a full lobby.
- **Player** - godmode, heal, refill ammo, infinite stamina, teleport to the arena center, kill yourself on command.
- **Diagnostics** - dump round state to chat/`.rpt`, or to the clipboard.

## Mod independence

The framework contains no mod-specific classnames. Gear actions run the shop's purchase effects, which read the dynamic arsenal and its vanilla fallbacks. See [Equipment System](Dev-Equipment-System).

One helper creates dummies, simulated players, and the hostile combat dummy. It validates the configured unit class and falls back to a base-game class when necessary. It also dresses non-enemy units from the discovered clothing pools.
