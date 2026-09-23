//////////////////////////////////////////////////////////////////
// Waldo_fnc_initClient
// CLIENT: per-player setup. Gated on Waldo_configReady and uses nil-safe
// reads throughout so it can never abort part-way (the old init threw on
// nil mapDone/gameOn during JIP/fast restarts, which is why "scripts failed
// to kick in" on repeat). Emits [Waldo][client] phase markers.
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};   // dedicated server / headless: nothing to do

// Damage off from the very first executable line, before anything else runs.
// The player unit already exists in the world by the time this script starts
// (wherever mission.sqm happened to place them, possibly in water, possibly
// overlapping another unit, on a terrain those coordinates were never
// checked against), and the holding-position relocation below still has two
// waitUntils to clear before it can move them. Without this, that whole gap
// is a window where a bad spawn point can actually hurt or kill someone
// before the mission gets a chance to move them anywhere.
player allowDamage false;

// The engine's own built-in scoreboard shows raw kill/death attribution,
// which would hand out exactly the hidden information this whole gamemode
// is built around (who killed whom, at a glance) outside of any of the
// mission's own investigation mechanics. Locked out entirely - only the
// mission's own scoreboard (K, Waldo_fnc_scoreboard) is meant to exist.
// showScoretable takes a NUMBER (1 force-visible, 0 force-invisible, -1
// default), not a Bool - passing false here threw "Type Bool, expected
// Number" and aborted the rest of this script outright (confirmed via RPT:
// nothing after this line ran - no teleport, no HUD, no key bindings,
// nothing), which is exactly the regression this caused in production.
showScoretable 0;

private _logPhase = {
	params ["_phase"];
	diag_log ("[Waldo][client] phase: " + _phase);
	if (missionNamespace getVariable ["TestingFlag", false]) then { systemChat ("[Waldo] " + _phase); };
};

waitUntil { !isNull player };

// "How To Play" map-screen diary - static content, no round/role dependency,
// so it's available to read from the moment a player connects.
[] call Waldo_fnc_setupBriefing;

// Wait for the server to publish config (modpack + params) before reading it.
waitUntil { missionNamespace getVariable ["Waldo_configReady", false] };
["config-ready"] call _logPhase;

// Move off whatever mission.sqm happened to place us at - only ever valid on
// the one terrain a mission was saved on - onto a runtime-picked safe spot
// (Waldo_fnc_selectHoldingPos), so the same mission works on Altis, Tanoa,
// Stratis, Livonia, or anywhere else. findEmptyPosition scatters each client
// around it so up to 128 players don't clip into each other or the terrain
// while they wait for the real arena.
waitUntil { !((missionNamespace getVariable ["Waldo_holdingPos", []]) isEqualTo []) };
private _hold = missionNamespace getVariable ["Waldo_holdingPos", [0,0,0]];
private _holdSafe = _hold findEmptyPosition [0, 40];
if (_holdSafe isEqualTo []) then { _holdSafe = _hold; };
player setPos _holdSafe;
["holding-pos"] call _logPhase;

// If a round is already live when we arrive (JIP), we don't belong in it.
if (missionNamespace getVariable ["gameOn", false]) then { player setDammage 1; };

// --- Spawn loadout ---
player setVariable ["tested", false, true];
player setVariable ["player", player, true];
// local: 3 keyed activation slots (Y/U/J) + an overflow backlog for anything
// bought beyond 3 activation items at once (see Waldo_fnc_buyItem /
// Waldo_fnc_useActivationSlot / Waldo_fnc_assignActivationSlot).
player setVariable ["Waldo_activationSlots", [-1, -1, -1]];
player setVariable ["Waldo_activationBacklog", []];
player setVariable ["Waldo_purchaseSeq", 0];   // next unique Waldo_purchases id

[] call Waldo_fnc_applySpawnLoadout;
player allowDamage false;

waitUntil { !isNull player && time > 0 };

// --- Pregame: wait until the arena is built ---
[] call Waldo_fnc_pregameScreen;
["arena-ready"] call _logPhase;

// Warmup "Selecting Roles" bar (same top-bar casing/position as the round
// timer): mapDone is already true by the time Waldo_fnc_pregameScreen
// returns, which is exactly the window the server's own warmup loop
// (Waldo_fnc_initServer) is running in - no extra readiness gating needed.
[] spawn Waldo_fnc_warmupBar;

