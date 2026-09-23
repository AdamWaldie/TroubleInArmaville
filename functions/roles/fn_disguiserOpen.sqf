//////////////////////////////////////////////////////////////////
// Waldo_fnc_disguiserOpen
// CLIENT: opens the Disguiser's target-picker dialog (WaldoDisguise) - one
// button per living player other than the caller, labelled with their name
// and (only where the caller is actually allowed to know it - the same
// reveal rule Waldo_fnc_scoreboard uses, so this never leaks a role beyond
// what a Traitor already legitimately knows: their own team, the Jester,
// the public Detective, and anyone a Detective has already identified)
// their role.
//
// Deliberately does NOT consume the Disguiser purchase - this only opens
// the menu. Pressing ESC here must leave the item untouched, so the actual
// purchase consumption happens in Waldo_fnc_disguiserActivate instead, once
// a target is genuinely picked (see there, and Waldo_fnc_consumeActivationItem).
//
// params: [_purchId, _slotIdx]
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};
params ["_purchId", "_slotIdx"];

if (!alive player) exitWith {};

disableSerialization;
createDialog "WaldoDisguise";
waitUntil { !isNull (uiNamespace getVariable ["WaldoDisguise", displayNull]) };
private _display = uiNamespace getVariable "WaldoDisguise";

private _myRole = player getVariable ["role", "Innocent"];
private _traitors = missionNamespace getVariable ["TraitorList", []];

// Same reveal rule as Waldo_fnc_scoreboard's _rowFor - kept in sync with it
// deliberately rather than a shared helper, since it's four short lines and
// the scoreboard's own version is already the single reference point this
// mirrors.
private _revealRole = {
	params ["_p"];
	private _role     = _p getVariable ["role", "Innocent"];
	private _revealed = _p getVariable ["Waldo_roleRevealed", false];
	private _reveal = (_role == "Detective")
		|| _revealed
		|| {_myRole == "Traitor" && {(_p in _traitors) || {_role == "Jester"}}};
	if (_reveal) then { _role } else { "Innocent" };
};

private _group = _display displayCtrl 3801;
private _targets = allPlayers select { alive _x && {_x != player} };
private _rowW = 0.26 * safezoneW;
private _rowH = 0.05 * safezoneH;
private _gapY = 0.006 * safezoneH;

{
	private _p = _x;
	private _i = _forEachIndex;
	private _role = [_p] call _revealRole;
	private _color = [_role] call Waldo_roleColor;

	private _btn = _display ctrlCreate ["RscButton", 3820 + _i, _group];
	_btn ctrlSetPosition [0, _i * (_rowH + _gapY), _rowW, _rowH];
	_btn ctrlSetText format [localize "STR_TIA_Disguiser_Row", name _p, toUpper localize ("STR_TIA_Role_" + _role)];
	_btn ctrlSetFontHeight (0.6 * _rowH);
	_btn ctrlSetBackgroundColor [_color select 0, _color select 1, _color select 2, 0.45];
	_btn ctrlSetTextColor [0.95, 0.93, 0.86, 1];
	_btn setVariable ["disguiseTarget", _p];
	_btn setVariable ["purchId", _purchId];
	_btn setVariable ["slotIdx", _slotIdx];
	_btn ctrlAddEventHandler ["ButtonClick", {
		params ["_ctrl"];
		private _target = _ctrl getVariable "disguiseTarget";
		private _pid    = _ctrl getVariable "purchId";
		private _sidx   = _ctrl getVariable "slotIdx";
		closeDialog 1;
		[_target, _pid, _sidx] call Waldo_fnc_disguiserActivate;
	}];
	_btn ctrlCommit 0;
} forEach _targets;

if (count _targets == 0) then {
	private _lbl = _display ctrlCreate ["RscStructuredText", 3830, _group];
	_lbl ctrlSetPosition [0, 0, _rowW, _rowH * 2];
	_lbl ctrlSetStructuredText parseText format ["<t color='#9EA290'>%1</t>", localize "STR_TIA_Disguiser_NoTargets"];
	_lbl ctrlCommit 0;
};
