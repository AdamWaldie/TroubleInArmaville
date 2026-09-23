//////////////////////////////////////////////////////////////////
// Waldo_fnc_onKilled
// SERVER-authoritative kill handler (invoked from an MPKilled EH that
// fires on every machine; only the server acts). Handles:
//   - extending the round timer per death
//   - awarding shop credits (detectives for traitor kills, vice versa)
//   - Jester clean-kill detection (non-Traitor killed the Jester)
//   - Jester kill-by-Traitor penalty (Waldo_jesterKillFloor, severe - strips
//     the culprit down to the floor rather than a fixed deduction)
//   - Traitor-on-Traitor teamkill penalty (Waldo_traitorTeamkillPenalty,
//     small credit + karma hit - previously entirely free)
//   - karma: lowering the culprit's karma for killing a teammate (RDM), or
//     a smaller amount for a Traitor teamkill
//   - DNA/evidence attribution, including redirecting it onto whoever the
//     culprit is currently disguised as (Waldo_fnc_disguiserActivate) or is
//     framing (False Flag)
//
// params (from MPKilled): [_unit, _killer, _instigator, _useEffects]
//////////////////////////////////////////////////////////////////

params ["_unit", "_killer", "_instigator", "_useEffects"];
if (!isServer) exitWith {};

// MPKilled is broadcast (fires on every machine, this guard is why only the
// server's own execution matters at all) - but nothing stopped it from
// firing MORE THAN ONCE for the same death (a stray damage tick on an
// already-dead body, an ACE unconscious->death race, etc.), and every
// single thing below - round timer extension, credit rewards, DNA state,
// the addAction - has no guard of its own against running twice. Confirmed
// in testing as duplicate "Identify Body" actions stacking on one corpse.
// A revived unit is a brand-new object (Waldo_fnc_reviveRelink), so this
// flag never carries over into a life that legitimately needs to be
// processed again.
if (_unit getVariable ["Waldo_deathProcessed", false]) exitWith {};
_unit setVariable ["Waldo_deathProcessed", true, true];

private _traitors = missionNamespace getVariable ["TraitorList", []];
private _detectives = missionNamespace getVariable ["DetectiveList", []];

// Extend the round for every death - diminishing returns rather than a hard
// wall. This used to add roundDeadLength on every single death with no
// ceiling at all (a chaotic high-kill round, with revives creating more
// deaths to extend it further, could run "overtime" - the stretch between
// the civilian clock hitting zero and the real deadline, timelimit - longer
// than the round itself), then a flat `min roundBaseLength` cap that just
// stopped extending outright past that point - the Nth death mattered
// exactly as much as the 1st right up until it suddenly mattered not at
// all. Hyperbolic saturation instead: Waldo_deathBonusRaw accumulates
// uncapped (the "if every death counted in full" total), and the bonus
// actually applied is cap * raw / (raw + cap) - strictly increasing with
// every death (so nothing ever hard-stops extending the round), but each
// additional death's marginal contribution shrinks as the total climbs,
// approaching (never quite reaching) the cap.
//
// The cap itself is HALF of roundBaseLength, not the full base length - a
// stale, dragged-out round is worse than a slightly early one, so worst
// case (asymptotically, i.e. never quite hit) a round can grow by half its
// planned length from deaths plus the flat traitor bonus on top, not
// double it.
private _dead = missionNamespace getVariable ["roundDeadLength", 30];
private _cap = (missionNamespace getVariable ["roundBaseLength", 180]) * 0.5;
private _raw = (missionNamespace getVariable ["Waldo_deathBonusRaw", 0]) + _dead;
missionNamespace setVariable ["Waldo_deathBonusRaw", _raw, true];
private _deathBonus = _cap * (_raw / (_raw + _cap));
missionNamespace setVariable ["Waldo_deathBonusTotal", _deathBonus, true];
private _traitorBonus = missionNamespace getVariable ["roundTraitorLength", 45];
missionNamespace setVariable ["timelimit", (missionNamespace getVariable ["Waldo_startTime", 0]) + _traitorBonus + _deathBonus, true];

private _victimRole = _unit getVariable ["role", "Innocent"];

// Resolve the real culprit (instigator preferred; fall back to killer).
private _culprit = _instigator;
if (isNull _culprit) then { _culprit = _killer; };