// Intro music. Deliberately triggered HERE rather than right after spawn: an
// elapsed-time heuristic (however generous) can never fully guarantee the
// client isn't still on a loading screen, which is why this was intermittent
// rather than reliably broken - time > 0 (or even time > 3) can already be
// true well before the audio engine is necessarily ready. Waldo_fnc_pregameScreen
// just spent however long the arena took to build actively looping a hint
// refresh every 0.25s on THIS client - by the time it returns, this client
// has provably been running SQF and updating the screen the whole time, not
// stuck loading. Skipped if the round already went live (a JIP mid-round
// shouldn't restart the intro); logged either way so a silent failure shows
// up in the .rpt instead of being another guess.
//
// _musicStarted is recorded (see the fadeMusic call near the end of this
// script) so the fade-out below can be skipped entirely for a JIP client
// that never started the music in the first place.
//
// 0 fadeMusic 1 first: fadeMusic sets an engine-level "scripted volume"
// multiplier (final volume = client's own Music slider * this), and it is
// NOT track-specific or reset by playMusic - it just stays wherever the
// LAST fadeMusic call left it. This mission restarts a fresh round (and
// calls playMusic again) many times in the same server session, and
// fn_initClient.sqf's own fade-out at round-live (`6 fadeMusic 0;`, near
// the end of this script) leaves that multiplier at 0 - silently muting
// every playMusic call for the rest of the server's life (this round's MVP
// replay, Waldo_fnc_mvpCelebrate, and every later round's intro alike) with
// zero indication anywhere that it happened, since playMusic itself still
// resolves and logs cleanly. Resetting to 1 (instantly, duration 0) right
// before playing is what actually guarantees this is audible.
// Waldo_roundLiveAt is 0 during pregame and holds the just-ended round's
// `time` value for a short window after fn_endRound.sqf flips gameOn false
// (fn_resetState.sqf doesn't zero it again until the NEXT round's setup) -
// so `!gameOn` alone doesn't distinguish "haven't started the round yet"
// from "round just ended, MVP celebration is playing its own music right
// now". If THIS client's fn_initClient somehow re-runs during that window
// (e.g. a respawn/JIP landing exactly then), the old code would fire a
// second playMusic on top of Waldo_fnc_mvpCelebrate's broadcast one -
// audibly overlapping tracks. Remembering which Waldo_roundLiveAt value
// already got its intro music (local to this client, not broadcast) closes
// that window while still playing fresh intro music every real round, since
// that value is different (0, then a new `time`) each time.
private _musicStarted = false;
private _liveAt = missionNamespace getVariable ["Waldo_roundLiveAt", 0];
private _introPlayedFor = missionNamespace getVariable ["Waldo_introMusicPlayedFor", -1];
if (!(missionNamespace getVariable ["gameOn", false]) && {_liveAt != _introPlayedFor}) then {
	0 fadeMusic 1;
	playMusic ["TTTIntroMusic", 20];
	_musicStarted = true;
	missionNamespace setVariable ["Waldo_introMusicPlayedFor", _liveAt];
	diag_log "[Waldo][client] intro music: playMusic issued";

	// Independent safety valve, same idea as the ace_medical_deathBlocked
	// watchdog further down this file: the single `0 fadeMusic 1;` right
	// above is a one-shot reset, issued once, the instant BEFORE playMusic
	// - it does nothing to protect the track for the rest of the intro
	// window if anything else (another mod's own periodic fadeMusic call,
	// same class of interference ACE's hearing module already needed an
	// opt-out for; a JIP client's fn_initClient re-running mid-window; or
	// anything not yet identified) drags the multiplier back down to 0
	// sometime AFTER that single reset but before the round actually goes
	// live. Rather than trying to enumerate every possible culprit, this
	// just keeps re-asserting fadeMusic 1 once a second for as long as the
	// intro is supposed to be audible, and stops on its own the moment
	// gameOn flips true - the round-live fade-out below is deliberate and
	// must not be fought by this loop, so it only ever runs during the
	// pregame/holding window, never after.
	[] spawn {
		while { !(missionNamespace getVariable ["gameOn", false]) } do {
			0 fadeMusic 1;
			sleep 1;
		};
	};
} else {
	diag_log "[Waldo][client] intro music: skipped, round already live (JIP) or already played for this round";
};

