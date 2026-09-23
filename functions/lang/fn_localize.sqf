//////////////////////////////////////////////////////////////////
// Waldo_fnc_localize
// SHARED: resolves a "localisable" value into display text in THIS
// machine's own game language (stringtable.xml at the mission root).
//
// Adaptive by design: text that the server builds and sends to clients
// (notification cards, announcements, chat lines) is sent as keys + args,
// never as a pre-localised string. Each client resolves it here with its own
// language, so a German and an English player each get their own text.
// Calling `localize` on the server would produce the server's language for
// everyone.
//
// Accepted forms:
//   "STR_TIA_Role_Traitor"      -> localize "STR_TIA_Role_Traitor"
//   "any other string"          -> returned unchanged (player names, numbers
//                                  already formatted, legacy plain text)
//   ["STR_TIA_MVP_BodyOne", a, b, c] -> format [localize "STR_TIA_MVP_BodyOne", a, b, c],
//                                  where every arg is itself resolved by this
//                                  function first (so a role name key or a
//                                  nested [fmt, ...] array is localised too)
//   anything else (TEXT, NUMBER, ...) -> returned unchanged
//
// Only the STR_TIA_ prefix is treated as a key - a player whose name happens
// to start with "STR_" still shows up as their name.
//////////////////////////////////////////////////////////////////

params [["_value", ""]];

if (_value isEqualType "") exitWith {
	if ((toUpper (_value select [0, 8])) isEqualTo "STR_TIA_" && {isLocalized _value}) then {
		localize _value
	} else {
		_value
	};
};

if (_value isEqualType [] && {count _value > 0}) exitWith {
	private _parts = _value apply { [_x] call Waldo_fnc_localize };
	format _parts
};

_value
