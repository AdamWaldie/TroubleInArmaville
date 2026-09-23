//////////////////////////////////////////////////////////////////
// Waldo_fnc_topBarTimer
// CLIENT: drives the top bar's round-timer text (idc 3603) and its accent
// bar (idc 3602), which doubles as a countdown progress indicator - it
// shrinks toward the centre as the civilian clock runs down, and flashes
// once 30s or less remain. Started exactly ONCE per client session, from
// fn_initClient.sqf, immediately after that file's own `waitUntil { gameOn }`
// - by the time this runs, the round is genuinely live and
// Waldo_startTime/timelimit are already broadcast, so no extra readiness
// gating is needed here. Unlike fn_initHud.sqf (which re-runs on every
// respawn/role change), this function's caller only ever runs once, so no
// duplicate-start guard is needed either.
//
// Computes the countdown locally every tick from state the server already
// publishes (Waldo_startTime, timelimit, Waldo_roundLiveAt, gameOn) instead
// of the old approach (Waldo_fnc_roundLoop remoteExec-ing a formatted
// hintSilent string to every client every second) - one less per-second
// broadcast, and each client trusts its own local `time` (kept in sync with
// the server automatically by the engine) rather than a string that could
// arrive late under network jitter.
//
// Self-healing against the display being recreated: fn_initHud.sqf now
// guards its own titleRsc call so TTTHud is only ever created once (see the
// comment there - repeat titleRsc calls for the same class recreate the
// display, which is what silently blanked this exact control before that
// fix), but re-checking here too costs nothing and matches the same
// isNull-guarded refresh already used by the credits-readout loop.
//
// Exits cleanly the moment gameOn goes false - the round is over (about to
// restart the whole mission, per this ruleset), nothing left to count down.
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};

private _display = displayNull;
private _timerCtrl = controlNull;
private _accentCtrl = controlNull;

private _fmt = {
	params ["_s"];
	private _clamped = 0 max _s;
	private _m = floor (_clamped / 60);
	private _sec = floor (_clamped % 60);
	format ["%1:%2", _m, [str _sec, "0" + str _sec] select (_sec < 10)]
};

private _accentCenterX = safezoneX + (0.5 * safezoneW);
private _accentFullW = 0.36 * safezoneW;
private _accentY = (safezoneY + (0.015 * safezoneH)) + (0.062 * safezoneH);
private _accentH = 0.006 * safezoneH;
private _accentNormal = [0.85, 0.62, 0.20, 1];
private _accentWarn = [0.9, 0.15, 0.1, 1];

private _timerBoxX = (safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW);
private _timerBoxY = safezoneY + (0.015 * safezoneH);
private _timerBoxW = 0.36 * safezoneW;
private _timerBoxH = 0.062 * safezoneH;

while { missionNamespace getVariable ["gameOn", false] } do {
	if (isNull _timerCtrl || {isNull _accentCtrl} || {isNull (uiNamespace getVariable ["TTTHud", displayNull])}) then {
		waitUntil { !isNull (uiNamespace getVariable ["TTTHud", displayNull]) };
		_display = uiNamespace getVariable "TTTHud";
		_timerCtrl = _display displayCtrl 3603;
		_accentCtrl = _display displayCtrl 3602;

		// Measured/positioned only when (re)fetched, not every tick - every
		// value this ever displays is the same handful of fixed-height
		// characters (digits, a colon, "Round"/"Deadline" labels), so its
		// rendered height doesn't meaningfully change between ticks, only its
		// width (traitors see a longer string) - and ST_CENTER already
		// handles horizontal centring on its own.
		_timerCtrl ctrlSetText format [localize "STR_TIA_Timer_Round", "0:00"];
		private _textH = ctrlTextHeight _timerCtrl;
		_timerCtrl ctrlSetPosition [_timerBoxX, _timerBoxY + ((_timerBoxH - _textH) / 2), _timerBoxW, _textH];
		_timerCtrl ctrlCommit 0;
	};

	private _start     = missionNamespace getVariable ["Waldo_startTime", 180];
	private _timelimit = missionNamespace getVariable ["timelimit", _start];
	private _liveAt    = missionNamespace getVariable ["Waldo_roundLiveAt", time];
	private _elapsed   = time - _liveAt;

	private _civRemaining = _start - _elapsed;

	// Labelled, not just two bare numbers side by side - "3:24 (4:09)" never
	// said which was which. "Deadline", not "Traitor": this second clock is
	// the round's real hard end time (timelimit - grows on every death, see
	// Waldo_fnc_onKilled), not a "time left as a Traitor" countdown - only
	// Traitors are shown it, since only they get the full extended-by-deaths
	// picture, but the label needs to describe what the number IS, not who
	// sees it.
	private _text = format [localize "STR_TIA_Timer_Round", if (_civRemaining <= 0) then { localize "STR_TIA_Timer_Overtime" } else { [_civRemaining] call _fmt }];
	if ((player getVariable ["role", ""]) == "Traitor") then {
		private _traitorRemaining = _timelimit - _elapsed;
		_text = _text + "     " + format [localize "STR_TIA_Timer_OvertimeDeadline", [_traitorRemaining] call _fmt];
	};
	_timerCtrl ctrlSetText _text;

	// Progress bar: shrinks toward the centre as the civilian clock runs down
	// (the one timer every player shares, so it's the meaningful "how much of
	// the round is left" reference regardless of role), then flashes once 30s
	// or less remain (including overtime - if anything that's more urgent, not
	// less). ctrlCommit 0 - this needs to track the countdown exactly, not
	// ease into position a tick behind it.
	private _progress = (0 max (_civRemaining / (_start max 1))) min 1;
	private _barW = _accentFullW * _progress;
	_accentCtrl ctrlSetPosition [_accentCenterX - (_barW / 2), _accentY, _barW, _accentH];
	_accentCtrl ctrlCommit 0;

	if (_civRemaining <= 30) then {
		private _flashOn = (floor (time / 0.5)) mod 2 == 0;
		_accentCtrl ctrlSetBackgroundColor (if (_flashOn) then { _accentWarn } else { _accentNormal });
	} else {
		_accentCtrl ctrlSetBackgroundColor _accentNormal;
	};
	_accentCtrl ctrlCommit 0;

	sleep 0.25;
};