// WMP notification-card system (functions/uinotify/, vendored from
// WaldosMissionPack): the "clear stuck UI" safety valve. Safe/idempotent to
// call every init - it no-ops if already installed.
[] call Waldo_fnc_SetupUiCleanupAction;

// Obscure nametags (ACE)
ACE_NO_RECOGNIZE = true; publicVariable "ACE_NO_RECOGNIZE";

// Role-reveal 3D icons
[] call Waldo_fnc_drawRoleIcons;

// Keep alive/dead text chat from crossing over (Global/Side/Command/Group
// are shared channels regardless of role, so without this a dead player can
// feed information to whoever's still playing).
[] call Waldo_fnc_setupDeadChatFilter;

// --- Teleport into the arena ---
private _center = missionNamespace getVariable ["mapPos", [0,0,0]];
private _radius = missionNamespace getVariable ["mapRadius", 50];
private _dist = _radius * 0.9;
player setPos _center;
private _pos = [
	(_center select 0) - (_dist / 2) + random _dist,
	(_center select 1) - (_dist / 2) + random _dist,
	0
];
private _dir = _pos getDir _center;
private _empty = _pos findEmptyPosition [0, 25];
if !(_empty isEqualTo []) then { _pos = _empty; };
player setPos _pos;
player setDir _dir;
player allowDamage false;
["teleported"] call _logPhase;

// Keep the player inside the arena (single managed loop)
[_pos, _dir, _radius, _center] call Waldo_fnc_confineToArena;

// Title screen
[] call Waldo_fnc_titleSequence;

// --- Install the buy-menu / activation / holster key handler ONCE ---
// Add-only; we never displayRemoveAllEventHandlers (that thrash used to
// break the B key). B = buy menu, Y/U/J = use activation item slot 1/2/3,
// L = holster.
[] spawn {
	waitUntil { !isNull (findDisplay 46) };
	private _disp = findDisplay 46;
	if (isNil { _disp getVariable "Waldo_keyEH" }) then {
		// KeyDown fires repeatedly (OS key-repeat) for as long as a key stays
		// physically down, not once per press - without this guard, holding T
		// spams dozens of pings and holding any other bound key re-fires its
		// action every repeat tick. Track which of our bound keys are currently
		// held and ignore repeats until KeyUp clears them.
		_disp setVariable ["Waldo_heldKeys", []];
		private _eh = _disp displayAddEventHandler ["KeyDown", {
			params ["_d", "_key"];
			private _held = _d getVariable ["Waldo_heldKeys", []];
			if (_key in _held) exitWith { false };
			_held pushBack _key;
			_d setVariable ["Waldo_heldKeys", _held];
			private _handled = false;
			switch (_key) do {
				case 48: {   // B - open buy menu
					private _role = player getVariable ["role", "Innocent"];
					if (_role in ["Traitor", "Detective"]) then {
						// openBuyMenu waitUntils on its dialog existing after createDialog -
						// same reasoning as the debug menu below: never rely on that check
						// happening to pass on its very first tick when called unscheduled.
						[_role] spawn Waldo_fnc_openBuyMenu;
						_handled = true;
					};
				};
				case 21: {   // Y - use the activation item bound to slot 1
					[0] call Waldo_fnc_useActivationSlot;
					_handled = true;
				};
				case 22: {   // U - use the activation item bound to slot 2
					[1] call Waldo_fnc_useActivationSlot;
					_handled = true;
				};
				case 36: {   // J - use the activation item bound to slot 3
					[2] call Waldo_fnc_useActivationSlot;
					_handled = true;
				};
				case 38: {   // L - holster / lower weapon
					[] call Waldo_fnc_holster;
					_handled = true;
				};
				case 20: {   // T - hold to open the ping picker (traitors only); release fires it
					if ((player getVariable ["role", ""]) == "Traitor") then {
						// pingWheelOpen waitUntils on its overlay existing the first time it's
						// created - needs a scheduled context, same reason debugMenu does above.
						[] spawn Waldo_fnc_pingWheelOpen;
						_handled = true;
					};
				};
				case 26: {   // [ - open the dev/test menu (only under Testing Mode)
					// Was bound to \ (DIK 43); moved here because \ has a history of
					// colliding with a default Arma keybind and never reliably reaching
					// this handler at all, unlike every other key bound in this switch.
					if (missionNamespace getVariable ["TestingFlag", false]) then {
						// debugMenu waitUntils on the dialog existing after createDialog -
						// waitUntil needs a scheduled environment same as sleep does, and
						// this KeyDown handler is unscheduled, so `call` threw here every
						// time (the actual reason the menu never opened).
						[] spawn Waldo_fnc_debugMenu;
					} else {
						// Silent no-op otherwise looks identical to a broken key - tell the
						// player WHY nothing happened instead of leaving them guessing.
						hint localize "STR_TIA_Dev_TestingOff";
					};
					_handled = true;
				};
				case 27: {   // right-bracket key - instant role cycle (Testing Mode only)
					if (missionNamespace getVariable ["TestingFlag", false]) then {
						call Waldo_debugCycleRole;
					} else {
						hint localize "STR_TIA_Dev_TestingOff";
					};
					_handled = true;
				};
				case 35: {   // H - open the role crest style picker (previews, click to pick)
					// createDialog + waitUntil needs a scheduled environment, same
					// reason the debug menu above is spawned rather than called - this
					// KeyDown handler itself is unscheduled. The picker writes the
					// choice straight to profileNamespace (not missionNamespace/player
					// variables): a purely personal, client-side display preference,
					// the same kind of thing as a keybind or a graphics setting - it
					// has no gameplay effect, no server ever overrides it, and no
					// other player should ever see or be affected by it.
					[] spawn Waldo_fnc_openStylePicker;
					_handled = true;
				};
			};
			_handled
		}];
		private _ehUp = _disp displayAddEventHandler ["KeyUp", {
			params ["_d", "_key"];
			private _held = _d getVariable ["Waldo_heldKeys", []];
			_d setVariable ["Waldo_heldKeys", _held - [_key]];
			if (_key == 20) then { [] call Waldo_fnc_pingWheelClose; };   // T released - fire the highlighted ping
			false
		}];
		_disp setVariable ["Waldo_keyEH", _eh];
		_disp setVariable ["Waldo_keyEHUp", _ehUp];
	};
};

