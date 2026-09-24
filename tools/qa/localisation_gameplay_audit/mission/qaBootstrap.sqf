// CLIENT: wait for the real mission and run every player-facing UI case.
if (!hasInterface) exitWith {};
call compile preprocessFileLineNumbers "qa\auditConfig.sqf";
call compile preprocessFileLineNumbers "qa\qaCommon.sqf";

waitUntil { !isNull player && {!isNil "Waldo_fnc_initHud"} && {!isNil "Waldo_traitorShop"} };
waitUntil { time > 1 && {missionNamespace getVariable ["mapDone", false]} };
diag_log format ["TTT QA CLIENT READY: %1", TTT_QA_Language];

private _unresolved = TTT_QA_StringKeys select {
	private _value = localize _x;
	_value isEqualTo "" || {_value isEqualTo _x}
};
["localisation-keys-resolve", count _unresolved == 0, str _unresolved] call TTT_QA_Check;

[] execVM "qa\runUiAudit.sqf";