// Final fallback: the last unit that actually damaged the victim, tracked locally via
// HandleDamage on the victim's own machine (Waldo_lastDamager, set in fn_initClient.sqf).
// Covers ACE bleed-out/DoT deaths, where the terminal MPKilled event's own
// killer/instigator can resolve to null or to the victim themselves even though a real
// player's shot is what actually put them down.
if (isNull _culprit || {_culprit == _unit}) then {
	private _lastDamager = _unit getVariable ["Waldo_lastDamager", objNull];
	if (!isNull _lastDamager && {_lastDamager != _unit}) then { _culprit = _lastDamager; };
};
private _culpritRole = if (isNull _culprit) then { "" } else { _culprit getVariable ["role", ""] };

// --- Forensic state on the body (for the DNA scanner + Identify Body) ---
_unit setVariable ["Waldo_deathTime", time, true];
_unit setVariable ["Waldo_deathWeapon", (if (isNull _culprit) then { "" } else { currentWeapon _culprit }), true];
_unit setVariable ["Waldo_identified", false, true];
_unit setVariable ["Waldo_roleRevealed", false, true];

if (!isNull _culprit && {_culprit != _unit}) then {
	// Count the kill toward the culprit's in-round tally (scoreboard / MVP).
	if (isPlayer _culprit) then {
		_culprit setVariable ["Waldo_roundKills", (_culprit getVariable ["Waldo_roundKills", 0]) + 1, true];
	};

	// DNA left at the scene. A traitor's armed "False Flag" frames a random
	// other living player instead (and is consumed); otherwise it's the real
	// culprit. This used to have zero observable effect for a tester who
	// didn't personally go DNA-scan the corpse afterward - the frame itself
	// worked, there was just no confirmation anywhere that it had, which read
	// as "doesn't seem to work." A private notification card to the culprit
	// (Waldo_fnc_ShowUiNotification) closes that gap.
	//
	// The pool includes the Detective again (briefly excluded - see prior
	// history) - a small lobby can easily have no living Innocent left besides
	// the victim (1 Traitor + 1 Detective + 1-2 Innocents is common), which
	// made an armed False Flag reliably report "no one was around" the moment
	// the last other Innocent died, reading as broken rather than as the game
	// running out of bystanders. The Detective being a valid frame target is
	// exactly why the DNA Scanner now calls out a self-match explicitly
	// (fn_dnaScanner.sqf) instead of just silently tracking them at 0m.
	private _dnaOn = _culprit;
	// Disguised (Waldo_fnc_disguiserActivate) - their own DNA already reads
	// as whoever they copied the loadout from, the whole point of the
	// disguise. Checked before False Flag so an armed False Flag can still
	// override it below (a deliberate one-shot frame beats the passive
	// disguise state if a Traitor somehow has both active at once).
	if (_culprit getVariable ["Waldo_disguiseActive", false]) then {
		private _disguiseAs = _culprit getVariable ["Waldo_disguiseAs", objNull];
		if (!isNull _disguiseAs) then { _dnaOn = _disguiseAs; };
	};
	if (_culprit getVariable ["Waldo_falseFlag", false]) then {
		private _frames = allPlayers select { alive _x && {!(_x in _traitors)} && {_x != _culprit} };
		if (count _frames > 0) then {
			_dnaOn = selectRandom _frames;
			[
				"STR_TIA_FalseFlag_Triggered", ["STR_TIA_FalseFlag_TriggeredBody", name _dnaOn],
				"SUCCESS", 8, "TOP_RIGHT", "FALSEFLAG", "STR_TIA_Role_Traitor"
			] remoteExec ["Waldo_fnc_ShowUiNotification", _culprit];
		} else {
			[
				"STR_TIA_FalseFlag_Failed", "STR_TIA_FalseFlag_FailedBody",
				"WARNING", 8, "TOP_RIGHT", "FALSEFLAG", "STR_TIA_Role_Traitor"
			] remoteExec ["Waldo_fnc_ShowUiNotification", _culprit];
		};
		_culprit setVariable ["Waldo_falseFlag", false, true];
	};
	_unit setVariable ["Waldo_killerDNA", _dnaOn, true];
	_unit setVariable ["Waldo_killerDNATime", time, true];
	[_unit, _dnaOn] call Waldo_fnc_dnaContaminate;

	// Also leave DNA on the gear the victim drops, so a killer who flees the body
	// still leaves a second trace nearby (tag the death weapon-holders shortly
	// after the engine spawns them).
	[_unit, _dnaOn] spawn {
		params ["_body", "_dnaOn"];
		sleep 1;
		{
			_x setVariable ["Waldo_killerDNA", _dnaOn, true];
			_x setVariable ["Waldo_killerDNATime", time, true];
			[_x, _dnaOn] call Waldo_fnc_dnaContaminate;
		} forEach (nearestObjects [_body, ["WeaponHolderSimulated", "GroundWeaponHolder"], 4]);
	};
};

