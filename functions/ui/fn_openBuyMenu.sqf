//////////////////////////////////////////////////////////////////
// Waldo_fnc_openBuyMenu
// CLIENT: opens the shared shop dialog and generates its item cards at runtime
// from the role's catalog (Waldo_traitorShop / Waldo_detectiveShop). One layout
// serves both shops; adding an item needs no UI edits.
//
// The panel has a role-tinted header (title + live credits), a scrollable grid
// of item cards coloured by affordability, and a description footer that updates
// as you hover a card. Clicking a card buys it (Waldo_fnc_buyItem).
//
// params: [_role]  ("Traitor" | "Detective")
//////////////////////////////////////////////////////////////////

params ["_role"];
disableSerialization;

private _catalog = if (_role == "Traitor") then { Waldo_traitorShop } else { Waldo_detectiveShop };
private _color = [_role] call Waldo_roleColor;
// #rrggbb form for the structured-text description footer - see
// Waldo_roleColorHex (fn_initShops.sqf) for why this isn't a local helper.
private _colorHex = [_role] call Waldo_roleColorHex;

private _typeLabel = {
	params ["_t"];
	switch (_t) do {
		case "weapon":     { localize "STR_TIA_Buy_TypeWeapon" };
		case "passive":    { localize "STR_TIA_Buy_TypePassive" };
		// Which of Y/U/J actually fires this depends on key assignment (see the
		// Purchased panel), so this can't hardcode a specific key.
		case "activation": { localize "STR_TIA_Buy_TypeActivation" };
		default            { _t };
	};
};

createDialog "WaldoShop";
waitUntil { !isNull (uiNamespace getVariable ["WaldoShop", displayNull]) };
private _display = uiNamespace getVariable "WaldoShop";

// --- Header: a neutral dark bar with a thin stripe tinted to the role colour ---
(_display displayCtrl 1108) ctrlSetBackgroundColor [_color select 0, _color select 1, _color select 2, 1];
(_display displayCtrl 1100) ctrlSetText (format [localize "STR_TIA_Buy_Armory", toUpper localize ("STR_TIA_Role_" + _role)]);

private _credits = player getVariable ["points", 0];
(_display displayCtrl 1101) ctrlSetText (format [localize "STR_TIA_Buy_Credits", _credits]);

// --- Default footer hint ---
(_display displayCtrl 1103) ctrlSetStructuredText parseText format [
	"<t size='1.0' color='#9EA290'>%1</t>", localize "STR_TIA_Buy_FooterHint"
];

// --- Purchased-this-round panel (what you already own + how to use it) ---
[_display] call Waldo_shopRenderPurchased;

// --- Item cards ---
// Catalogs run ~14 items (7 rows of 2): sized so all 7 rows fit inside the
// group's declared height (0.395 * safezoneH) with margin to spare, rather than
// relying on RscControlsGroup to auto-scroll runtime-created (ctrlCreate)
// children - that scroll-extent behaviour isn't guaranteed the way it is for a
// single oversized declared child (as used by the Purchased panel/Scoreboard).
private _group = _display displayCtrl 1102;
private _cols = 2;
private _bw   = 0.202 * safezoneW;
private _bh   = 0.048 * safezoneH;
private _gapX = 0.012 * safezoneW;
private _gapY = 0.008 * safezoneH;

private _owned = player getVariable ["Waldo_purchases", []];
{
	_x params ["_name", "_cost", "_type", "_onBuy", "_onAct", "_tip", ["_requires", ""]];
	private _i  = _forEachIndex;
	private _cx = _i mod _cols;
	private _cy = floor (_i / _cols);
	// A _requires item that isn't owned yet blocks the buy the same way not
	// having enough credits does - Enhanced Scanner does nothing without the
	// DNA Scanner it upgrades, so letting it be bought first just wastes
	// credits on a passive with nothing to attach to.
	private _hasRequirement = (_requires == "") || { (_owned findIf { (_x select 1) == _requires }) >= 0 };
	private _afford = (_credits >= _cost) && _hasRequirement;
	// Catalog entries hold stringtable keys - localise for display only.
	private _nameL = localize _name;
	private _tipL = localize _tip;
	private _requiresL = if (_requires == "") then { "" } else { localize _requires };

	private _btn = _display ctrlCreate ["RscButton", 2000 + _i, _group];
	_btn ctrlSetPosition [_cx * (_bw + _gapX), _cy * (_bh + _gapY), _bw, _bh];
	_btn ctrlSetText (format [localize "STR_TIA_Buy_CardLabel", _nameL, _cost]);
	_btn ctrlSetTooltip (if (_hasRequirement) then { _tipL } else { format [localize "STR_TIA_Buy_RequiresTip", _requiresL, _tipL] });
	_btn ctrlSetFontHeight (0.85 * (_bh min (0.04 * safezoneH)));

	if (_afford) then {
		_btn ctrlSetBackgroundColor [_color select 0, _color select 1, _color select 2, 0.85];
		_btn ctrlSetTextColor [0.95, 0.93, 0.86, 1];
	} else {
		_btn ctrlSetBackgroundColor [0.06, 0.065, 0.055, 0.92];
		_btn ctrlSetTextColor [0.75, 0.42, 0.4, 1];
	};

	// Pre-format the hover description shown in the footer (idc 1103).
	private _afHex = ["#F2BE55", "#E4514B"] select (!_afford);
	private _reqLine = if (_hasRequirement) then { "" } else {
		format ["<br/><t size='0.9' color='#E4514B'>%1</t>", format [localize "STR_TIA_Buy_RequiresFirst", _requiresL]]
	};
	_btn setVariable ["descText", format [
		"<t size='1.3' color='%1'>%2</t>   <t size='1.1' color='%3'>%4</t>   <t size='0.9' color='#9EA290'>%5</t><br/><br/><t size='1.05'>%6</t>%7",
		_colorHex, _nameL, _afHex, format [localize "STR_TIA_Buy_CostCr", _cost], ([_type] call _typeLabel), _tipL, _reqLine
	]];
	_btn setVariable ["role", _role];
	_btn setVariable ["itemIndex", _i];

	_btn ctrlAddEventHandler ["MouseEnter", {
		params ["_ctrl"];
		(ctrlParent _ctrl displayCtrl 1103) ctrlSetStructuredText parseText (_ctrl getVariable ["descText", ""]);
	}];
	_btn ctrlAddEventHandler ["ButtonClick", {
		params ["_ctrl"];
		[(_ctrl getVariable "role"), (_ctrl getVariable "itemIndex")] call Waldo_fnc_buyItem;
	}];
	_btn ctrlCommit 0;
} forEach _catalog;
