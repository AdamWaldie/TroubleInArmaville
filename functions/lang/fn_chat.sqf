//////////////////////////////////////////////////////////////////
// Waldo_fnc_chat
// CLIENT: systemChat of a localisable value (see Waldo_fnc_localize).
// The server remoteExecs THIS instead of plain "systemChat" so the line is
// localised on the receiving client, in that player's own language.
//
// params: [_value]  - key, plain string, or [fmtKey, args...]
// Example: [["STR_TIA_Karma_LowWarning", name _x, 40, 2]] remoteExec ["Waldo_fnc_chat", 0];
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};
params [["_value", ""]];
systemChat ([_value] call Waldo_fnc_localize);
