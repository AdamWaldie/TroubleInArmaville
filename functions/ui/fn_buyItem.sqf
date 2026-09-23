//////////////////////////////////////////////////////////////////
// Waldo_fnc_buyItem
// CLIENT: handles one purchase - checks credits, deducts, runs the buy effect,
// and (for activation items) assigns it to the first free of 3 key slots
// (Y/U/J), or the backlog if all 3 are already taken - see
// Waldo_fnc_useActivationSlot / Waldo_fnc_assignActivationSlot for how those
// are fired/reassigned.
//
// The shop is left OPEN after a purchase so the player can keep browsing; the
// header credits and each card's affordability are refreshed live, and the
// footer confirms the buy.
//
// params: [_role, _index]
//////////////////////////////////////////////////////////////////

params ["_role", "_index"];
disableSerialization;

private _catalog = if (_role == "Traitor") then { Waldo_traitorShop } else { Waldo_detectiveShop };
if (_index < 0 || _index >= count _catalog) exitWith {};

private _item = _catalog select _index;
_item params ["_name", "_cost", "_type", "_onBuy", "_onAct", "_tip", ["_requires", ""]];

// _name/_requires are stringtable keys (the language-independent item id);
// only the text shown to the player is localised.
private _nameL = localize _name;

private _pts  = player getVariable ["points", 0];
private _disp = uiNamespace getVariable ["WaldoShop", displayNull];

if (_pts < _cost) exitWith {
	if (isNull _disp) then {
		hint localize "STR_TIA_Buy_NotEnoughHint";
	} else {
		(_disp displayCtrl 1103) ctrlSetStructuredText parseText (format [
			"<t size='1.15' color='#E4514B'>%1</t><br/><t size='0.95' color='#F2EFE3'>%2</t>",
			localize "STR_TIA_Buy_NotEnoughTitle", format [localize "STR_TIA_Buy_NotEnoughBody", _nameL, _cost, _pts]
		]);
	};
};

// Defense in depth: the shop UI already greys this button out and explains
// why, but block it here too rather than trusting the client not to have
// clicked a button that was disabled for a reason.
if (_requires != "" && {((player getVariable ["Waldo_purchases", []]) findIf { (_x select 1) == _requires }) < 0}) exitWith {
	if (isNull _disp) then {
		hint format [localize "STR_TIA_Buy_RequiresHint", localize _requires];
	} else {
		(_disp displayCtrl 1103) ctrlSetStructuredText parseText (format [
			"<t size='1.15' color='#E4514B'>%1</t><br/><t size='0.95' color='#F2EFE3'>%2</t>",
			format [localize "STR_TIA_Buy_RequiresTitle", toUpper localize _requires],
			format [localize "STR_TIA_Buy_RequiresBody", localize _requires, _nameL]
		]);
	};
};

private _new = _pts - _cost;
player setVariable ["points", _new, true];

// Immediate purchase effect.
call _onBuy;

// Log the purchase (id + name + tip + type + activation code) for the shop's
// "Purchased" panel - the id is what key slots/backlog reference, never the
// code block itself (see Waldo_fnc_useActivationSlot).
private _id = player getVariable ["Waldo_purchaseSeq", 0];
player setVariable ["Waldo_purchaseSeq", _id + 1];

private _keyLabel = if (_type == "activation") then { [_id] call Waldo_fnc_registerActivationSlot } else { "" };

private _purchases = player getVariable ["Waldo_purchases", []];
_purchases pushBack [_id, _name, _tip, _type, _onAct];
player setVariable ["Waldo_purchases", _purchases];

if (isNull _disp) exitWith {
	if (_type == "activation") then {
		if (_keyLabel != "") then {
			hint format [localize "STR_TIA_Buy_ReadyHint", _nameL, _keyLabel];
		} else {
			hint format [localize "STR_TIA_Buy_KeysFullHint", _nameL];
		};
	};
};

[_disp] call Waldo_shopRenderPurchased;

// --- Refresh the open shop: credits, card affordability, and a confirmation. ---
(_disp displayCtrl 1101) ctrlSetText (format [localize "STR_TIA_Buy_Credits", _new]);

private _color = [_role] call Waldo_roleColor;
private _nowOwned = _purchases;
{
	_x params ["", "_c", "", "", "", "", ["_req", ""]];
	private _btn = _disp displayCtrl (2000 + _forEachIndex);
	if (!isNull _btn) then {
		private _hasReq = (_req == "") || { (_nowOwned findIf { (_x select 1) == _req }) >= 0 };
		if (_new >= _c && _hasReq) then {
			_btn ctrlSetBackgroundColor [_color select 0, _color select 1, _color select 2, 0.85];
			_btn ctrlSetTextColor [0.95, 0.93, 0.86, 1];
		} else {
			_btn ctrlSetBackgroundColor [0.06, 0.065, 0.055, 0.92];
			_btn ctrlSetTextColor [0.75, 0.42, 0.4, 1];
		};
	};
} forEach _catalog;

private _extra = "";
if (_type == "activation") then {
	_extra = if (_keyLabel != "") then { " " + format [localize "STR_TIA_Buy_PressToUse", _keyLabel] } else { " " + localize "STR_TIA_Buy_AssignBelow" };
};
(_disp displayCtrl 1103) ctrlSetStructuredText parseText (format [
	"<t size='1.2' color='#6FCB74'>%1</t><t size='0.95' color='#9EA290'>%2</t><br/><t size='0.95' color='#9EA290'>%3</t>",
	format [localize "STR_TIA_Buy_Purchased", _nameL], _extra, format [localize "STR_TIA_Buy_CreditsRemaining", _new]
]);
