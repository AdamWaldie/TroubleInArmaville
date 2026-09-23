//////////////////////////////////////////////////////////////////
// Waldo_fnc_revive
// CLIENT: activation item (Y/U/J, whichever it's bound to). Aim at a dead
// PLAYER's body within 3m and press it. A Detective restores the player with
// their original allegiance; a Traitor revives them onto the Traitor team
// ("Defibrillator").
//
// A truly dead unit (damage 1, Killed already fired) can never be revived in
// place - respawn always creates a brand-new unit object. So this can't act
// on the body directly: it forces an early respawn and stashes the revive
// intent ON the corpse (broadcast setVariable), for onPlayerRespawn.sqf to
// read via its direct _oldUnit parameter once the new unit actually exists.
//
// Returns true when a revive was performed (consuming the item), false
// otherwise so the item stays assigned.
//////////////////////////////////////////////////////////////////

private _target = cursorTarget;
private _warn = {
	params ["_msg"];
	["STR_TIA_Revive_Title", _msg, "WARNING", 3, "BOTTOM_LEFT", "REVIVE", "STR_TIA_Revive_Title"] call Waldo_fnc_ShowUiNotification;
};

if (isNull _target || {!(_target isKindOf "CAManBase")} || {alive _target}) exitWith {
	["STR_TIA_RemoveBody_AimAtBody"] call _warn;
	false
};
if (isNil { _target getVariable "player" }) exitWith {
	["STR_TIA_Revive_CannotRevive"] call _warn;
	false
};
if ((player distance _target) > 3) exitWith {
	["STR_TIA_RemoveBody_MoveCloser"] call _warn;
	false
};

private _revived = _target getVariable "player";
if (isNull _revived) exitWith { ["STR_TIA_Revive_Failed"] call _warn; false };

["STR_TIA_Revive_Title", "STR_TIA_Revive_Reviving", "INFO", 3, "BOTTOM_LEFT", "REVIVE", "STR_TIA_Revive_Title"] call Waldo_fnc_ShowUiNotification;

// Y is handled unscheduled (called directly from the KeyDown handler), so
// both delays below have to live in their own scheduled thread.
[_revived] spawn {
	params ["_revived"];
	sleep 3;

	// Stash the revive intent on the corpse - onPlayerRespawn.sqf runs on the
	// revived player's own machine and gets the same object directly as
	// _oldUnit, so a broadcast setVariable here is all that's needed to hand it
	// off (no UID lookup required).
	private _asTraitor = (player getVariable ["role", ""]) == "Traitor";
	_revived setVariable ["Waldo_reviveAsTraitor", _asTraitor, true];
	_revived setVariable ["Waldo_revivePending", true, true];

	// Let them respawn now, then restore the long wait for future deaths.
	[0] remoteExec ["setPlayerRespawnTime", _revived];
	sleep 0.5;
	[2400] remoteExec ["setPlayerRespawnTime", _revived];

	["STR_TIA_Revive_Title", "STR_TIA_Revive_Complete", "SUCCESS", 4, "BOTTOM_LEFT", "REVIVE", "STR_TIA_Revive_Title"] call Waldo_fnc_ShowUiNotification;
};

true
