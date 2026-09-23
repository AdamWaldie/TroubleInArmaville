//////////////////////////////////////////////////////////////////
// Waldo_fnc_pingWheelRender
// CLIENT: redraws the 5 ping-picker rows, highlighting Waldo_pingWheelIndex.
// Called on open and every mouse-wheel step (Waldo_fnc_pingWheelOpen). Rows
// are RscStructuredText (not plain RscText) so parseText's <t> colour tags
// can style the label/description differently within one line - a plain
// RscText's ctrlSetText only ever renders in a single flat colour.
//////////////////////////////////////////////////////////////////

disableSerialization;
private _display = uiNamespace getVariable ["TTTHud", displayNull];
if (isNull _display) exitWith {};

private _options = missionNamespace getVariable ["Waldo_pingWheelOptions", []];
private _sel = missionNamespace getVariable ["Waldo_pingWheelIndex", 0];
private _color = ["Traitor"] call Waldo_roleColor;
private _hex = {
	params ["_c"];
	private _d = "0123456789abcdef";
	private _byte = { params ["_v"]; private _n = (round (_v * 255)) max 0 min 255; (_d select [floor (_n / 16), 1]) + (_d select [_n mod 16, 1]) };
	"#" + ([_c select 0] call _byte) + ([_c select 1] call _byte) + ([_c select 2] call _byte)
};
private _colorHex = [_color] call _hex;

{
	_x params ["", "_labelKey", "_descKey"];
	private _label = localize _labelKey;
	private _desc = localize _descKey;
	private _ctrl = _display displayCtrl (3510 + _forEachIndex);
	private _isSel = _forEachIndex == _sel;
	if (_isSel) then {
		_ctrl ctrlSetStructuredText parseText format [
			"<t color='%1' size='1.05'>&gt;  %2</t><br/><t color='#9EA290' size='0.85'>%3</t>",
			_colorHex, _label, _desc
		];
		_ctrl ctrlSetBackgroundColor [_color select 0, _color select 1, _color select 2, 0.16];
	} else {
		_ctrl ctrlSetStructuredText parseText format ["<t color='#BFBCAF'>%1</t>", _label];
		_ctrl ctrlSetBackgroundColor [0, 0, 0, 0];
	};
} forEach _options;