// "Identify Body" scroll action on the corpse - calling it in confirms the death
// to everyone (and, if a Detective calls it, the victim's role). hideOnUse is
// FALSE and the condition checks Waldo_roleRevealed (not Waldo_identified): a
// non-Detective finding the body first must NOT consume/hide the action, or a
// Detective arriving later could never get the role reveal. It only actually
// disappears once a Detective has identified it. Added on every machine
// (JIP-safe).
[_unit, [
	["<t color='#ffd23f'>%1</t>", "STR_TIA_Action_IdentifyBody"],
	// _target/_caller are only auto-bound magic variables inside the
	// CONDITION string (below) - the STATEMENT here only ever gets them
	// through _this ([_target, _caller, _actionId, _arguments], per BI's own
	// addAction docs). Referencing _target/_caller directly without
	// extracting them first throws "Undefined variable in expression" the
	// instant the action is used - confirmed via RPT, and since SQF doesn't
	// hard-abort on an undefined-variable error, it silently continued with
	// a truncated argument array, which is what made Waldo_fnc_identifyBody
	// itself throw on _body immediately after (params ["_body", "_finder"]
	// had nothing to fill them from). An earlier version of this comment
	// argued the opposite - that was the bug, not a fix.
	{
		params ["_target", "_caller"];
		[_target, _caller] remoteExec ["Waldo_fnc_identifyBody", 2];
	},
	nil, 4, true, false, "",
	"!(_target getVariable ['Waldo_roleRevealed', false])",
	2.5
]] remoteExec ["Waldo_fnc_addActionL", 0, _unit];   // title localised per client

private _guilty = true;   // did the culprit kill someone they shouldn't have?

// Shared karma nudge - RDM and a Traitor teamkill both dock karma, just by
// very different amounts (see each call site), so the UID lookup/clamp/save
// isn't duplicated between them.
private _adjustKarma = {
	params ["_p", "_delta", "_reason"];
	private _uid = getPlayerUID _p;
	if (_uid != "") then {
		private _key = "Waldo_karma_" + _uid;
		private _k = profileNamespace getVariable [_key, 100];
		private _new = ((_k + _delta) max 0) min 100;
		profileNamespace setVariable [_key, _new];
		saveProfileNamespace;
		diag_log format ["[Waldo][server] karma: %1 %2 -> karma %3", name _p, _reason, _new];
	};
};

// Credit awards (amount per kill is the lobby "Kill Reward Credits" setting;
// detectives are paid for traitor kills and traitors for detective kills).
private _reward = missionNamespace getVariable ["Waldo_killReward", 1];
if (_victimRole == "Traitor") then {
	_guilty = false;
	if (_reward > 0) then { { _x setVariable ["points", (_x getVariable ["points", 0]) + _reward, true]; } forEach _detectives; };
};
// Once per round, not once per death: a Traitor's own Defibrillator revives
// ANY corpse onto the Traitor team, so if a Traitor revives the dead
// Detective's body it comes back as a Traitor, not a Detective, and can't
// pay this out again - but a fellow Detective (a second one, or a lobby
// where Detective survives being downed some other way) reviving them back
// to Detective could otherwise let this fire every time they're re-killed,
// paying every Traitor in full each time.
if (_victimRole == "Detective" && {!(missionNamespace getVariable ["Waldo_detectiveRewardPaid", false])}) then {
	missionNamespace setVariable ["Waldo_detectiveRewardPaid", true, true];
	if (_reward > 0) then { { _x setVariable ["points", (_x getVariable ["points", 0]) + _reward, true]; } forEach _traitors; };
};

// Civilian bonus: every Nth Innocent a Traitor kills (round-wide tally across
// the whole team, not per-killer - matches the team-wide payout style of the
// two rewards above) pays every Traitor _reward credits. Innocent only -
// Detective/Jester kills are already paid/penalised by the blocks above and
// below, and double-dipping the same kill into both would make hunting the
// Detective or the Jester the bonus-farming target instead of civilians.
if (_victimRole == "Innocent" && {_culpritRole == "Traitor"}) then {
	private _every = missionNamespace getVariable ["Waldo_civKillBonusEvery", 5];
	if (_every > 0) then {
		private _tally = (missionNamespace getVariable ["Waldo_civKillTally", 0]) + 1;
		missionNamespace setVariable ["Waldo_civKillTally", _tally, true];
		if ((_tally % _every) == 0 && {_reward > 0}) then {
			{ _x setVariable ["points", (_x getVariable ["points", 0]) + _reward, true]; } forEach _traitors;
			[
				"STR_TIA_CivBonus_Title", ["STR_TIA_CivBonus_Body", _tally, _reward],
				"SUCCESS", 8, "TOP_RIGHT", "CIVBONUS", "STR_TIA_Role_Traitor"
			] remoteExec ["Waldo_fnc_ShowUiNotification", _traitors];
		};
	};
};