// --- K - toggle the in-round scoreboard, on EVERY open display, not just
// display 46. "KeyDown"/"KeyUp" are DISPLAY event handlers, not Mission
// event handlers - addMissionEventHandler ["KeyDown", ...] throws "Unknown
// enum value: KeyDown" outright (confirmed via RPT) and aborted the rest of
// this entire script, which is exactly why nothing after this point was
// working (HUD, MPKilled handling, the Jester damage guards, everything).
// Mission event handlers simply don't cover key input at all.
//
// The actual problem this was trying to solve is real, though: every other
// key above only makes sense on display 46 (the alive/in-round HUD:  buy
// menu, activation items, ping wheel), but the vanilla "Spectator" respawn
// template opens its own separate display while dead, which never has
// focus on display 46, so a display-46-only handler never sees a spectator's
// K press. Rather than hardcode the Spectator display's IDD (undocumented
// and liable to change), this polls allDisplays once a second and attaches
// the handler to every display that doesn't already have one - covers
// display 46, the Spectator display, and anything else, self-healing as
// displays open and close, with a per-display guard so nothing double-fires.
[] spawn {
	while { true } do {
		{
			if (isNil { _x getVariable "Waldo_scoreboardKeyEH" }) then {
				_x setVariable ["Waldo_scoreboardKeyHeld", false];
				private _sbEh = _x displayAddEventHandler ["KeyDown", {
					params ["_d", "_key"];
					if (_key == 37 && {!(_d getVariable ["Waldo_scoreboardKeyHeld", false])}) then {
						_d setVariable ["Waldo_scoreboardKeyHeld", true];
						[] spawn Waldo_fnc_scoreboard;
					};
					false
				}];
				private _sbEhUp = _x displayAddEventHandler ["KeyUp", {
					params ["_d", "_key"];
					if (_key == 37) then { _d setVariable ["Waldo_scoreboardKeyHeld", false]; };
					false
				}];
				_x setVariable ["Waldo_scoreboardKeyEH", [_sbEh, _sbEhUp]];
			};
		} forEach allDisplays;
		sleep 1;
	};
};

