//////////////////////////////////////////////////////////////////
// Waldo_fnc_spawnAirdrop
// SERVER: drops a parachuted supply crate at a random spot in the arena.
// Returns immediately; the smoke/detach timeline runs in its own thread so
// it never blocks the round loop.
//////////////////////////////////////////////////////////////////

if (!isServer) exitWith {};
if (isNil "airdropLoadouts") exitWith {
	diag_log "[Waldo][server] spawnAirdrop: airdropLoadouts not defined";
};

setWind [0, 0, true];

private _loadouts = airdropLoadouts;
private _limit = missionNamespace getVariable ["airdropLoadoutsAmount", 1];
private _center = missionNamespace getVariable ["mapPos", [0,0,0]];
private _distance = (missionNamespace getVariable ["mapRadius", 50]) * 0.9;

private _dropPos = [
	(_center select 0) - (_distance / 2) + random _distance,
	(_center select 1) - (_distance / 2) + random _distance,
	250
];

// Roll the crate type. A rare GOLDEN drop is announced to everyone and turns
// into a contested objective; it comes in three flavours so it's not always
// just "more guns". Otherwise it's a normal weapons crate built from the
// discovered airdrop loadouts.
private _golden = (random 1) < (missionNamespace getVariable ["Waldo_goldenAirdropChance", 0.15]);
private _variant = ["weapons", "medical", "ammo"] select (floor (random 3));

private _parachute = createVehicle ["B_Parachute_02_F", _dropPos, [], 0, "FLY"];
private _crate = createVehicle [(["B_supplyCrate_F", "Box_IND_Wps_F"] select _golden), position _parachute, [], 0, "NONE"];
clearItemCargoGlobal _crate;
clearMagazineCargoGlobal _crate;
clearWeaponCargoGlobal _crate;
clearBackpackCargoGlobal _crate;

private _smokeClass = "SmokeShellOrange";
private _label = "";

if (_golden) then {
	switch (_variant) do {
		case "medical": {
			_crate addItemCargoGlobal ["Medikit", 2];
			_crate addItemCargoGlobal ["FirstAidKit", 6];
			_crate addItemCargoGlobal [(missionNamespace getVariable ["ShopArmorVest", "V_PlateCarrier2_rgr"]), 1];
			_smokeClass = "SmokeShellBlue";
			_label = "STR_TIA_Airdrop_GoldenMedical";
		};
		case "ammo": {
			_crate addMagazineCargoGlobal [(missionNamespace getVariable ["ShopPistolMag", "16Rnd_9x21_Mag"]), 6];
			_crate addMagazineCargoGlobal [(missionNamespace getVariable ["TraitorRifleMag", "7Rnd_408_Mag"]), 6];
			_crate addMagazineCargoGlobal [(missionNamespace getVariable ["ShopFrag", "HandGrenade"]), 4];
			_smokeClass = "SmokeShellGreen";
			_label = "STR_TIA_Airdrop_GoldenAmmo";
		};
		default {   // "weapons": the top sniper + a launcher + NVG + heavy armour (all discovered)
			_crate addWeaponCargoGlobal [(missionNamespace getVariable ["TraitorRifle", "srifle_LRR_F"]), 1];
			_crate addMagazineCargoGlobal [(missionNamespace getVariable ["TraitorRifleMag", "7Rnd_408_Mag"]), 4];
			_crate addWeaponCargoGlobal [(missionNamespace getVariable ["TraitorLauncher", "launch_NLAW_F"]), 1];
			_crate addMagazineCargoGlobal [(missionNamespace getVariable ["TraitorLauncherMag", "NLAW_F"]), 1];
			_crate addItemCargoGlobal [(missionNamespace getVariable ["ShopNVG", "NVGoggles"]), 1];
			_crate addItemCargoGlobal [(missionNamespace getVariable ["ShopArmorVest", "V_PlateCarrier2_rgr"]), 1];
			_smokeClass = "SmokeShellYellow";
			_label = "STR_TIA_Airdrop_GoldenWeapons";
		};
	};
	[
		// _label is a whole-sentence key (not a word slotted into one) so
		// translators can order it naturally; localised on each client.
		"STR_TIA_Airdrop_GoldenTitle", _label,
		"WARNING", 6, "TOP", "AIRDROP", "STR_TIA_Airdrop_Source"
	] remoteExec ["Waldo_fnc_ShowUiNotification", 0];
} else {
	for "_i" from 1 to _limit do {
		private _loadout = selectRandom _loadouts;
		if ((_loadout select 0) == "weapon") then {
			_crate addWeaponCargoGlobal [(_loadout select 1), 1];
			for "_j" from 0 to (count (_loadout select 2) - 1) step 2 do {
				_crate addMagazineCargoGlobal [(_loadout select 2 select _j), (_loadout select 2 select (_j + 1))];
			};
			{ _crate addItemCargoGlobal [_x, 1]; } forEach (_loadout select 3);
		};
	};
	[
		"STR_TIA_Airdrop_InboundTitle", "STR_TIA_Airdrop_InboundBody",
		"INFO", 5, "TOP", "AIRDROP", "STR_TIA_Airdrop_Source"
	] remoteExec ["Waldo_fnc_ShowUiNotification", 0];
};

_crate attachTo [_parachute, [0, 0, 1]];
_crate allowDamage false;

[_parachute, _crate, _smokeClass] spawn {
	params ["_parachute", "_crate", "_smokeClass"];
	sleep 10;
	private _smoke = _smokeClass createVehicle [0, 0, 0];
	_smoke attachTo [_crate, [0, 0, 0]];
	sleep 50;
	detach _crate;
	deleteVehicle _parachute;
};
