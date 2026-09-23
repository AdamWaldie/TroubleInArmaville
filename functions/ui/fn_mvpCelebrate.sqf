//////////////////////////////////////////////////////////////////
// Waldo_fnc_mvpCelebrate
// CLIENT: plays the round-end MVP celebration (broadcast from
// Waldo_fnc_roundMVP): replays the intro music, pops a short fireworks-style
// display over the arena, and banners the round's top scorer - or just a plain
// "Round Complete" if nobody scored a kill this round.
//
// params: [_name, _role, _kills]  - _name == "" means no MVP this round.
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};
params [["_name", ""], ["_role", ""], ["_kills", 0]];

// Reset fadeMusic's scripted volume multiplier before playing - it's a
// standing engine-level value (not track-specific, not reset by playMusic
// itself), and Waldo_fnc_initClient's own `10 fadeMusic 0;` at round-live
// just left it at 0 for the round that's now ending. Without this, the
// replay resolves and "plays" with zero audible output.
0 fadeMusic 1;
playMusic ["TTTIntroMusic", 20];

// Fireworks: a handful of coloured smoke shells launched up and out over the
// arena centre, popping in a loose sequence for a celebratory feel.
private _center = missionNamespace getVariable ["mapPos", getPosATL player];
[_center] spawn {
	params ["_center"];
	private _colors = ["SmokeShellGreen", "SmokeShellRed", "SmokeShellYellow", "SmokeShellBlue", "SmokeShellPurple", "SmokeShellOrange"];
	for "_i" from 1 to 8 do {
		private _p = _center vectorAdd [-15 + random 30, -15 + random 30, 40 + random 20];
		private _s = (selectRandom _colors) createVehicle _p;
		_s setVelocity [-2 + random 4, -2 + random 4, -6 - random 4];
		sleep 0.35;
	};
};

// Waldo_fnc_ShowUiNotification (functions/uinotify/), "TOP" placement - the
// same reserved top-centre slot the old topBarAnnounce banner used to sit
// in, so this doesn't fight the round timer/keybind row for space, and
// doesn't touch hintSilent (the whole reason that channel used to race
// fn_dnaScanner.sqf's tracking readout, see the fn_initHud.sqf/
// fn_dnaScanner.sqf history) at all anymore.
private _title = if (_name != "") then { "STR_TIA_MVP_Title" } else { "STR_TIA_MVP_Complete" };
private _msg = if (_name != "") then {
	// _role arrives as the role id from the server - localised here.
	[["STR_TIA_MVP_BodyMany", "STR_TIA_MVP_BodyOne"] select (_kills == 1), _name, "STR_TIA_Role_" + _role, _kills]
} else {
	"STR_TIA_MVP_NoKills"
};
[_title, _msg, "SUCCESS", 8, "TOP", "MVP", "STR_TIA_Source_Round"] call Waldo_fnc_ShowUiNotification;