// --- Wait for the round to go live ---
waitUntil { missionNamespace getVariable ["gameOn", false] };

player allowDamage true;

// HUD (role badge + live credits). This is the moment a player's role is
// actually revealed to them - the intro music should die right here, not on
// some fixed delay afterward, so fade it out gently as the badge appears
// instead of leaving it running under the round proper.
//
// Logged on both sides of the call (not just "issued"): fadeMusic itself
// never throws and never reports failure, so a diag_log placed only before
// it would look identical whether the ramp actually engaged or not. Having
// both lines land in the .rpt confirmed the call was reached and returned -
// and a live dedicated-server test with ACE loaded still had the track
// playing at full volume for the rest of the round regardless. Root cause:
// ACE's hearing module periodically calls fadeMusic itself to duck music
// under hearing damage/suppression, fighting this call every time it fired.
// init.sqf now sets ace_hearing_disableVolumeUpdate = true so ACE leaves
// fadeMusic alone and this call actually takes effect.
if (_musicStarted) then {
	diag_log "[Waldo][client] intro music: fade-out issued (6 fadeMusic 0)";
	6 fadeMusic 0;
	diag_log "[Waldo][client] intro music: fade-out call returned";
} else {
	diag_log "[Waldo][client] intro music: fade-out skipped, music never started";
};

[] call Waldo_fnc_initHud;
["round-live"] call _logPhase;

// Top bar round-timer loop: started exactly once here (never from
// fn_initHud.sqf, which re-runs on every respawn/role change) - gameOn is
// already confirmed true by the waitUntil above, so Waldo_startTime/timelimit
// are already broadcast too; no extra readiness gating needed.
[] spawn Waldo_fnc_topBarTimer;

// --- Kill handling (server-authoritative logic lives in Waldo_fnc_onKilled) ---
player addMPEventHandler ["MPKilled", {
	params ["_unit"];
	_this call Waldo_fnc_onKilled;
	// Nothing clears a hint/hintSilent on death - a scanner readout, "Reviving...",
	// "Charge armed", whatever happened to be up at the moment of death, was
	// otherwise left on screen bleeding into the Spectator view with no way to
	// dismiss it. Waldo_fnc_ClearUiPanels covers the same thing for every tool
	// now on the notification system (functions/uinotify/) - without it, a
	// card like DNA_TRACK or REVIVE would just sit there on its own duration
	// timer, the exact bleed-into-Spectator bug this was already guarding
	// against for the old hint/hintSilent channel.
	if (_unit == player) then { hint ""; hintSilent ""; [] call Waldo_fnc_ClearUiPanels; };
}];

