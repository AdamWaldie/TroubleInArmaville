# Equipment System

This mission has no `modpacks/*.sqf` preset files. `Waldo_fnc_buildArsenal` scans the loaded mods once on the server during `loadParams`, then publishes weapons, ammo, gear, loot, airdrops, and clothing.

## How classification works

A single pass over `CfgWeapons` sorts everything it finds:

- **Weapons** use config inheritance (`isKindOf`) and rifle damage and magazine data to choose ground loot, airdrops, the Traitor Long Rifle, or LMG drops.
- **Clothing** uses `ItemInfo` types for uniforms, vests, and headgear. A separate `CfgVehicles` scan finds backpacks through `Bag_Base`.
- **Optics:** the scan keeps thermal optics out of ground loot.
- **Gear:** the scan finds NVGs (`ItemInfo` type 617), plain binoculars, body armour, and explosive throwables. Rangefinders and designators carry battery magazines, so the scan classifies them as weapons. For armour, it chooses the strongest vest that still has cargo space. For explosives, it takes the first throwable found among the `Throw` weapon's muzzles.

Every bucket has a vanilla fallback. A total-conversion mod that adds no pistols still leaves every shop slot and loot table usable. The lobby's "Loot Power" setting controls whether standard rifles join the low-powered ground-loot pool.

## What gets published

`buildArsenal` writes its results straight to `missionNamespace` as globals the rest of the mission reads directly: `lootPriWeapons` / `lootSecWeapons` / `lootAttachments` (ground loot), `airdropLoadouts`, `TraitorRifle`/`*Mag`/`*Optics`, `TraitorLauncher`/`*Mag`, `ShopPistol`/`*Mag`/`*Suppressor`, `ShopArmorVest`, `ShopFrag`, `ShopNVG`, `ShopBinocular`, `uniformsConfig` / `headgearsConfig` / `vestsConfig` / `backpacksConfig`, and `detectiveConfig`.

`vestsConfig` and `backpacksConfig` are deliberately not just spawn-loadout pools: `Waldo_fnc_populateLoot` also draws from them to place better armour and backpacks as ground loot, on top of the one starting vest everyone spawns with. Neither is ever handed out for free beyond that - both are things a player finds, the same way a better weapon is.

## Changing "modpacks"

There is no modpack switch. Change the loaded mods and the next mission start rescans them. Optional power thresholds in `config.sqf` (`Waldo_arsenalLowMaxHit`, `Waldo_arsenalSniperMinHit`, `Waldo_arsenalLmgMinRounds`) tune classifications for unusual damage values.
