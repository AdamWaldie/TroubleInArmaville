//////////////////////////////////////////////////////////////////
// Waldo_fnc_openStylePicker
// CLIENT: opens the role crest style picker (H key). Shows one named card
// per style (0 Original .. 8 Stamped Tag) - the selected one's own
// background fills with the player's role colour, so it's clear which
// style is active without a separate border/highlight control. Clicking a
// card sets Waldo_roleCrestStylePref in profileNamespace, saves it,
// refreshes the live HUD (Waldo_fnc_initHud), and closes the dialog - this
// replaces the old H-key cycle-through-styles behaviour entirely.
//////////////////////////////////////////////////////////////////

disableSerialization;

private _role = player getVariable ["role", "Innocent"];
private _color = [_role] call Waldo_roleColor;
private _current = profileNamespace getVariable ["Waldo_roleCrestStylePref", 0];

createDialog "WaldoStylePicker";
waitUntil { !isNull (uiNamespace getVariable ["WaldoStylePicker", displayNull]) };
private _display = uiNamespace getVariable "WaldoStylePicker";

// Real vertical centring, not ST_VCENTER (see the comment above spTitle in
// ui/TTTHud.hpp) - same ctrlTextHeight technique as the badge letter, applied
// to the dialog title and to all 9 card labels.
//
// Only ever applied to text controls. It used to be run on the cards
// themselves, back when each card was one control carrying both its background
// and its label: that shrank the card's background down to the height of its
// own text, so the "card" was really a thin strip and the selected style's
// highlight was a thin band rather than a filled card. The cards are plain
// backgrounds now and their labels are separate controls, so there's nothing
// left to shrink by accident.
private _vcenter = {
	params ["_ctrl"];
	private _h = ctrlTextHeight _ctrl;
	private _pos = ctrlPosition _ctrl;
	_ctrl ctrlSetPosition [_pos select 0, (_pos select 1) + (((_pos select 3) - _h) / 2), _pos select 2, _h];
	_ctrl ctrlCommit 0;
};
[_display displayCtrl 1590] call _vcenter;
{ [_display displayCtrl _x] call _vcenter; } forEach [1620, 1621, 1622, 1623, 1624, 1625, 1626, 1627, 1628];

// Paints the 9 cards: an amber selection frame behind the current style's card
// only. Nothing else needs tinting - the cards are named, not previewed (three
// attempts at a preview graphic at this size all rendered as blank or black boxes
// in game, so per direction the names carry it), and the crest itself is visible
// the moment a card is picked.
Waldo_stylePickerPaint = {
	params ["_d"];
	private _cur = profileNamespace getVariable ["Waldo_roleCrestStylePref", 0];
	{
		(_d displayCtrl _x) ctrlShow (_forEachIndex == _cur);
	} forEach [1630, 1631, 1632, 1633, 1634, 1635, 1636, 1637, 1638];
};
[_display] call Waldo_stylePickerPaint;

private _btnIdcs = [1640, 1641, 1642, 1643, 1644, 1645, 1646, 1647, 1648];
{
	private _i = _forEachIndex;
	(_display displayCtrl _x) ctrlAddEventHandler ["ButtonClick", {
		params ["_ctrl"];
		private _style = _ctrl getVariable "styleIndex";
		profileNamespace setVariable ["Waldo_roleCrestStylePref", _style];
		saveProfileNamespace;
		[] call Waldo_fnc_initHud;
		closeDialog 1;
	}];
	(_display displayCtrl _x) setVariable ["styleIndex", _i];
} forEach _btnIdcs;

// Colourblind-safe palette toggle. ctrlAddEventHandler code runs in its own
// scope with no access to this script's private variables (a real SQF footgun,
// not a style choice), which is why the card-painting pass lives in
// Waldo_stylePickerPaint above rather than in a local: the handler can call
// the same function the initial run did instead of keeping a duplicate copy of
// the tinting logic in sync with it by hand.
private _accessBtn = _display displayCtrl 1592;
private _setAccessLabel = { params ["_btn", "_on"]; _btn ctrlSetText (localize (["STR_TIA_Style_ColourblindOff", "STR_TIA_Style_ColourblindOn"] select _on)) };
[_accessBtn, profileNamespace getVariable ["Waldo_accessibilityMode", false]] call _setAccessLabel;
_accessBtn ctrlAddEventHandler ["ButtonClick", {
	params ["_ctrl"];
	private _on = !(profileNamespace getVariable ["Waldo_accessibilityMode", false]);
	profileNamespace setVariable ["Waldo_accessibilityMode", _on];
	saveProfileNamespace;
	_ctrl ctrlSetText (localize (["STR_TIA_Style_ColourblindOff", "STR_TIA_Style_ColourblindOn"] select _on));

	[] call Waldo_fnc_initHud;   // live badge picks up the new palette immediately
}];
