//////////////////////////////////////////////////////////////////
// Waldo_fnc_applyKarma
// SERVER: applies carry-over karma at the start of a round, then decays it.
//
// Karma is stored per player UID in profileNamespace (the only store that
// survives the per-round mission restart). Killing a teammate (RDM) lowers
// it heavily in Waldo_fnc_onKilled, a Traitor-on-Traitor teamkill lowers it
// a little. Here we:
//   - scale down low-karma players' starting credits (graduated, not a hard
//     cliff - see _fullThreshold/_zeroThreshold below) + public warning,
//   - DECAY everyone back toward neutral so punishment is never permanent
//     (this is the fix for "bugs out on repeat" caused by the old flag that
//      was written every round but never reset),
//   - PRUNE stored karma for UIDs no longer present so the profile can't
//     grow without bound.
//
// Runs AFTER Waldo_fnc_assignRoles has already set each player's starting
// "points" (see the call site) - this scales down whatever they were
// already given rather than setting credits directly, so it composes
// correctly with the Traitor/Detective base-credit and per-player-count
// lobby settings instead of overriding them outright.
//////////////////////////////////////////////////////////////////

if (!isServer) exitWith {};

// Graduated multiplier instead of the old hard 50-karma/0-credits cliff -
// full credits at _fullThreshold+, zero at _zeroThreshold-, linear between,
// so a mildly-tarnished player (say karma 45) loses some credits rather
// than being wiped out exactly the same as someone at karma 1.
private _fullThreshold = 80;
private _zeroThreshold = 20;
private _decay = 10;          // karma regained each round
private _maxKarma = 100;

{
	private _uid = getPlayerUID _x;
	if (_uid != "") then {
		private _key = "Waldo_karma_" + _uid;
		private _k = profileNamespace getVariable [_key, _maxKarma];

		private _mult = if (_k >= _fullThreshold) then {
			1
		} else {
			if (_k <= _zeroThreshold) then {
				0
			} else {
				(_k - _zeroThreshold) / (_fullThreshold - _zeroThreshold)
			};
		};

		if (_mult < 1) then {
			private _starting = _x getVariable ["points", 0];
			// ceil, not round - a partial-credit remainder always rounds UP in
			// the player's favour (e.g. 1 starting credit at _mult 0.5 keeps
			// that credit instead of rounding down to 0), so the graduated
			// scale never overshoots into a harsher cut than the multiplier
			// itself implies.
			private _reduced = ceil (_starting * _mult);
			_x setVariable ["points", _reduced, true];
			// Key + args, localised on each receiving client (Waldo_fnc_chat).
			[["STR_TIA_Karma_LowWarning", name _x, round _k, _reduced]] remoteExec ["Waldo_fnc_chat", 0];
		};

		// decay toward neutral
		profileNamespace setVariable [_key, (_k + _decay) min _maxKarma];
	};
} forEach allPlayers;

// Prune karma entries for UIDs that are not currently present.
private _presentUids = allPlayers apply { getPlayerUID _x };
{
	if ((_x select [0, 12]) == "Waldo_karma_") then {
		private _uid = _x select [12];
		if !(_uid in _presentUids) then { profileNamespace setVariable [_x, nil]; };
	};
} forEach (allVariables profileNamespace);

saveProfileNamespace;
