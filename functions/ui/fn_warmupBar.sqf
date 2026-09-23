//////////////////////////////////////////////////////////////////
// Waldo_fnc_warmupBar
// CLIENT: shows "Selecting Roles: N" in the same centre-top position/casing
// as the round timer (TTTWarmup, a separate resource from TTTHud - role isn't
// assigned yet at this point, so there's nothing for TTTHud itself to show).
// Computes the countdown locally from Waldo_warmupEndAt (the server `time`
// warmup ends at, broadcast once) instead of the old per-second remoteExec'd
// hint, same reasoning as Waldo_fnc_topBarTimer.
//
// A cutRsc, deliberately NOT a titleRsc like TTTHud: this runs during the
// exact same window as Waldo_fnc_titleSequence's BIS_fnc_typeText call, which
// is built on the titleText command - titleText/titleRsc/titleObj all share
// ONE engine-wide "title" layer (confirmed via allActiveTitleEffects - title
// effects report layer -1, distinct from cutText/cutRsc/cutObj's own numbered
// layers), so a titleRsc TTTWarmup would get evicted by every single
// character BIS_fnc_typeText types (and would evict the type sequence right
// back) - exactly why nothing was showing. cutRsc has its own, separate
// layer system, so this coexists with the mission's title-card animation
// instead of fighting it.
//
// Being on a different layer than TTTHud (its own named cut layer) also
// means TTTHud's cutRsc call does NOT evict this automatically the way same-layer calls
// would - every exit path below explicitly clears the cutRsc itself instead
// of relying on that.
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};

if (missionNamespace getVariable ["gameOn", false]) exitWith {};   // already live by the time this got here - nothing to show

if (isNull (uiNamespace getVariable ["TTTWarmup", displayNull])) then {
	cutRsc ["TTTWarmup", "PLAIN", 1, false];
};
waitUntil { !isNull (uiNamespace getVariable ["TTTWarmup", displayNull]) };
private _display = uiNamespace getVariable "TTTWarmup";
private _textCtrl = _display displayCtrl 3630;

private _boxX = (safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW);
private _boxY = safezoneY + (0.015 * safezoneH);
private _boxW = 0.36 * safezoneW;
private _boxH = 0.062 * safezoneH;

_textCtrl ctrlSetText format [localize "STR_TIA_Warmup_SelectingRoles", 0];
private _textH = ctrlTextHeight _textCtrl;
_textCtrl ctrlSetPosition [_boxX, _boxY + ((_boxH - _textH) / 2), _boxW, _textH];
_textCtrl ctrlCommit 0;

while { !(missionNamespace getVariable ["gameOn", false]) } do {
	if (missionNamespace getVariable ["Waldo_debugSkipWarmup", false]) exitWith {};
	private _endAt = missionNamespace getVariable ["Waldo_warmupEndAt", time];
	private _remaining = ceil (0 max (_endAt - time));
	_textCtrl ctrlSetText format [localize "STR_TIA_Warmup_SelectingRoles", _remaining];
	if (_remaining <= 0) exitWith {};   // warmup's over - TTTHud takes over at round-live
	sleep 0.25;
};

cutText ["", "PLAIN"];   // explicit clear - TTTHud's own cutRsc is on a different layer and won't do this for us
