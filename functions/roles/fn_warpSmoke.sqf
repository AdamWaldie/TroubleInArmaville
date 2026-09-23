//////////////////////////////////////////////////////////////////
// Waldo_fnc_warpSmoke
// CLIENT: adds a managed Fired handler so throwing a red smoke ("Teleport
// Grenade") warps the player to where it lands, with portal SFX. Marks the
// landing spot with ACE's HiRed chemlight when ACE is loaded (brighter,
// nicer model), falling back to the plain vanilla Chemlight_red otherwise -
// ACE is preferred when present, but never required.
//
// Also hooks ACE3's Advanced Throwing CBA event (ace_throwableThrown):
// Advanced Throwing manually positions/launches the throwable itself
// (setPosASL/setVelocity/addTorque, confirmed in ACE3's own
// addons/advanced_throwing/functions/fnc_throw.sqf) instead of going through
// the engine's normal weapon-fire pipeline, so it never triggers the vanilla
// "Fired" handler below at all (a known ACE3 issue - Advanced Throwing
// bypasses FiredMan the same way). Without this second hook the teleport
// only ever worked for a player who had Advanced Throwing off. The thrown
// object's type is the ammo class (fnc_prime.sqf), which for a plain
// SmokeShellRed magazine is the same name already checked below for the
// vanilla case.
//
// The warp effect itself is duplicated in both handlers rather than shared
// via an outer private - SQF is dynamically scoped, not lexically: a code
// block passed to addEventHandler/CBA_fnc_addEventHandler only sees private
// variables from whatever calls it when the event actually fires (the
// engine, later), never from the scope that DEFINED it. An outer
// `private _warpEffect` referenced from inside either handler would be nil
// by the time either one actually runs.
//////////////////////////////////////////////////////////////////

private _old = player getVariable ["Waldo_warpEH", -1];
if (_old >= 0) then { player removeEventHandler ["Fired", _old]; };

private _eh = player addEventHandler ["Fired", {
	params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
	if (_ammo == "SmokeShellRed") then {
		[_unit, _projectile] spawn {
			params ["_unit", "_projectile"];
			private _flareClass = if (isClass (configFile >> "CfgVehicles" >> "ACE_G_Chemlight_HiRed")) then { "ACE_G_Chemlight_HiRed" } else { "Chemlight_red" };
			private _flare = _flareClass createVehicle getPos _projectile;
			triggerAmmo _projectile;
			_flare attachTo [_projectile];
			triggerAmmo _flare;
			sleep 2;
			// A landing spot outside the real arena boundary (mapPos/mapRadius,
			// the same source of truth Waldo_fnc_confineToArena polices) doesn't
			// get warped to at all - a strong throw could otherwise chuck this
			// clean over the fence and step the thrower straight out of the
			// play area.
			private _land = getPos _projectile;
			private _center = missionNamespace getVariable ["mapPos", _land];
			private _radius = missionNamespace getVariable ["mapRadius", 1e6];
			if ((_land distance2D _center) <= _radius) then {
				playSound3D [getMissionPath "audio\portalIn.ogg", _unit];
				sleep 1;   // let the ~1s "in" cue finish before the "out" cue - they were firing back to back with zero gap, overlapping almost entirely
				_unit setPos _land;
				playSound3D [getMissionPath "audio\portalOut.ogg", _unit];
			} else {
				["STR_TIA_Warp_Title", "STR_TIA_Warp_Outside", "WARNING", 4, "BOTTOM_LEFT", "WARPSMOKE", "STR_TIA_Role_Traitor"] call Waldo_fnc_ShowUiNotification;
			};
			sleep 0.5;
			deleteVehicle _flare;
		};
	};
}];
player setVariable ["Waldo_warpEH", _eh];

// CBA (and therefore ACE, which requires it) is no longer treated as a hard
// requirement - this hook is purely additive on top of the vanilla one
// above, so with neither loaded there's simply nothing to add here.
if (!isNil "CBA_fnc_addEventHandler") then {
	private _oldAce = player getVariable ["Waldo_warpAceEH", -1];
	if (_oldAce >= 0) then { [_oldAce] call CBA_fnc_removeEventHandler; };
	private _aceEh = ["ace_throwableThrown", {
		params ["_unit", "_activeThrowable"];
		if (typeOf _activeThrowable == "SmokeShellRed") then {
			[_unit, _activeThrowable] spawn {
				params ["_unit", "_projectile"];
				private _flareClass = if (isClass (configFile >> "CfgVehicles" >> "ACE_G_Chemlight_HiRed")) then { "ACE_G_Chemlight_HiRed" } else { "Chemlight_red" };
				private _flare = _flareClass createVehicle getPos _projectile;
				triggerAmmo _projectile;
				_flare attachTo [_projectile];
				triggerAmmo _flare;
				sleep 2;
				// See the vanilla Fired handler above - same arena-boundary guard.
				private _land = getPos _projectile;
				private _center = missionNamespace getVariable ["mapPos", _land];
				private _radius = missionNamespace getVariable ["mapRadius", 1e6];
				if ((_land distance2D _center) <= _radius) then {
					playSound3D [getMissionPath "audio\portalIn.ogg", _unit];
					sleep 1;   // let the ~1s "in" cue finish before the "out" cue - they were firing back to back with zero gap, overlapping almost entirely
					_unit setPos _land;
					playSound3D [getMissionPath "audio\portalOut.ogg", _unit];
				} else {
					["STR_TIA_Warp_Title", "STR_TIA_Warp_Outside", "WARNING", 4, "BOTTOM_LEFT", "WARPSMOKE", "STR_TIA_Role_Traitor"] call Waldo_fnc_ShowUiNotification;
				};
				sleep 0.5;
				deleteVehicle _flare;
			};
		};
	}] call CBA_fnc_addEventHandler;
	player setVariable ["Waldo_warpAceEH", _aceEh];
};
