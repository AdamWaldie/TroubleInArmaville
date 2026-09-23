//////////////////////////////////////////////////////////////////
// Waldo_fnc_hintL
// CLIENT: hint (or hintSilent) of a localisable value (see
// Waldo_fnc_localize). Remote-executed by the server in place of plain
// "hint" so the text is localised on the receiving client.
//
// params: [_value, _silent]
//   _value  - key, plain string, or [fmtKey, args...]
//   _silent - true for hintSilent (default false)
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};
params [["_value", ""], ["_silent", false, [true]]];
private _text = [_value] call Waldo_fnc_localize;
if (_silent) then { hintSilent _text } else { hint _text };
