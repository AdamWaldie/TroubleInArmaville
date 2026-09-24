// CLIENT: deterministic screenshots of the shipped UI code paths.
waitUntil { !isNil "TTT_QA_Capture" };

missionNamespace setVariable ["mapDone", false];
[] spawn Waldo_fnc_pregameScreen;
uiSleep 0.5;
["pregame"] call TTT_QA_Capture;
missionNamespace setVariable ["mapDone", true];
call TTT_QA_CloseSurface;

missionNamespace setVariable ["roundWarmupLength", 8];
missionNamespace setVariable ["gameOn", false];
missionNamespace setVariable ["Waldo_warmupEndAt", time + 8];
[] spawn Waldo_fnc_warmupBar;
uiSleep 0.5;
["warmup"] call TTT_QA_Capture;
missionNamespace setVariable ["gameOn", true];
call TTT_QA_CloseSurface;

{
	private _role = _x;
	player setVariable ["role", _role];
	player setVariable ["points", 7];
	missionNamespace setVariable ["TraitorList", if (_role == "Traitor") then {[player]} else {[]}];
	missionNamespace setVariable ["DetectiveList", if (_role == "Detective") then {[player]} else {[]}];
	missionNamespace setVariable ["JesterList", if (_role == "Jester") then {[player]} else {[]}];
	[] call Waldo_fnc_initHud;
	uiSleep 0.5;
	["hud-" + toLower _role] call TTT_QA_Capture;
} forEach ["Innocent", "Traitor", "Detective", "Jester"];

{
	_x params ["_role", "_mates", "_detective", "_jester", "_jesterName"];
	[_role, _mates, _detective, _jester, _jesterName] call Waldo_fnc_showRoleCard;
	uiSleep 0.4;
	["role-card-" + toLower _role] call TTT_QA_Capture;
	call TTT_QA_CloseSurface;
} forEach [
	["Innocent", [], "Detective Example", true, ""],
	["Traitor", ["Traitor Teammate"], "Detective Example", true, "Jester Example"],
	["Detective", [], "Detective Example", true, ""],
	["Jester", [], "Detective Example", true, ""]
];

player setVariable ["role", "Innocent"];
[] spawn Waldo_fnc_openStylePicker;
uiSleep 0.7;
["style-picker"] call TTT_QA_Capture;
call TTT_QA_CloseSurface;

player setVariable ["role", "Traitor"];
player setVariable ["points", 100];
player setVariable ["Waldo_purchases", []];
[] call Waldo_fnc_initHud;
["Traitor"] spawn Waldo_fnc_openBuyMenu;
uiSleep 0.7;
["traitor-shop"] call TTT_QA_Capture;
call TTT_QA_CloseSurface;

player setVariable ["Waldo_purchases", [[9001, "STR_TIA_Shop_Disguiser", "STR_TIA_ShopTip_T_Disguiser", "activation", {}]]];
player setVariable ["Waldo_activationSlots", [9001, -1, -1]];
["Traitor"] spawn Waldo_fnc_openBuyMenu;
uiSleep 0.7;
["traitor-shop-purchased"] call TTT_QA_Capture;
call TTT_QA_CloseSurface;

player setVariable ["Waldo_purchases", []];
player setVariable ["role", "Detective"];
[] call Waldo_fnc_initHud;
["Detective"] spawn Waldo_fnc_openBuyMenu;
uiSleep 0.7;
["detective-shop"] call TTT_QA_Capture;
call TTT_QA_CloseSurface;

{
	private _role = _x;
	player setVariable ["role", _role];
	missionNamespace setVariable ["TraitorList", if (_role == "Traitor") then {[player]} else {[]}];
	missionNamespace setVariable ["DetectiveList", if (_role == "Detective") then {[player]} else {[]}];
	missionNamespace setVariable ["JesterList", if (_role == "Jester") then {[player]} else {[]}];
	[] spawn Waldo_fnc_scoreboard;
	uiSleep 0.7;
	["scoreboard-" + toLower _role] call TTT_QA_Capture;
	call TTT_QA_CloseSurface;
} forEach ["Innocent", "Traitor", "Detective", "Jester"];

player setVariable ["role", "Traitor"];
[9001, 0] spawn Waldo_fnc_disguiserOpen;
uiSleep 0.7;
["disguiser-no-targets"] call TTT_QA_Capture;
call TTT_QA_CloseSurface;

[] call Waldo_fnc_pingWheelOpen;
uiSleep 0.5;
["ping-wheel"] call TTT_QA_Capture;
[] call Waldo_fnc_pingWheelClose;
call TTT_QA_CloseSurface;

["STR_TIA_Identify_BodyIdentified", ["STR_TIA_Identify_BodyIdentifiedBody", "Detective", "Body", "STR_TIA_Role_Traitor"], "SUCCESS", 30, "TOP_RIGHT", "QA_ONE", "STR_TIA_Identify_Source"] call Waldo_fnc_ShowUiNotification;
["STR_TIA_TeamKill_Title", ["STR_TIA_TeamKill_BodyOne", "Teammate", 1, 2], "WARNING", 30, "BOTTOM_LEFT", "QA_TWO", "STR_TIA_Role_Traitor"] call Waldo_fnc_ShowUiNotification;
uiSleep 0.7;
["notifications"] call TTT_QA_Capture;
call TTT_QA_CloseSurface;

[8] spawn Waldo_fnc_radarCountdown;
uiSleep 0.7;
["radar-countdown"] call TTT_QA_Capture;
player setVariable ["Waldo_radarCountdownToken", (player getVariable ["Waldo_radarCountdownToken", 0]) + 1];
uiSleep 1.1;
call TTT_QA_CloseSurface;

["Example Player", "Detective", 3] call Waldo_fnc_mvpCelebrate;
uiSleep 0.7;
["mvp"] call TTT_QA_Capture;
call TTT_QA_CloseSurface;

// Deliberately call setup a second time: its once-per-session guard must keep
// this capture at one copy of each entry instead of multiplying the diary.
[] call Waldo_fnc_setupBriefing;
openMap true;
uiSleep 1;
["briefing-map"] call TTT_QA_Capture;
call TTT_QA_CloseSurface;

diag_log format ["TTT QA UI COMPLETE: %1 capture(s)", count TTT_QA_ExpectedCaptures];
missionNamespace setVariable ["TTT_QA_UiComplete", true, true];