// Dead Ringer guard: while armed (Waldo_fnc_deadRinger sets Waldo_deadRingerArmed),
// a hit that would be fatal is capped instead of killing, and
// Waldo_fnc_deadRingerTrigger sells the fake death.
//
// A dead unit cannot be undone - setDamage cannot resurrect someone once
// Killed/MPKilled has fired, so "correct it afterward" (the watchdog inside
// the Jester branch below) only helps against damage that DOESN'T kill in
// one shot, e.g. a DoT tick reapplying more on the next frame. It does
// NOTHING against a single lethal hit that this handler's own return value
// never got to arbitrate in the first place - and per BI's own docs on
// HandleDamage, "only the return value of the LAST added HandleDamage EH is
// considered." If another mod adds its own HandleDamage EH to this unit
// AFTER this one (ACE Medical does, as part of its own init), that one
// becomes authoritative instead, silently, with no way for us to know it
// happened - our 0 would just never be the value the engine actually used,
// and a Jester's "harmless" hit could be genuinely lethal.
//
// So this doesn't just install the handler once: Waldo_fnc_installDamageEH
// removes and re-adds it, which is how you become the LAST added EH again.
// Called once immediately, then re-called every 3s for as long as this life
// is alive (removeEventHandler + addEventHandler is a cheap list operation,
// not a per-frame cost, so there's no real reason to leave a wider window
// open than that) - closing the window to at most ~3s after whatever mod
// last raced us for the position, rather than leaving it open for an
// entire life. ACE (and anything else) sets its own handler up once during
// its own addon init and never refights for last position afterward, so in
// practice this wins the race back within one cycle of losing it, not
// eventually.
Waldo_fnc_installDamageEH = {
	private _old = player getVariable ["Waldo_damageEHId", -1];
	if (_old >= 0) then { player removeEventHandler ["HandleDamage", _old]; };
	private _new = player addEventHandler ["HandleDamage", {
		params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator"];
		// Track the last real (non-null, non-self) damager independent of the Dead Ringer
		// check below - ACE bleed-out/DoT damage ticks can hit this handler with a null
		// _instigator, and by the time the terminal MPKilled event fires its own
		// killer/instigator can likewise resolve to null or to the victim themselves, even
		// though a real player caused the damage that led to death. Waldo_fnc_onKilled falls
		// back to this when MPKilled's own attribution comes up empty.
		if (!isNull _instigator && {_instigator != _unit}) then {
			_unit setVariable ["Waldo_lastDamager", _instigator, true];
			// Someone OTHER than the Jester is now responsible for whatever happens
			// to this unit next - if a Jester-triggered ace_medical_deathBlocked
			// (below) were still up, clear it immediately so a legitimate killer's
			// hit is never silently no-op'd by residual Jester-graze protection.
			// Checked here, synchronously, on EVERY hit (not just Jester ones) -
			// per BI's own docs every added HandleDamage EH still runs even when
			// its return value doesn't win, so this side effect fires reliably
			// regardless of which handler's return was actually used, and a
			// genuine attacker's damage must never be at the mercy of a polling
			// loop's next tick instead.
			if ((_instigator getVariable ["role", ""]) != "Jester" && {_unit getVariable ["ace_medical_deathBlocked", false]}) then {
				_unit setVariable ["ace_medical_deathBlocked", false];
			};
		};
		// Any damage while armed triggers it now, not just a near-lethal hit - and
		// the return is 0, not a 0.9 cap: Waldo_fnc_deadRingerTrigger now
		// teleports the real unit away entirely rather than leaving them ragdolled
		// in place, so "you weren't actually there" means no damage at all, not a
		// reduced amount (a 0.9 cap on a graze that would've only done 0.05 in the
		// first place used to make a minor hit WORSE).
		if ((_unit getVariable ["Waldo_deadRingerArmed", false]) && {_damage > 0}) then {
			[_unit] call Waldo_fnc_deadRingerTrigger;
			0
		} else {
			// Jester deals (essentially) no damage. The Fired EH in
			// Waldo_fnc_makeJester deletes their bullets/thrown munitions
			// before they connect, but that only covers stuff that actually
			// fires a projectile - melee (bare fists, and modded melee like
			// SOG Prairie Fire's knives) hits here directly with no Fired
			// event ever raised, so it was going straight through. This is
			// the universal backstop: whatever the mechanism, if the
			// instigator is the Jester, damage is capped here.
			//
			// Capped, not hard-zeroed: a hit that visibly connects but does
			// exactly 0 damage is a dead giveaway the instant anyone tests
			// it twice ("this person literally can't be hurt" reads very
			// differently from "I got lucky/grazed that hit"). The actual
			// requirement is "cannot kill," not "cannot be felt" - so a
			// small, real fraction of the proposed damage is allowed
			// through (WALDO_JESTER_SAFE_FLOOR below is the hard ceiling on
			// how far that can ever push the victim's OVERALL damage, so
			// stacking hits still can't add up to lethal).
			if (!isNull _instigator && {_instigator != _unit} && {(_instigator getVariable ["role", ""]) == "Jester"}) then {
				private _safeFloor = 0.85;   // never below ~15% health from Jester hits alone
				private _preHit = damage _unit;
				private _visible = (_damage * 0.2) min ((_safeFloor - _preHit) max 0);
				// Second-layer backstop for anything that still gets past the
				// capped return above WITHOUT being an outright single
				// lethal hit - a DoT tick from the same attack reapplying
				// damage a moment later, for instance. Starts (or refreshes,
				// on a repeat hit) a short watchdog that force-corrects the
				// unit's damage back down to the same safe floor for the
				// next 1.5s (not the pre-hit baseline - that would erase the
				// small, deliberate graze this is supposed to leave
				// visible). setDamage does not itself trigger HandleDamage,
				// so this can't recurse into itself - but it cannot save a
				// unit that died in the same synchronous hit this return
				// value lost arbitration on, which is exactly why staying
				// the LAST-added EH (above) is the real defence, not this.
				_unit setVariable ["Waldo_jesterGuardUntil", time + 1.5];
				if (isNil { _unit getVariable "Waldo_jesterGuardRunning" }) then {
					_unit setVariable ["Waldo_jesterGuardRunning", true];
					[_unit, _safeFloor] spawn {
						params ["_u", "_floor"];
						while { alive _u && {time < (_u getVariable ["Waldo_jesterGuardUntil", 0])} } do {
							if ((damage _u) > _floor) then {
								_u setDamage _floor;
							};
							sleep 0.05;
						};
						_u setVariable ["Waldo_jesterGuardRunning", nil];
					};
				};
				_visible
			} else {
				_damage
			}
		}
	}];
	player setVariable ["Waldo_damageEHId", _new];
};
[] call Waldo_fnc_installDamageEH;
[] spawn {
	while { alive player } do {
		sleep 3;
		if (alive player) then { [] call Waldo_fnc_installDamageEH; };
	};
};

