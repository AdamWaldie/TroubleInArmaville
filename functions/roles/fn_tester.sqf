//////////////////////////////////////////////////////////////////
// Waldo_fnc_tester
// CLIENT: detective activation item (Y/U/J, whichever it's bound to). "Tests"
// the aimed-at person within 3m (alive or a corpse), permanently revealing
// their role to the detective via the icons handler - after a 5s delay, not
// instantly. The target is notified the moment testing starts (a corpse has
// no screen to put this on, so only a living player gets it), with an extra
// warning if they're a Traitor that the test will expose them - the delay is
// the window that notification buys them to react (flee, silence the
// detective) before the reveal locks in.
//
// Returns true when a valid target was tested (so it is consumed), false
// otherwise so it stays assigned for another try.
//////////////////////////////////////////////////////////////////

private _target = cursorTarget;

if (isNull _target || {!(_target isKindOf "CAManBase")}) exitWith {
	["STR_TIA_Tester_Title", "STR_TIA_Tester_NoTarget", "WARNING", 3, "BOTTOM_LEFT", "TESTER", "STR_TIA_Tester_Source"] call Waldo_fnc_ShowUiNotification;
	false
};

if ((player distance _target) > 3) exitWith {
	["STR_TIA_Tester_Title", "STR_TIA_Tester_MoveCloser", "WARNING", 3, "BOTTOM_LEFT", "TESTER", "STR_TIA_Tester_Source"] call Waldo_fnc_ShowUiNotification;
	false
};

["STR_TIA_Tester_Title", "STR_TIA_Tester_Testing", "INFO", 2, "BOTTOM_LEFT", "TESTER", "STR_TIA_Tester_Source"] call Waldo_fnc_ShowUiNotification;

if (isPlayer _target && {alive _target}) then {
	private _targetRole = _target getVariable ["role", "Innocent"];
	// Keys, not text: this card is drawn on the TARGET's machine, so it has
	// to be localised there, in their language rather than ours.
	private _msg = "STR_TIA_Tester_BeingTested";
	private _state = "WARNING";
	if (_targetRole == "Traitor") then {
		_msg = "STR_TIA_Tester_BeingTestedTraitor";
		_state = "ERROR";
	};
	[
		"STR_TIA_Tester_BeingTestedTitle", _msg, _state, 6, "TOP_RIGHT", "TESTED", "STR_TIA_Tester_Source"
	] remoteExec ["Waldo_fnc_ShowUiNotification", _target];
};

[_target] spawn {
	params ["_target"];
	sleep 5;
	_target setVariable ["tested", true, true];
	private _role = _target getVariable ["role", "Innocent"];
	// Same role palette every other role indicator in this HUD uses
	// (Waldo_roleColor, fn_initShops.sqf) - already accessibility-aware via
	// the colourblind-safe Okabe-Ito set when that mode is on. Structured
	// text only takes a hex colour, not an RGBA array, so convert it the
	// same way Waldo_fnc_pingWheelRender already does.
	private _roleColor = [_role] call Waldo_roleColor;
	private _hex = {
		params ["_c"];
		private _d = "0123456789abcdef";
		private _byte = { params ["_v"]; private _n = (round (_v * 255)) max 0 min 255; (_d select [floor (_n / 16), 1]) + (_d select [_n mod 16, 1]) };
		"#" + ([_c select 0] call _byte) + ([_c select 1] call _byte) + ([_c select 2] call _byte)
	};
	private _roleHex = [_roleColor] call _hex;
	["STR_TIA_Tester_Title", format [localize "STR_TIA_Tester_Complete", format ["<t color='%1'>%2</t>", _roleHex, localize ("STR_TIA_Role_" + _role)]],
		"SUCCESS", 4, "BOTTOM_LEFT", "TESTER", "STR_TIA_Tester_Source"] call Waldo_fnc_ShowUiNotification;
};

true
