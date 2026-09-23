//////////////////////////////////////////////////////////////////
// Waldo_fnc_confineToArena
// CLIENT: keeps the local player inside the arena. Uses a single managed
// loop guarded by a per-player flag so it can never stack up if called
// again (e.g. after a revive).
//
// params: [_spawnPos, _spawnDir, _radius, _center]
//////////////////////////////////////////////////////////////////

params ["_spawnPos", "_spawnDir", "_radius", "_center"];

// Signal any previous confine loop to stop, then start a fresh one.
player setVariable ["Waldo_confineGen", (player getVariable ["Waldo_confineGen", 0]) + 1];
private _gen = player getVariable "Waldo_confineGen";

[_spawnPos, _spawnDir, _radius, _center, _gen] spawn {
	params ["_p", "_d", "_r", "_c", "_gen"];
	// gameOn gates both the loop itself and the deferred hintSilent "" below -
	// without it this kept running (and could still fire/clear a hint) after
	// the round ended, racing Waldo_fnc_mvpCelebrate for the same hintSilent
	// channel the same way fn_dnaScanner.sqf's tracking loop used to.
	while {
		alive player
		&& {(player getVariable ["Waldo_confineGen", 0]) == _gen}
		&& {missionNamespace getVariable ["gameOn", true]}
	} do {
		if ((player distance _c) > (_r + 5)) then {
			player setPos _p;
			player setDir _d;
			hintSilent localize "STR_TIA_Arena_NoEscape";
			sleep 5;
			if (missionNamespace getVariable ["gameOn", true]) then { hintSilent ""; };
		};
		sleep 10;
	};
};