// ACE Medical cooperative layer: ACE's OWN docs are explicit that another
// mod/mission adding its own HandleDamage EH "is virtually guaranteed to
// break ACE's handling" - so fighting for last-added position (above) isn't
// just imperfect against ACE specifically, it's the one thing ACE says not
// to do. Rather than trying to detect "is ACE Medical actually active" and
// branch (its medical level is a runtime CBA setting, not something safe to
// infer from whether the addon is merely loaded), this hooks ACE's own
// ace_medical_woundReceived CBA event - fired with the shooter already
// resolved, no attribution guessing needed - whenever the shooter is the
// Jester.
//
// This does NOT fully heal the wound (an earlier version of this did, and
// it looked exactly as suspicious as it sounds - a real injury that just
// vanishes a second later is as much a tell as taking no damage at all).
// Instead it sets ace_medical_deathBlocked, a documented ACE variable that
// stops ACE's OWN medical simulation from being able to kill this unit,
// without touching the wound/bleeding/pain it already registered - the
// injury looks and plays out like a real, survived hit, while ACE's own
// gradual bleed-out/critical-condition check simply can't end this life
// while it's set.
//
// ace_medical_deathBlocked is coarse - it blocks ANY death, not just a
// Jester-caused one - so leaving it set for a flat few seconds regardless
// of what happens next would let a Traitor's genuinely lethal hit on the
// same, recently-grazed victim get silently no-op'd too. Instead of a flat
// timer, this polls (Waldo_lastDamager, tracked on every hit above,
// regardless of which HandleDamage EH's return value actually won) and
// drops the block the INSTANT someone other than the Jester becomes the
// most recent damager - the synchronous check in the HandleDamage EH above
// already covers the common case immediately; this loop is the backstop
// for anything that lands between polls, capped at a hard 6s so it can
// never get stuck up regardless.
//
// This runs ADDITIONALLY to the HandleDamage EH above, not instead of it:
// if ACE Medical isn't actually intercepting damage (disabled, or the addon
// merely present), this whole block silently never fires and the
// HandleDamage EH remains the sole, correct defence. Every ACE symbol is
// isNil-checked before use - this must never hard-error if a future ACE
// version renames something.
if (!isNil "CBA_fnc_addEventHandler") then {
	["ace_medical_woundReceived", {
		params ["_woundedUnit", "_allDamages", "_shooter"];
		if (
			_woundedUnit == player
			&& {!isNull _shooter}
			&& {_shooter != _woundedUnit}
			&& {(_shooter getVariable ["role", ""]) == "Jester"}
		) then {
			_woundedUnit setVariable ["ace_medical_deathBlocked", true];
			if (isNil { _woundedUnit getVariable "Waldo_jesterAceGuardRunning" }) then {
				_woundedUnit setVariable ["Waldo_jesterAceGuardRunning", true];
				[_woundedUnit] spawn {
					params ["_u"];
					private _deadline = time + 6;
					while {
						time < _deadline
						&& {alive _u}
						&& {
							private _last = _u getVariable ["Waldo_lastDamager", objNull];
							!isNull _last && {(_last getVariable ["role", ""]) == "Jester"}
						}
					} do {
						sleep 0.2;
					};
					_u setVariable ["ace_medical_deathBlocked", false];
					_u setVariable ["Waldo_jesterAceGuardRunning", nil];
				};
			};
		};
	}] call CBA_fnc_addEventHandler;
};

