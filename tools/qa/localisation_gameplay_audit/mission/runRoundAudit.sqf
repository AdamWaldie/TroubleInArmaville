// SERVER: use the shipped round functions and simulated-player API.
call compile preprocessFileLineNumbers "qa\auditConfig.sqf";
call compile preprocessFileLineNumbers "qa\qaCommon.sqf";
waitUntil { time > 1 && {count allPlayers > 0} && {!isNil "Waldo_fnc_checkWin"} };
waitUntil { missionNamespace getVariable ["TTT_QA_UiComplete", false] };

["mission-initialised", !isNil "Waldo_fnc_initServer" && {!isNil "Waldo_fnc_initClient"}] call TTT_QA_Check;
missionNamespace setVariable ["TestingFlag", true, true];
missionNamespace setVariable ["roundBaseLength", 30];
missionNamespace setVariable ["roundPlayerLength", 5];
missionNamespace setVariable ["roundTraitorLength", 10];
[] call Waldo_fnc_resetState;
[] call Waldo_fnc_assignRoles;
private _assignedRole = player getVariable ["role", ""];
private _assignedRoster = switch (_assignedRole) do {
	case "Traitor": { missionNamespace getVariable ["TraitorList", []] };
	case "Detective": { missionNamespace getVariable ["DetectiveList", []] };
	case "Jester": { missionNamespace getVariable ["JesterList", []] };
	default { allPlayers - (missionNamespace getVariable ["TraitorList", []]) };
};
[
	"role-assignment-populates-rosters",
	_assignedRole in ["Innocent", "Traitor", "Detective", "Jester"] && {player in _assignedRoster},
	_assignedRole
] call TTT_QA_Check;
[] call Waldo_fnc_startRound;
[
	"round-start-timers",
	missionNamespace getVariable ["gameOn", false]
		&& {missionNamespace getVariable ["Waldo_startTime", 0] >= 35}
		&& {missionNamespace getVariable ["timelimit", 0] > missionNamespace getVariable ["Waldo_startTime", 0]}
] call TTT_QA_Check;

private _unit = player;
_unit setVariable ["role", "Innocent", true];
// The preceding solo role-assignment check correctly made the only real
// player a Traitor. Build a fresh Innocents-win roster before adding the
// simulated Traitor, otherwise membership (not the later role string) still
// leaves the real player alive in TraitorList and invalidates this scenario.
missionNamespace setVariable ["TraitorList", [], true];
missionNamespace setVariable ["Waldo_hadNonTraitors", true, true];
[_unit, "Traitor", 1] call Waldo_debugSpawnSim;
[_unit, "Traitor"] call Waldo_debugKillSims;
uiSleep 0.2;
["innocents-win-after-traitor-death", [0, 9999] call Waldo_fnc_checkWin == "END1"] call TTT_QA_Check;
[_unit] call Waldo_debugClearSims;

_unit setVariable ["role", "Traitor", true];
missionNamespace setVariable ["TraitorList", [_unit], true];
missionNamespace setVariable ["Waldo_hadNonTraitors", true, true];
[_unit, "Innocent", 1] call Waldo_debugSpawnSim;
[_unit, "NonTraitor"] call Waldo_debugKillSims;
uiSleep 0.2;
["traitors-win-after-last-nontraitor-death", [0, 9999] call Waldo_fnc_checkWin == "END2"] call TTT_QA_Check;
[_unit] call Waldo_debugClearSims;

missionNamespace setVariable ["TraitorList", [], true];
missionNamespace setVariable ["JESTERCLEANKILL", false, true];
["time-limit-win", [10, 10] call Waldo_fnc_checkWin == "END3"] call TTT_QA_Check;
missionNamespace setVariable ["JESTERCLEANKILL", true, true];
["jester-win-priority", [10, 10] call Waldo_fnc_checkWin == "END4"] call TTT_QA_Check;

[] call Waldo_fnc_resetState;
[
	"round-reset-clears-state",
	!(missionNamespace getVariable ["gameOn", true])
		&& {count (missionNamespace getVariable ["TraitorList", [objNull]]) == 0}
		&& {!(missionNamespace getVariable ["JESTERCLEANKILL", true])}
] call TTT_QA_Check;
[] call Waldo_fnc_startRound;
["next-round-can-start", missionNamespace getVariable ["gameOn", false]] call TTT_QA_Check;

diag_log format ["TTT QA ROUND COMPLETE: %1 finding(s) %2", count TTT_QA_Findings, TTT_QA_Findings];
missionNamespace setVariable ["TTT_QA_RoundComplete", true, true];
