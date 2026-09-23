//////////////////////////////////////////////////////////////////
// Waldo_fnc_disguiserActivate
// CLIENT: copies the target's CURRENT loadout onto the caller for 60s, then
// reverts to the caller's own original loadout. While active,
// Waldo_disguiseActive/Waldo_disguiseAs (broadcast, so the SERVER can read
// them off the culprit) redirect any DNA/evidence Waldo_fnc_onKilled would
// normally attribute to the caller onto the disguise target instead - see
// there.
//
// This is what actually consumes the Disguiser purchase - opening the
// picker (Waldo_fnc_disguiserOpen) does not, only a genuine pick does, via
// Waldo_fnc_consumeActivationItem.
//
// A second disguise while one is already running replaces it outright:
// reverts to the ORIGINAL pre-disguise loadout (never a mid-disguise one,
// since the own-loadout snapshot is only taken when nothing is active yet)
// and restarts the 60s window on the new target. A generation token (same
// idiom as Waldo_radarToken/Waldo_dnaTrackToken elsewhere) stops the first
// disguise's own countdown/revert loop from running past that point and
// stripping the second disguise early. The same token/active check also
// stops a loop that's still ticking across a round boundary (assignRoles
// force-clears Waldo_disguiseActive on every player at round start) from
// reverting a brand new round's freshly-assigned loadout using a stale
// snapshot.
//
// params: [_target, _purchId, _slotIdx]
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};
params ["_target", "_purchId", "_slotIdx"];

if (!alive player || {isNull _target} || {!alive _target}) exitWith {};

[_purchId, _slotIdx] call Waldo_fnc_consumeActivationItem;

if !(player getVariable ["Waldo_disguiseActive", false]) then {
	player setVariable ["Waldo_disguiseOwnLoadout", getUnitLoadout player];
};

player setUnitLoadout (getUnitLoadout _target);
// Broadcast: Waldo_fnc_onKilled runs on the SERVER and reads these off the
// culprit to redirect DNA attribution.
player setVariable ["Waldo_disguiseAs", _target, true];
player setVariable ["Waldo_disguiseActive", true, true];

private _dur = 60;
private _endAt = time + _dur;
player setVariable ["Waldo_disguiseToken", (player getVariable ["Waldo_disguiseToken", 0]) + 1];
private _token = player getVariable ["Waldo_disguiseToken", 0];

[
	"STR_TIA_Disguiser_Title", ["STR_TIA_Disguiser_Active", name _target, _dur],
	"SUCCESS", 6, "TOP_RIGHT", "DISGUISE", "STR_TIA_Role_Traitor"
] call Waldo_fnc_ShowUiNotification;

[_token, _endAt] spawn {
	params ["_token", "_endAt"];

	waitUntil { uiSleep 0.1; !isNull (uiNamespace getVariable ["TTTHud", displayNull]) || !alive player };
	private _ctrl = objNull;
	if (alive player && {(player getVariable ["Waldo_disguiseToken", 0]) == _token}) then {
		private _display = uiNamespace getVariable "TTTHud";
		// Top-right corner - the only always-on element up here, so it
		// doesn't need to dodge the centred top bar or the bottom-right role
		// crest. Same dynamic ctrlCreate-once/update-in-place technique as
		// Waldo_fnc_radarCountdown's corner label.
		private _w = 0.18 * safezoneW;
		private _h = 0.045 * safezoneH;
		private _x = (safezoneX + safezoneW) - _w - (0.015 * safezoneH);
		private _y = safezoneY + (0.015 * safezoneH);
		_ctrl = _display ctrlCreate ["RscStructuredText", -1];
		_ctrl ctrlSetPosition [_x, _y, _w, _h];
		_ctrl ctrlCommit 0;
	};

	while {
		alive player
		&& {(player getVariable ["Waldo_disguiseToken", 0]) == _token}
		&& {player getVariable ["Waldo_disguiseActive", false]}
		&& {time < _endAt}
	} do {
		if (!isNull _ctrl) then {
			private _remaining = ceil (_endAt - time);
			_ctrl ctrlSetStructuredText parseText format [
				"<t align='right' font='PuristaMedium' size='1.0' shadow='1' color='#D9AE34'>%1</t>", format [localize "STR_TIA_Disguiser_Countdown", _remaining]
			];
		};
		sleep 1;
	};

	if (!isNull _ctrl) then { ctrlDelete _ctrl; };

	// Lost the race to a newer disguise (token bumped already), or the
	// active flag was already cleared out from under us (a newer disguise,
	// or a fresh round starting) - either way, that's not this call's
	// revert to perform.
	if ((player getVariable ["Waldo_disguiseToken", 0]) != _token) exitWith {};
	if !(player getVariable ["Waldo_disguiseActive", false]) exitWith {};

	player setVariable ["Waldo_disguiseActive", false, true];
	player setVariable ["Waldo_disguiseAs", objNull, true];
	if (alive player) then {
		player setUnitLoadout (player getVariable ["Waldo_disguiseOwnLoadout", getUnitLoadout player]);
		[
			"STR_TIA_Disguiser_Title", "STR_TIA_Disguiser_WornOff",
			"INFO", 5, "TOP_RIGHT", "DISGUISE", "STR_TIA_Role_Traitor"
		] call Waldo_fnc_ShowUiNotification;
	};
};
