//////////////////////////////////////////////////////////////////
// Waldo_fnc_spawnDecoyCorpse
// SERVER: spawns a fake corpse to sell a Traitor's Dead Ringer as a real death.
// Wears the REAL player's exact loadout (uniform/vest/backpack/headgear/
// weapons/items, via _loadout - see getUnitLoadout in Waldo_fnc_deadRingerTrigger)
// when one is given, so a body found at the drop site is visually identical to
// the player who was just standing there - falls back to a random pick from
// the spawn-loadout pool only if no loadout is passed (kept for any future
// caller that doesn't have a specific player to clone). Tagged role
// "Innocent" (so any Identify/DNA info gathered from it is misleading), and
// given the same "Identify Body" action as a real corpse. Deletes itself
// after a while so it doesn't linger forever once the scene has moved on.
//
// params: [_pos, _dir, _loadout]
//////////////////////////////////////////////////////////////////

if (!isServer) exitWith {};
params ["_pos", ["_dir", 0], ["_loadout", []]];

private _grp = createGroup [civilian, true];
_grp createUnit ["C_man_1", _pos, [], 0, "NONE"];
private _decoy = (units _grp) select 0;
if (isNull _decoy) exitWith { diag_log "[Waldo][server] spawnDecoyCorpse: spawn failed"; };

if (count _loadout > 0) then {
	_decoy setUnitLoadout _loadout;
} else {
	private _uni  = missionNamespace getVariable ["uniformsConfig", []];
	private _vest = missionNamespace getVariable ["vestsConfig", []];
	if (count _uni  > 0) then { _decoy forceAddUniform (selectRandom _uni); };
	if (count _vest > 0) then { _decoy addVest (selectRandom _vest); };
};

_decoy setDir _dir;
_decoy setVariable ["role", "Innocent", true];       // misdirection - never the truth
_decoy setVariable ["Waldo_deathTime", time, true];
_decoy setVariable ["Waldo_identified", false, true];
_decoy setDamage 1;   // instantly a corpse

// Same two-tier reveal as a real body (see Waldo_fnc_identifyBody) - a
// non-Detective finding it first can't consume the action before a
// Detective gets to it.
//
// Condition is "alive _this" ONLY, not gated on Waldo_roleRevealed like a
// real corpse's own Identify Body action can afford to be - Waldo_fnc_onKilled's
// _unit is a long-lived player object, but _decoy here was createVehicle'd
// moments earlier in this very script, and a condition reading _target
// getVariable [...] against a freshly created object can throw on a client
// whose local copy isn't fully resolved yet (confirmed live on the near-
// identical Waldo_fnc_fakeHealthStation/Waldo_fnc_c4Charge mistake - a
// throwing condition is silently treated as false, so the action just
// never appeared at all). Waldo_fnc_identifyBody itself already no-ops once
// Waldo_roleRevealed is set, so the only cost of dropping that gate here is
// the prompt staying clickable (harmlessly) after the reveal, instead of
// risking it never showing up in the first place.
[_decoy, [
	["<t color='#ffd23f'>%1</t>", "STR_TIA_Action_IdentifyBody"],
	{
		params ["_target", "_caller"];
		[_target, _caller] remoteExec ["Waldo_fnc_identifyBody", 2];
	},
	nil, 4, true, false, "",
	"alive _this",
	2.5
]] remoteExec ["Waldo_fnc_addActionL", 0, _decoy];   // title localised per client

[_decoy] spawn { params ["_d"]; sleep 60; if (!isNull _d) then { deleteVehicle _d }; };
