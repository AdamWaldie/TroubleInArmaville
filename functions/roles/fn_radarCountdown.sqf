//////////////////////////////////////////////////////////////////
// Waldo_fnc_radarCountdown
// CLIENT: a small always-on corner label counting down to the owner's next
// Radar pulse (Waldo_radarNextPing, kept up to date by
// Waldo_fnc_traitorRadar/Waldo_fnc_detectiveRadar each time it recharges).
// One control, created once and text-updated in place each tick - no
// per-tick ctrlCreate/ctrlDelete churn. Replaces rather than stacks if
// called again (rebuying Radar), and clears itself on death.
//
// params: [_interval]
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};
params ["_interval"];

player setVariable ["Waldo_radarCountdownToken", (player getVariable ["Waldo_radarCountdownToken", 0]) + 1];
private _token = player getVariable ["Waldo_radarCountdownToken", 0];

[_token, _interval] spawn {
	params ["_token", "_interval"];

	waitUntil { uiSleep 0.1; !isNull (uiNamespace getVariable ["TTTHud", displayNull]) || !alive player };
	if (!alive player) exitWith {};
	private _display = uiNamespace getVariable "TTTHud";

	// Tucked just under the round-timer bar (fn_topBarTimer.sqf), same
	// horizontal centring, small and out of the way of everything else.
	// Sized to fit the bumped-up text below (was 0.12x0.03, too tight once
	// the font size went from 0.6 to 1.0 to actually be legible).
	private _w = 0.16 * safezoneW;
	private _h = 0.045 * safezoneH;
	private _x = safezoneX + (0.5 * safezoneW) - (_w / 2);
	private _y = safezoneY + (0.015 * safezoneH) + (0.062 * safezoneH) + (0.008 * safezoneH);

	private _ctrl = _display ctrlCreate ["RscStructuredText", -1];
	_ctrl ctrlSetPosition [_x, _y, _w, _h];
	_ctrl ctrlCommit 0;

	while { alive player && {(player getVariable ["Waldo_radarCountdownToken", 0]) == _token} } do {
		private _remaining = ceil (((player getVariable ["Waldo_radarNextPing", time]) - time) max 0);
		// RscStructuredText's own base "size" (ui/common.hpp) is the same
		// formula the round-timer text right above this uses for ITS sizeEx,
		// just without that control's extra *1.35 - so a <t size='X'> here is
		// already on the same scale as the timer, not some separate/smaller
		// unit. 0.6 rendered at roughly half the timer's on-screen size right
        // next to it, which read as "the countdown is tiny" - 1.0 lines it up
		// far closer while still reading as the secondary element. Also adding
		// the shadow every other label in this HUD has - this was the only
		// text control in the file without one, and a gold (#D9AE34) glyph
		// with no shadow washes out against bright terrain/sky behind it.
		_ctrl ctrlSetStructuredText parseText format [
			"<t align='center' font='PuristaMedium' size='1.0' shadow='1' color='#D9AE34'>%1</t>", format [localize "STR_TIA_Radar_Countdown", _remaining]
		];
		sleep 1;
	};

	if (!isNull _ctrl) then { ctrlDelete _ctrl; };
};