// Jester clean kill: a non-Traitor player (and not self / environment) killed the Jester.
// isPlayer is required - a non-player culprit (a vehicle, an explosive/environment prop
// with no "role" variable) has _culpritRole default to "" via getVariable's safe default,
// and "" != "Traitor" was trivially true, incorrectly flagging a clean kill for any
// non-player-attributed Jester death (e.g. an unattributed explosion).
if (_victimRole == "Jester" && {!isNull _culprit} && {_culprit != _unit} && {isPlayer _culprit} && {_culpritRole != "Traitor"}) then {
	missionNamespace setVariable ["JESTERCLEANKILL", true, true];
};

// A Traitor killing the Jester is otherwise a completely free kill (line 141
// exempts every Traitor kill from the RDM/karma penalty below, since killing
// non-Traitors is literally their win condition) - but the Jester is a
// special case: killing them doesn't advance the Traitors' own win condition
// at all, it just denies the Jester the "a non-Traitor killed me" win they're
// otherwise going for. Docking the same amount a correct kill would have
// earned keeps it a real cost instead of a shrug.
if (_victimRole == "Jester" && {_culpritRole == "Traitor"} && {!isNull _culprit} && {_culprit != _unit}) then {
	private _floor = missionNamespace getVariable ["Waldo_jesterKillFloor", 1];
	private _before = _culprit getVariable ["points", 0];
	// Strips the culprit down to the floor, not a fixed deduction - takes
	// basically everything they'd banked regardless of how much that was,
	// rather than a flat number a well-stocked Traitor could shrug off. min,
	// not max: never GRANTS credits to a culprit already below the floor,
	// only ever takes from someone above it - see the lobby param's own
	// comment in description.ext for why the floor defaults to Radar's cost.
	private _after = _before min _floor;
	_culprit setVariable ["points", _after, true];
	private _lost = _before - _after;
	[
		"STR_TIA_JesterKill_Title",
		[["STR_TIA_JesterKill_BodyMany", "STR_TIA_JesterKill_BodyOne"] select (_lost == 1), _lost, _after],
		"WARNING", 8, "TOP_RIGHT", "JESTERPENALTY", "STR_TIA_Role_Traitor"
	] remoteExec ["Waldo_fnc_ShowUiNotification", _culprit];
};

// Traitor-on-Traitor teamkill: friendly fire between two people who already
// know each other's role, not a mystery-breaking mistake like real RDM - so
// it's a real cost, just a much smaller one than the RDM block below on both
// credits and karma. This used to be completely free: the blanket
// "_culpritRole == Traitor -> not guilty" line right after this exempted it
// from the RDM karma check entirely, with no credit penalty anywhere either.
if (_victimRole == "Traitor" && {_culpritRole == "Traitor"} && {!isNull _culprit} && {_culprit != _unit}) then {
	private _penalty = missionNamespace getVariable ["Waldo_traitorTeamkillPenalty", 2];
	private _before = _culprit getVariable ["points", 0];
	private _after = _before;
	if (_penalty > 0) then {
		_after = (_before - _penalty) max 0;
		_culprit setVariable ["points", _after, true];
	};
	private _lost = _before - _after;
	[
		"STR_TIA_TeamKill_Title",
		[["STR_TIA_TeamKill_BodyMany", "STR_TIA_TeamKill_BodyOne"] select (_lost == 1), name _unit, _lost, _after],
		"WARNING", 8, "TOP_RIGHT", "TRAITORTK", "STR_TIA_Role_Traitor"
	] remoteExec ["Waldo_fnc_ShowUiNotification", _culprit];
	if (missionNamespace getVariable ["KarmaEnabled", true]) then {
		[_culprit, -10, "teamkilled a fellow Traitor"] call _adjustKarma;
	};
};

// Killing as a Traitor is never "guilty".
if (_culpritRole == "Traitor") then { _guilty = false; };

// Karma: a non-Traitor killed a teammate (innocent/detective/jester) -> RDM.
if ((missionNamespace getVariable ["KarmaEnabled", true]) && {_guilty} && {!isNull _culprit} && {_culprit != _unit} && {isPlayer _culprit}) then {
	[_culprit, -30, "RDM'd"] call _adjustKarma;
};
