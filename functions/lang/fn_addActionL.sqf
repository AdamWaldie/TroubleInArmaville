//////////////////////////////////////////////////////////////////
// Waldo_fnc_addActionL
// CLIENT: addAction whose title is localised on THIS client. The server
// remoteExecs this (JIP-keyed to the object, like a plain addAction) instead
// of the raw "addAction" command, so every player reads the action in their
// own game language rather than the server's.
//
// params: [_object, _actionArgs]
//   _actionArgs - the normal addAction argument array, except element 0 (the
//                 title) may be anything Waldo_fnc_localize accepts, e.g.
//                 ["<t color='#3FE07A'>%1</t>", "STR_TIA_Health_Title"]
// Example:
//   [_obj, [["<t color='#FFFFFF'>%1</t>", "STR_TIA_Action_DefuseCharge"], { ... }]] remoteExec ["Waldo_fnc_addActionL", 0, _obj];
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};
params [["_object", objNull, [objNull]], ["_actionArgs", [], [[]]]];
if (isNull _object || {count _actionArgs == 0}) exitWith {};

private _args = +_actionArgs;
_args set [0, [_args select 0] call Waldo_fnc_localize];
_object addAction _args