// Independent safety valve for ace_medical_deathBlocked: everything above
// already clears it (synchronously, the instant a non-Jester attacker takes
// over; and via a polling loop hard-capped at 6s), but both of those live
// inside the SAME code path that set it - if that spawned script were ever
// interrupted (a disconnect, an unrelated error mid-loop), nothing else
// would ever clear the flag, and the affected unit would stay permanently
// un-killable through ACE's medical system for the rest of the round. This
// loop doesn't trust any of that: it watches the flag's OWN state directly,
// with its own separate timer, and force-clears it once it's been
// continuously true for more than 10s, regardless of what set it, why, or
// whether anything else was supposed to be handling it. A blanket
// "can't die at all" flag getting stuck is exactly the kind of unintended
// consequence this must never allow.
[] spawn {
	private _blockedSince = -1;
	while { true } do {
		if (alive player) then {
			if (player getVariable ["ace_medical_deathBlocked", false]) then {
				if (_blockedSince < 0) then { _blockedSince = time; };
				if ((time - _blockedSince) > 10) then {
					player setVariable ["ace_medical_deathBlocked", false];
					_blockedSince = -1;
				};
			} else {
				_blockedSince = -1;
			};
		} else {
			_blockedSince = -1;
		};
		sleep 2;
	};
};

// ACE unconscious -> death (this TTT ruleset has no downed/incapacitated state
// - going unconscious always means dead), EXCEPT a unit currently faking its
// death via Dead Ringer (an in-progress fake death must not get overwritten
// by a real one).
//
// The Jester used to be excluded here too, on the theory that a source-less
// setDamage would wipe the "who killed me" attribution the Jester win
// depends on - but that's not actually true, and excluding them was itself
// the bug: a Jester who got shot just sat unconscious in limbo instead of
// ever actually dying (no round-timer extension, no JESTERCLEANKILL, no win
// check ever seeing them as dead - reported live as "people are going ACE
// unconscious without dying outright"). Waldo_fnc_onKilled already has a
// fallback for exactly a source-less/self-attributed death: it uses
// Waldo_lastDamager (tracked on every hit by the HandleDamage EH below,
// independent of how the unit actually dies) whenever _instigator/_killer
// comes up null or resolves to the victim - which a plain `setDamage 1` from
// this very script always would. So attribution was never actually at risk;
// the exclusion just meant the Jester never got that fallback used at all,
// because they never generated a MPKilled event in the first place.
//
// TWO redundant triggers, because a single CBA event handler was unreliable:
//   1. The old handler ignored _state entirely, so it fired identically
//      whether a unit went UNCONSCIOUS or RECOVERED - it could re-kill someone
//      the instant they woke back up. Now gated on _state (only the "went
//      unconscious" edge) and restricted to the unit's OWN machine
//      (_unit == player) - calling setDamage locally on the affected player's
//      machine is more reliable than every client reacting to the same
//      broadcast event and racing to remote-kill the same unit.
//   2. A local watchdog backstop using the ENGINE's own lifeState (not an
//      ACE-internal variable name, which risks not matching ACE's actual
//      implementation) - catches a unit stuck INCAPACITATED if the event is
//      ever missed, or doesn't fire at all under a given ACE medical setting.
[] spawn {
	// CBA (and therefore ACE) is no longer treated as a hard requirement -
	// this hook is purely additive on top of the lifeState watchdog below,
	// which already catches the same case without either mod loaded.
	if (!isNil "CBA_fnc_addEventHandler") then {
		["ace_unconscious", {
			params ["_unit", "_state"];
			private _protected = _unit getVariable ["Waldo_deadRingerTriggered", false];
			if (_state && {_unit == player} && {!_protected}) then { player setDamage 1; };
		}] call CBA_fnc_addEventHandler;
	};

	while { true } do {
		private _protected = player getVariable ["Waldo_deadRingerTriggered", false];
		if (alive player && {lifeState player == "INCAPACITATED"} && {!_protected}) then { player setDamage 1; };
		sleep 2;
	};
};
