//////////////////////////////////////////////////////////////////
// Waldo_fnc_healthStation
// Detective deployable. Called on the buyer's client; forwards to the
// server which spawns a supply crate with a "Health Station" addAction -
// using it fully heals whoever used it. Use-based, not proximity/automatic,
// so it behaves identically (from any other player's perspective) to its
// Traitor decoy counterpart (Waldo_fnc_fakeHealthStation) right up until
// used. Permanent once placed - it does not expire/despawn on its own.
//
// Client call: no args -> forwards player's position to the server.
// Server call: [_pos] -> spawns and arms the station.
//////////////////////////////////////////////////////////////////

if (!isServer) exitWith {
	[getPosATL player] remoteExec ["Waldo_fnc_healthStation", 2];
};

// Default falls back to the CALLER's own current position, not a fixed
// [0,0,0] - on a listen-server host, isServer is true on the very machine
// that bought this, so the exitWith above never fires and this runs
// straight through with the original empty _this from the shop's `[] call
// Waldo_fnc_healthStation;` (no remoteExec ever happened to populate _pos).
params [["_pos", getPosATL player]];

private _station = createVehicle ["Box_NATO_Support_F", _pos, [], 0, "CAN_COLLIDE"];
_station allowDamage false;

// Box_NATO_Support_F spawns with vanilla's own default NATO cargo (rifles,
// mags, etc.) already inside - clearing it so this is actually a health
// station, not a free loot crate.
clearWeaponCargoGlobal _station;
clearMagazineCargoGlobal _station;
clearItemCargoGlobal _station;
clearBackpackCargoGlobal _station;

// Label/colour/size/priority/showWindow/hideOnUse/shortcut/radius all match
// Waldo_fnc_fakeHealthStation's own addAction exactly - the whole point is
// that the two are completely impossible to tell apart before being used.
// The addAction's own code runs locally on whoever actually performs it
// (the caller), so no remoteExec is needed to heal them - they're already
// local to whichever machine is running this.
[_station, [
	["<t color='#3FE07A' size='1.4'>%1</t>", "STR_TIA_Health_Title"],
	{
		params ["_target", "_caller"];
		if (isNil "ace_medical_treatment_fnc_fullHeal") then {
			_caller setDamage 0;
		} else {
			[objNull, _caller] call ace_medical_treatment_fnc_fullHeal;
		};
		["STR_TIA_Health_Title", "STR_TIA_Health_Treated", "SUCCESS", 4, "BOTTOM_LEFT", "HEALTHSTATION", "STR_TIA_Health_Title"] call Waldo_fnc_ShowUiNotification;
	},
	nil, 1.5, false, false, "",
	"alive _this",
	4
]] remoteExec ["Waldo_fnc_addActionL", 0, _station];   // title localised per client

// Reported "no interactions" with no bug found on static review of the
// addAction call itself (it matches Defuse Charge's own working
// remoteExec ["addAction", ...] pattern exactly, and this mission's
// description.ext has no CfgRemoteExec block at all, so remoteExec is
// unrestricted by default - that's not blocking it either). Logging the
// object's actual identity/position so the next .rpt confirms whether the
// crate is even being created where expected, rather than guessing again.
diag_log format ["[Waldo][server] healthStation deployed at %1 (netId=%2, typeOf=%3, isNull=%4)", _pos, netId _station, typeOf _station, isNull _station];
