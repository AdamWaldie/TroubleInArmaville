//////////////////////////////////////////////////////////////////
// Waldo_fnc_topBarAnnounce
// CLIENT: "pops out" a banner directly under the top bar's keybind row
// (topBarAnnounceShadow/BG/Text, idc 3619-3621) - fades IN, holds, then
// fades back OUT, rather than an instant hint-style pop. Used for anything
// worth a one-off callout during a live round (golden airdrop drops, etc.)
// without stealing the hint/hintSilent channel other systems already rely on.
//
// params: [_text, _color, _hold]
//   _text  - plain string, STR_TIA_ key or [fmtKey, args...] - resolved with
//            Waldo_fnc_localize on this client (no markup - this is ctrlSetText, not structured text,
//            same "keep colour and precise layout apart" reasoning as the
//            keybind row in fn_initHud.sqf)
//   _color - [r,g,b], alpha is driven by the fade itself
//   _hold  - seconds to stay fully visible before fading back out
//
// Token-guarded (same idiom as Waldo_hintFadeToken in fn_initHud.sqf): calling
// this again before a previous announcement finished immediately supersedes
// it - checked both before the fade-in starts (so two near-simultaneous calls
// don't fight over the same controls) and before the fade-out (so a stale
// announcement's timer can't cut a newer one short).
//////////////////////////////////////////////////////////////////

params [["_text", "", ["", []]], ["_color", [1, 0.82, 0.25], [[]]], ["_hold", 4, [0]]];

if (!hasInterface) exitWith {};

private _display = uiNamespace getVariable ["TTTHud", displayNull];
if (isNull _display) exitWith {};

private _shadowCtrl = _display displayCtrl 3619;
private _bgCtrl = _display displayCtrl 3620;
private _textCtrl = _display displayCtrl 3621;
if (isNull _shadowCtrl || {isNull _bgCtrl} || {isNull _textCtrl}) exitWith {};

_textCtrl ctrlSetText ([_text] call Waldo_fnc_localize);

private _token = (_display getVariable ["Waldo_announceToken", 0]) + 1;
_display setVariable ["Waldo_announceToken", _token];

[_shadowCtrl, _bgCtrl, _textCtrl, _display, _token, _color, _hold] spawn {
	params ["_shadowCtrl", "_bgCtrl", "_textCtrl", "_display", "_token", "_color", "_hold"];
	if ((_display getVariable ["Waldo_announceToken", 0]) != _token) exitWith {};   // already superseded before we even started

	_shadowCtrl ctrlSetBackgroundColor [0, 0, 0, 0.55];
	_shadowCtrl ctrlCommit 0.6;
	_bgCtrl ctrlSetBackgroundColor [0.105, 0.11, 0.095, 0.85];
	_bgCtrl ctrlCommit 0.6;
	_textCtrl ctrlSetTextColor [_color select 0, _color select 1, _color select 2, 1];
	_textCtrl ctrlCommit 0.6;

	sleep (0.6 + _hold);
	if ((_display getVariable ["Waldo_announceToken", 0]) != _token) exitWith {};   // superseded by a newer announcement

	_shadowCtrl ctrlSetBackgroundColor [0, 0, 0, 0];
	_shadowCtrl ctrlCommit 0.6;
	_bgCtrl ctrlSetBackgroundColor [0.105, 0.11, 0.095, 0];
	_bgCtrl ctrlCommit 0.6;
	_textCtrl ctrlSetTextColor [_color select 0, _color select 1, _color select 2, 0];
	_textCtrl ctrlCommit 0.6;
};
