//////////////////////////////////////////////////////////////////
// Waldo_fnc_fakeHealthStation
// Traitor deployable. Completely indistinguishable from the real Detective
// Health Station (Waldo_fnc_healthStation) - same crate, same cleared
// cargo, same "Health Station" addAction (identical label, colour, size,
// priority, and radius) - right up until someone uses it: instead of
// healing them, it detonates (Waldo_fnc_fakeHealthStationBoom). No healing
// of any kind; this is a decoy, not a real aid station. Anyone who uses it
// sets it off, INCLUDING the planter themselves - it's a trap for anyone
// careless enough to click it, not just a tell-free ambush for other
// players. _owner is still tracked (Waldo_fakeOwner) purely for kill
// attribution (karma/DNA/round-kill credit via setShotParents in
// Waldo_fnc_fakeHealthStationBoom), not to exempt them from it.
// Permanent once placed until someone sets it off - it does not expire/
// despawn on its own, same as the real station.
//
// Client call: no args -> forwards the buyer's position (and identity, for
// kill attribution) to the server.
// Server call: [_pos, _owner] -> spawns and arms the trap.
//////////////////////////////////////////////////////////////////

if (!isServer) exitWith {
	[getPosATL player, player] remoteExec ["Waldo_fnc_fakeHealthStation", 2];
};

// Same listen-server-host position fix as Waldo_fnc_healthStation: isServer
// is true on the very machine that bought this, so the exitWith above never
// fires there, and this runs straight through with the shop's original
// empty _this - default to the caller's own position/unit instead of a
// fixed [0,0,0]/objNull.
params [["_pos", getPosATL player], ["_owner", player]];

private _station = createVehicle ["Box_NATO_Support_F", _pos, [], 0, "CAN_COLLIDE"];
_station allowDamage false;
_station setVariable ["Waldo_fakeOwner", _owner, true];

// Box_NATO_Support_F spawns with vanilla's own default NATO cargo already
// inside - cleared for the same reason the real station clears it: this
// needs to look identical, not like a free loot crate that happens to have
// a health station's addAction on it.
clearWeaponCargoGlobal _station;
clearMagazineCargoGlobal _station;
clearItemCargoGlobal _station;
clearBackpackCargoGlobal _station;

// Every visible parameter here matches Waldo_fnc_healthStation's own
// addAction exactly (label/colour/size/priority/radius) - the whole point
// is that the two are indistinguishable before use. The CONDITION now
// matches too, for a real reason, not just cosmetics: Waldo_fnc_healthStation's
// condition only ever reads _this (the potential caller, always a
// long-lived player unit); this one used to also read _target getVariable
// [...] (the crate itself - freshly createVehicle'd moments earlier in
// this same script). Confirmed live: the real station's action showed up
// fine, this one never did. A condition that throws is treated as false -
// no error dialog, the action just silently never appears - and a client
// whose local copy of a just-created object isn't fully resolved yet can
// throw evaluating _target there, which _this never risks.
//
// No owner exemption - anyone who clicks it (including whoever placed it)
// sets it off. _target is only read here for the boom's kill-attribution
// hand-off, not to gate whether it fires.
[_station, [
	["<t color='#3FE07A' size='1.4'>%1</t>", "STR_TIA_Health_Title"],
	{
		params ["_target"];
		[_target] remoteExec ["Waldo_fnc_fakeHealthStationBoom", 2];
	},
	nil, 1.5, false, false, "",
	"alive _this",
	4
]] remoteExec ["Waldo_fnc_addActionL", 0, _station];   // title localised per client

// Same diagnostic as Waldo_fnc_healthStation - "no interactions" reported
// with no bug found on static review; logging so the next .rpt confirms
// whether the crate is actually created/registered where expected.
diag_log format ["[Waldo][server] fakeHealthStation deployed at %1 for owner %2 (netId=%3, typeOf=%4, isNull=%5)", _pos, _owner, netId _station, typeOf _station, isNull _station];
