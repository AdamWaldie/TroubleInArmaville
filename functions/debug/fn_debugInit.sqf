//////////////////////////////////////////////////////////////////
// Waldo_fnc_debugInit   (preInit = 1, runs on EVERY machine)
// Builds the extensible dev/test action registry and the small runtime API the
// menu (Waldo_fnc_debugMenu) and console use. Nothing here has any effect
// unless "Enable Testing Mode" (TestingFlag) is on.
//
// ── EXTENDING ────────────────────────────────────────────────────────────────
// Register a tool from anywhere that runs at preInit on every machine (this
// file, or a future module's own preInit) so the registry — and therefore the
// action indices — line up on all machines:
//
//   ["Category", "Label", "Tooltip", "local"|"server", { /* _this = actor */ }]
//     call Waldo_debugRegister;
//
//   • "local"  code runs on the clicking client   (_this = player).
//   • "server" code is dispatched to the server by index and run there with the
//     clicking unit as _this, keeping authoritative state (roles, lists,
//     timers) correct.
//   • The menu renders entries grouped by Category, in Waldo_debugCatOrder;
//     unlisted categories are appended in first-seen order.
//
// That single call is the whole extension surface — no UI, dispatch or
// description.ext edits are ever needed to add a test operation.
//////////////////////////////////////////////////////////////////

if (isNil "Waldo_debugRegistry") then { Waldo_debugRegistry = []; };

// Category render order (unlisted categories appended after these).
Waldo_debugCatOrder = [
	"Roles", "Loadout & Shops", "Abilities", "Test Dummies", "Simulated Players",
	"Round Flow", "Arena & World", "Karma & Sim", "Player", "Diagnostics", "Menu"
];

// ── Registration API ─────────────────────────────────────────────────────────
Waldo_debugRegister = {
	params ["_cat", "_label", "_tip", "_ctx", "_code"];
	Waldo_debugRegistry pushBack [_cat, _label, _tip, _ctx, _code];
	(count Waldo_debugRegistry) - 1
};

// Run registry entry _idx for the local player. Local entries run here; server
// entries hop to the server (which re-validates by index). Used by the menu
// buttons and the console helper alike.
Waldo_debugDispatch = {
	params ["_idx"];
	if (_idx < 0 || {_idx >= count Waldo_debugRegistry}) exitWith {};
	(Waldo_debugRegistry select _idx) params ["", "", "", "_ctx", "_code"];
	if (_ctx == "server") then {
		[player, _idx] remoteExec ["Waldo_fnc_debugExec", 2];
	} else {
		player call _code;
	};
};

// Console helper for scripted testing from the debug console (\ opens the menu;
// this drives it from code): "airdrop" call Waldo_debug runs the first action
// whose label contains that text (case-insensitive).
Waldo_debug = {
	params ["_needle"];
	private _n = toLower _needle;
	private _i = Waldo_debugRegistry findIf { (toLower (_x select 1)) find _n >= 0 };
	if (_i < 0) exitWith { systemChat format ["[Waldo][debug] no action matching '%1'", _needle]; false };
	[_i] call Waldo_debugDispatch;
	true
};

// Instant role switch without opening the menu — bound to a hotkey (see
// Waldo_fnc_initClient) and reusing the registry's "Become X" server action so
// the role change stays authoritative. Cycles Innocent -> Traitor -> Detective
// -> Jester -> Innocent.
Waldo_debugCycleRole = {
	private _roles = ["Innocent", "Traitor", "Detective", "Jester"];
	private _cur = player getVariable ["role", "Innocent"];
	private _next = _roles select ((((_roles find _cur) max 0) + 1) mod (count _roles));
	hintSilent parseText format ["<t align='center' size='1.4' color='#ffbb00'>Role -> %1</t>", _next];
	("Become " + _next) call Waldo_debug;
	call Waldo_debugStatus;
};

// Live status line shown at the top of the menu; also handy from the console.
Waldo_debugStatus = {
	private _disp = uiNamespace getVariable ["WaldoDebug", displayNull];
	if (isNull _disp) exitWith {};
	private _sim = missionNamespace getVariable ["Waldo_debugPlayerCount", 0];
	private _txt = format [
		"<t color='#ffbb00'>Role: </t>%1     <t color='#ffbb00'>Credits: </t>%2     <t color='#ffbb00'>Godmode: </t>%3<br/>"
		+ "<t color='#ffbb00'>Round live: </t>%4     <t color='#ffbb00'>Frozen: </t>%5     <t color='#ffbb00'>Reveal: </t>%6<br/>"
		+ "<t color='#ffbb00'>Players: </t>%7 (sim-size %8, sim-players %9)     T:%10  D:%11  J:%12",
		player getVariable ["role", "Innocent"],
		player getVariable ["points", 0],
		["off", "ON"] select (player getVariable ["Waldo_debugGod", false]),
		["no", "YES"] select (missionNamespace getVariable ["gameOn", false]),
		["no", "YES"] select (missionNamespace getVariable ["Waldo_debugFreeze", false]),
		["off", "ON"] select (!isNil "Waldo_debugRevealEH"),
		count allPlayers,
		[_sim, "off"] select (_sim <= 0),
		count (missionNamespace getVariable ["Waldo_debugSimPlayers", []]),
		count (missionNamespace getVariable ["TraitorList", []]),
		count (missionNamespace getVariable ["DetectiveList", []]),
		count (missionNamespace getVariable ["JesterList", []])
	];
	(_disp displayCtrl 3101) ctrlSetStructuredText parseText _txt;
};

// ── Shared server-side helpers (run on the server via debugExec) ─────────────

// Switch a unit's role, keeping the authoritative role lists consistent so win
// checks keep behaving. Applies the role's loadout / fire-block and refreshes
// the unit's HUD + role icons.
Waldo_debugSetRole = {
	params ["_unit", "_role"];
	if (isNull _unit) exitWith {};

	{
		private _list = (missionNamespace getVariable [_x, []]) - [_unit];
		missionNamespace setVariable [_x, _list, true];
	} forEach ["TraitorList", "DetectiveList", "JesterList"];

	_unit setVariable ["role", _role, true];
	_unit setVariable ["tested", false, true];

	switch (_role) do {
		case "Traitor": {
			private _l = missionNamespace getVariable ["TraitorList", []];
			_l pushBackUnique _unit;
			missionNamespace setVariable ["TraitorList", _l, true];
			// Give a usable test balance so the shop is immediately buyable.
			_unit setVariable ["points", (_unit getVariable ["points", 0]) max 10, true];
		};
		case "Detective": {
			private _l = missionNamespace getVariable ["DetectiveList", []];
			_l pushBackUnique _unit;
			missionNamespace setVariable ["DetectiveList", _l, true];
			_unit setVariable ["points", (_unit getVariable ["points", 0]) max 10, true];
			[_unit] remoteExec ["Waldo_fnc_applyDetectiveLoadout", _unit];
		};
		case "Jester": {
			private _l = missionNamespace getVariable ["JesterList", []];
			_l pushBackUnique _unit;
			missionNamespace setVariable ["JesterList", _l, true];
		};
		default { /* Innocent: belongs to no list */ };
	};

	// Reconcile the Jester "deals no damage" fire-block on EVERY switch, so
	// cycling in and out of Jester on the fly never leaves you firing blanks.
	if (_role == "Jester") then {
		[] remoteExec ["Waldo_fnc_makeJester", _unit];
	} else {
		[] remoteExec ["Waldo_fnc_unmakeJester", _unit];
	};

	[] remoteExec ["Waldo_fnc_initHud", _unit];
	[] remoteExec ["Waldo_fnc_drawRoleIcons", _unit];
	[format ["[Waldo][debug] you are now %1", _role]] remoteExec ["systemChat", _unit];
	diag_log format ["[Waldo][server] debug: %1 -> role %2", name _unit, _role];
};

// Create one AI test unit at _pos on _side, MOD-INDEPENDENTLY. The unit class is
// read from an overridable variable (Waldo_debugCivUnit / Waldo_debugEnemyUnit)
// and validated, falling back to a base-game class that exists in every Arma 3
// install — so testing works under any mods. Civilian-side units are dressed in
// the discovered uniform/headgear/vest so dummies and sims look like the current
// players. Returns the unit, or objNull on failure.
Waldo_debugMakeUnit = {
	params ["_pos", "_side"];
	private _enemy = (_side isEqualTo east);
	private _default = ["C_man_1", "O_Soldier_F"] select _enemy;
	private _var     = ["Waldo_debugCivUnit", "Waldo_debugEnemyUnit"] select _enemy;
	private _cls = missionNamespace getVariable [_var, _default];
	if (!isClass (configFile >> "CfgVehicles" >> _cls)) then { _cls = _default; };

	private _grp = createGroup [_side, true];
	_grp createUnit [_cls, _pos, [], 0, "NONE"];
	private _u = (units _grp) select 0;
	if (isNull _u) exitWith { objNull };

	// Dress non-enemy test units to match the current players' look.
	if (!_enemy) then {
		private _uni  = missionNamespace getVariable ["uniformsConfig", []];
		private _head = missionNamespace getVariable ["headgearsConfig", []];
		private _vest = missionNamespace getVariable ["vestsConfig", []];
		if (count _uni  > 0) then { _u forceAddUniform (selectRandom _uni); };
		if (count _vest > 0) then { _u addVest (selectRandom _vest); };
		if (count _head > 0) then { _u addHeadgear (selectRandom _head); };
	};
	_u
};

// Spawn a test dummy in front of the caller. Role dummies are captive/idle and
// route their death through the normal kill handler (so kill-credit, the Jester
// clean-kill and karma can be exercised solo). "Hostile" is an armed enemy for
// combat testing and deliberately has NO kill hook (killing it isn't a TTT kill).
Waldo_debugSpawnDummy = {
	params ["_caller", "_role"];
	if (isNull _caller) exitWith {};
	private _hostile = (_role == "Hostile");
	private _pos = _caller getPos [5, getDir _caller];
	private _unit = [_pos, [civilian, east] select _hostile] call Waldo_debugMakeUnit;
	if (isNull _unit) exitWith { diag_log "[Waldo][server] debug: dummy spawn failed"; };

	_unit setDir ((getDir _caller) + 180);
	_unit allowDamage true;

	if (_hostile) then {
		_unit setSkill 0.3;
		_unit setBehaviour "COMBAT";
	} else {
		_unit setCaptive true;
		_unit disableAI "ALL";
		_unit setVariable ["role", _role, true];
		_unit setVariable ["tested", false, true];
		_unit addMPEventHandler ["MPKilled", { _this call Waldo_fnc_onKilled }];
	};

	private _list = missionNamespace getVariable ["Waldo_debugDummies", []];
	_list pushBack _unit;
	missionNamespace setVariable ["Waldo_debugDummies", _list, true];
	[format ["[Waldo][debug] spawned %1 dummy", _role]] remoteExec ["systemChat", _caller];
};

Waldo_debugClearDummies = {
	params ["_caller"];
	{ if (!isNull _x) then { deleteVehicle _x }; } forEach (missionNamespace getVariable ["Waldo_debugDummies", []]);
	missionNamespace setVariable ["Waldo_debugDummies", [], true];
	["[Waldo][debug] cleared test dummies"] remoteExec ["systemChat", _caller];
};

// Spawn _n simulated players of a role. Unlike test dummies, these are wired
// into the win-condition roster: traitor sims join TraitorList (so END1 needs
// them dead), non-traitor sims flag that non-Traitors exist (so END2 becomes
// reachable). Each routes its death through the normal kill handler. Captive +
// idle so they never fight or wander — they exist purely to resolve endings.
Waldo_debugSpawnSim = {
	params ["_caller", "_role", ["_n", 1]];
	if (isNull _caller) exitWith {};
	private _made = 0;
	for "_i" from 1 to _n do {
		private _pos = _caller getPos [4 + random 4, random 360];
		private _u = [_pos, civilian] call Waldo_debugMakeUnit;
		if (!isNull _u) then {
			_u setVariable ["role", _role, true];
			_u setVariable ["tested", false, true];
			_u setVariable ["Waldo_sim", true, true];
			_u setCaptive true;
			_u disableAI "ALL";
			_u allowDamage true;
			_u addMPEventHandler ["MPKilled", { _this call Waldo_fnc_onKilled }];

			private _sims = missionNamespace getVariable ["Waldo_debugSimPlayers", []];
			_sims pushBackUnique _u;
			missionNamespace setVariable ["Waldo_debugSimPlayers", _sims, true];

			if (_role == "Traitor") then {
				private _tl = missionNamespace getVariable ["TraitorList", []];
				_tl pushBackUnique _u;
				missionNamespace setVariable ["TraitorList", _tl, true];
			} else {
				missionNamespace setVariable ["Waldo_hadNonTraitors", true, true];
			};
			_made = _made + 1;
		};
	};
	[format ["[Waldo][debug] added %1 simulated %2 player(s)", _made, _role]] remoteExec ["systemChat", _caller];
};

// Kill simulated players of one side so an ending can be watched resolving.
// _which is "Traitor" (-> END1) or "NonTraitor" (-> END2). Deaths flow through
// the kill handler, then the 1 Hz round loop's win check ends the round.
Waldo_debugKillSims = {
	params ["_caller", "_which"];
	private _traitors = missionNamespace getVariable ["TraitorList", []];
	private _killed = 0;
	{
		if (!isNull _x && {alive _x}) then {
			private _isT = _x in _traitors;
			if ((_which == "Traitor" && _isT) || {_which == "NonTraitor" && !_isT}) then {
				_x setDamage 1;
				_killed = _killed + 1;
			};
		};
	} forEach (missionNamespace getVariable ["Waldo_debugSimPlayers", []]);
	[format ["[Waldo][debug] killed %1 sim %2 player(s)", _killed, _which]] remoteExec ["systemChat", _caller];
};

// Remove every simulated player and repair the win lists so a torn-down
// scenario can't leave a stale ending armed. Recomputes Waldo_hadNonTraitors
// from the REAL players so a solo dev is never insta-ended after a clear.
Waldo_debugClearSims = {
	params ["_caller"];
	private _sims = missionNamespace getVariable ["Waldo_debugSimPlayers", []];
	private _traitors = (missionNamespace getVariable ["TraitorList", []]) - _sims;
	missionNamespace setVariable ["TraitorList", _traitors, true];
	{ if (!isNull _x) then { deleteVehicle _x }; } forEach _sims;
	missionNamespace setVariable ["Waldo_debugSimPlayers", [], true];
	private _realNon = allPlayers findIf { !isNull _x && {alive _x} && {!(_x in _traitors)} };
	missionNamespace setVariable ["Waldo_hadNonTraitors", (_realNon != -1), true];
	["[Waldo][debug] cleared simulated players"] remoteExec ["systemChat", _caller];
};

// ── Shared client-side helpers ───────────────────────────────────────────────

// Toggle the "reveal every unit's role in 3D" dev overlay.
Waldo_debugToggleReveal = {
	if (isNil "Waldo_debugRevealEH") then {
		Waldo_debugRevealEH = addMissionEventHandler ["Draw3D", {
			{
				private _p = getPosATL _x;
				_p set [2, (_p select 2) + 2];
				private _r = _x getVariable ["role", "Innocent"];
				drawIcon3D ["", ([_r] call Waldo_roleColor), _p, 1, 0, 0, _r, 2, 0.04, "PuristaMedium", "center"];
			} forEach (allUnits + allDeadMen);
		}];
	} else {
		removeMissionEventHandler ["Draw3D", Waldo_debugRevealEH];
		Waldo_debugRevealEH = nil;
	};
};

// One-line game-state dump to chat + rpt; returns the string (for clipboard).
Waldo_debugDump = {
	private _s = format [
		"role=%1 pts=%2 gameOn=%3 start=%4 timelimit=%5 T=%6 D=%7 J=%8 pos=%9 r=%10 sim=%11 frozen=%12",
		player getVariable ["role", "?"], player getVariable ["points", 0],
		missionNamespace getVariable ["gameOn", false],
		missionNamespace getVariable ["Waldo_startTime", 0],
		missionNamespace getVariable ["timelimit", 0],
		count (missionNamespace getVariable ["TraitorList", []]),
		count (missionNamespace getVariable ["DetectiveList", []]),
		count (missionNamespace getVariable ["JesterList", []]),
		missionNamespace getVariable ["mapPos", []],
		missionNamespace getVariable ["mapRadius", 0],
		missionNamespace getVariable ["Waldo_debugPlayerCount", 0],
		missionNamespace getVariable ["Waldo_debugFreeze", false]
	];
	systemChat _s;
	diag_log ("[Waldo][debug] " + _s);
	_s
};

// ── Built-in action registry ─────────────────────────────────────────────────

// Roles
["Roles", "Become Innocent",  "Switch your role to Innocent",              "server", { [_this, "Innocent"]  call Waldo_debugSetRole }] call Waldo_debugRegister;
["Roles", "Become Traitor",   "Switch your role to Traitor",               "server", { [_this, "Traitor"]   call Waldo_debugSetRole }] call Waldo_debugRegister;
["Roles", "Become Detective", "Switch role + apply the detective loadout", "server", { [_this, "Detective"] call Waldo_debugSetRole }] call Waldo_debugRegister;
["Roles", "Become Jester",    "Switch to Jester (bullets deal no damage)", "server", { [_this, "Jester"]    call Waldo_debugSetRole }] call Waldo_debugRegister;
["Roles", "Reassign All Roles", "Clear sims, then re-run role assignment for the lobby", "server", { [_this] call Waldo_debugClearSims; [] call Waldo_fnc_assignRoles }] call Waldo_debugRegister;
["Roles", "Reveal All Roles",   "Toggle a 3D overlay of every unit's role","local",  { call Waldo_debugToggleReveal }] call Waldo_debugRegister;

// Loadout & Shops
["Loadout & Shops", "+5 Credits",         "Add 5 shop credits",   "local", { player setVariable ["points", (player getVariable ["points", 0]) + 5, true] }] call Waldo_debugRegister;
["Loadout & Shops", "+100 Credits",       "Add 100 shop credits", "local", { player setVariable ["points", (player getVariable ["points", 0]) + 100, true] }] call Waldo_debugRegister;
["Loadout & Shops", "Open Traitor Shop",  "Inspect / buy-test the Traitor shop",   "local", { closeDialog 1; ["Traitor"]   call Waldo_fnc_openBuyMenu }] call Waldo_debugRegister;
["Loadout & Shops", "Open Detective Shop","Inspect / buy-test the Detective shop", "local", { closeDialog 1; ["Detective"] call Waldo_fnc_openBuyMenu }] call Waldo_debugRegister;
// Runs every catalog entry's _onBuy AND, for activation items, logs + slots
// them exactly like a real purchase - _onBuy is an empty {} by design for
// every activation item (the real effect lives in _onAct), so without this a
// dev pressing this button would see the passives/weapons land but every
// activation item would silently do nothing, with no way to press Y/U/J and
// actually exercise it.
private _giveAll = {
	params ["_catalog"];
	{
		_x params ["_name", "", "_type", "_onBuy", "_onAct", "_tip"];
		call _onBuy;
		if (_type == "activation") then {
			private _id = player getVariable ["Waldo_purchaseSeq", 0];
			player setVariable ["Waldo_purchaseSeq", _id + 1];
			[_id] call Waldo_fnc_registerActivationSlot;
			private _purchases = player getVariable ["Waldo_purchases", []];
			_purchases pushBack [_id, _name, _tip, _type, _onAct];
			player setVariable ["Waldo_purchases", _purchases];
		};
	} forEach _catalog;
};
["Loadout & Shops", "Give All Traitor Items",   "Run every Traitor shop purchase effect (activation items get slotted to Y/U/J too)",   "local", { [Waldo_traitorShop]   call _giveAll }] call Waldo_debugRegister;
["Loadout & Shops", "Give All Detective Items", "Run every Detective shop purchase effect (activation items get slotted to Y/U/J too)", "local", { [Waldo_detectiveShop] call _giveAll }] call Waldo_debugRegister;

// Abilities (exercise each role power directly)
["Abilities", "Traitor Radar",   "Pulse everyone's position",               "local", { [] call Waldo_fnc_traitorRadar }] call Waldo_debugRegister;
["Abilities", "Detective Radar", "Pulse all positions",                     "local", { [] call Waldo_fnc_detectiveRadar }] call Waldo_debugRegister;
["Abilities", "Warp Smoke",      "Get red smoke + arm the teleport",        "local", { player addMagazine ["SmokeShellRed", 2]; [] call Waldo_fnc_warpSmoke }] call Waldo_debugRegister;
["Abilities", "Flower Power",    "Turn your bullets into flowers",          "local", { [] call Waldo_fnc_flowerPower }] call Waldo_debugRegister;
["Abilities", "Health Station",  "Deploy a healing station",                "local", { [] call Waldo_fnc_healthStation }] call Waldo_debugRegister;
["Abilities", "Suicide Bomb",    "Detonate yourself (test the traitor bomb)","local", { [] call Waldo_fnc_suicideBomb }] call Waldo_debugRegister;
["Abilities", "Holster",         "Holster / lower weapon toggle",           "local", { [] call Waldo_fnc_holster }] call Waldo_debugRegister;

// HUD - role crest style preview. Goes through the exact same mechanism the
// H key does (profileNamespace, Waldo_roleCrestStylePref) rather than a
// separate override path, since that IS the only mechanism now - role crest
// style is a per-player preference, not a lobby setting. Saved immediately,
// same as H, so testing one of these really does stick for this profile.
private _setCrestStyle = {
	params ["_style"];
	profileNamespace setVariable ["Waldo_roleCrestStylePref", _style];
	saveProfileNamespace;
	[] call Waldo_fnc_initHud;
};
["HUD", "Role Crest: Field Medallion",               "Sets your saved role crest preference to this style (same as pressing H)", "local", { [0] call _setCrestStyle }] call Waldo_debugRegister;
["HUD", "Role Crest: Struck Coin",                   "Sets your saved role crest preference to this style (same as pressing H)", "local", { [1] call _setCrestStyle }] call Waldo_debugRegister;
["HUD", "Role Crest: Enamel Pin",                    "Sets your saved role crest preference to this style (same as pressing H)", "local", { [2] call _setCrestStyle }] call Waldo_debugRegister;
["HUD", "Role Crest: Dog Tag",                       "Sets your saved role crest preference to this style (same as pressing H)", "local", { [3] call _setCrestStyle }] call Waldo_debugRegister;
["HUD", "Role Crest: Unit Patch",                    "Sets your saved role crest preference to this style (same as pressing H)", "local", { [4] call _setCrestStyle }] call Waldo_debugRegister;
["HUD", "Role Crest: Crate Stencil",                 "Sets your saved role crest preference to this style (same as pressing H)", "local", { [5] call _setCrestStyle }] call Waldo_debugRegister;
["HUD", "Role Crest: Case File",                     "Sets your saved role crest preference to this style (same as pressing H)", "local", { [6] call _setCrestStyle }] call Waldo_debugRegister;
["HUD", "Role Crest: Chalk Mark",                    "Sets your saved role crest preference to this style (same as pressing H)", "local", { [7] call _setCrestStyle }] call Waldo_debugRegister;
["HUD", "Role Crest: Evidence Tag",                  "Sets your saved role crest preference to this style (same as pressing H)", "local", { [8] call _setCrestStyle }] call Waldo_debugRegister;

// HUD - notification-card system (functions/uinotify/) previews. All fire
// real Waldo_fnc_ShowUiNotification calls, not mockups, so what's on screen
// after clicking one of these is exactly what a player would see - just
// without needing to actually die mid-round, wait for an airdrop timer, or
// end a round to trigger the real event.
["HUD", "UI: Preview All Placements", "One sample card in each of the 5 placement zones (TOP/TOP_RIGHT/CENTER/BOTTOM_LEFT/BOTTOM_RIGHT)", "local", {
	{
		[
			format ["PLACEMENT: %1", _x], "Sample card for this zone - checking spacing/overlap.",
			"INFO", 8, _x, format ["PREVIEW_PLACEMENT_%1", _x], "UI TEST"
		] call Waldo_fnc_ShowUiNotification;
	} forEach ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_RIGHT"];
}] call Waldo_debugRegister;
["HUD", "UI: Preview All States", "One card per state (INFO/SUCCESS/WARNING/ERROR) stacked in BOTTOM_LEFT", "local", {
	{
		_x params ["_state", "_msg"];
		[
			format ["STATE: %1", _state], _msg,
			_state, 8, "BOTTOM_LEFT", format ["PREVIEW_STATE_%1", _state], "UI TEST"
		] call Waldo_fnc_ShowUiNotification;
	} forEach [
		["INFO", "This is an info card."],
		["SUCCESS", "This is a success card."],
		["WARNING", "This is a warning card."],
		["ERROR", "This is an error card."]
	];
}] call Waldo_debugRegister;
["HUD", "UI: Simulate MVP Banner", "Plays the real round-end MVP celebration (music + fireworks + card) without ending the round", "local", {
	["Test Player", player getVariable ["role", "Innocent"], 5] call Waldo_fnc_mvpCelebrate;
}] call Waldo_debugRegister;
["HUD", "UI: Simulate Airdrop (Golden)", "Fires the exact card a real golden airdrop shows, without spawning one", "local", {
	["STR_TIA_Airdrop_GoldenTitle", "STR_TIA_Airdrop_GoldenWeapons", "WARNING", 6, "TOP", "AIRDROP", "STR_TIA_Airdrop_Source"] call Waldo_fnc_ShowUiNotification;
}] call Waldo_debugRegister;
["HUD", "UI: Simulate Airdrop (Supply)", "Fires the exact card a real supply airdrop shows, without spawning one", "local", {
	["STR_TIA_Airdrop_InboundTitle", "STR_TIA_Airdrop_InboundBody", "INFO", 5, "TOP", "AIRDROP", "STR_TIA_Airdrop_Source"] call Waldo_fnc_ShowUiNotification;
}] call Waldo_debugRegister;

// Test Dummies
["Test Dummies", "Spawn Innocent Dummy",  "Captive dummy; death runs the kill handler", "server", { [_this, "Innocent"]  call Waldo_debugSpawnDummy }] call Waldo_debugRegister;
["Test Dummies", "Spawn Traitor Dummy",   "Kill it to test detective kill-credit",      "server", { [_this, "Traitor"]   call Waldo_debugSpawnDummy }] call Waldo_debugRegister;
["Test Dummies", "Spawn Detective Dummy", "Test detective corpse reveal / credit",      "server", { [_this, "Detective"] call Waldo_debugSpawnDummy }] call Waldo_debugRegister;
["Test Dummies", "Spawn Jester Dummy",    "Kill as non-traitor to test the Jester win", "server", { [_this, "Jester"]    call Waldo_debugSpawnDummy }] call Waldo_debugRegister;
["Test Dummies", "Spawn Hostile AI",      "An armed enemy for combat testing",          "server", { [_this, "Hostile"]   call Waldo_debugSpawnDummy }] call Waldo_debugRegister;
["Test Dummies", "Clear All Dummies",     "Delete every spawned test unit",             "server", { [_this] call Waldo_debugClearDummies }] call Waldo_debugRegister;

// Simulated Players (count toward win conditions — use these to test endings)
["Simulated Players", "Add Innocent",  "Spawn a simulated Innocent (counts for endings)",  "server", { [_this, "Innocent"]  call Waldo_debugSpawnSim }] call Waldo_debugRegister;
["Simulated Players", "Add Traitor",   "Spawn a simulated Traitor (joins TraitorList)",    "server", { [_this, "Traitor"]   call Waldo_debugSpawnSim }] call Waldo_debugRegister;
["Simulated Players", "Add Detective", "Spawn a simulated Detective (counts as innocent)", "server", { [_this, "Detective"] call Waldo_debugSpawnSim }] call Waldo_debugRegister;
["Simulated Players", "Add Jester",    "Spawn a simulated Jester",                         "server", { [_this, "Jester"]    call Waldo_debugSpawnSim }] call Waldo_debugRegister;
["Simulated Players", "Simulate Round (3 Inn + 1 Tra)", "Quick roster for testing endings", "server", { [_this, "Innocent", 3] call Waldo_debugSpawnSim; [_this, "Traitor", 1] call Waldo_debugSpawnSim }] call Waldo_debugRegister;
["Simulated Players", "Kill Sim Traitors (test END1)",  "Innocents win when all traitors die - be a NON-traitor yourself", "server", { [_this, "Traitor"]    call Waldo_debugKillSims }] call Waldo_debugRegister;
["Simulated Players", "Kill Sim Innocents (test END2)", "Traitors win when all non-traitors die - be a TRAITOR yourself", "server", { [_this, "NonTraitor"] call Waldo_debugKillSims }] call Waldo_debugRegister;
["Simulated Players", "Clear Sim Players", "Remove sims + repair the win lists",            "server", { [_this] call Waldo_debugClearSims }] call Waldo_debugRegister;

// Round Flow
["Round Flow", "Skip Warmup",    "End the role-selection warmup early", "server", { missionNamespace setVariable ["Waldo_debugSkipWarmup", true, true] }] call Waldo_debugRegister;
["Round Flow", "Freeze Timer",   "Toggle: pause the clock / airdrops / win checks", "server", {
	private _f = !(missionNamespace getVariable ["Waldo_debugFreeze", false]);
	missionNamespace setVariable ["Waldo_debugFreeze", _f, true];
	[format ["[Waldo][debug] timer %1", ["unfrozen", "FROZEN"] select _f]] remoteExec ["systemChat", _this];
}] call Waldo_debugRegister;
["Round Flow", "Add 60s",        "Extend the round by 60 seconds", "server", {
	missionNamespace setVariable ["Waldo_startTime", (missionNamespace getVariable ["Waldo_startTime", 180]) + 60, true];
	missionNamespace setVariable ["timelimit",       (missionNamespace getVariable ["timelimit", 180]) + 60, true];
}] call Waldo_debugRegister;
["Round Flow", "Subtract 60s",   "Shorten the round by 60 seconds", "server", {
	missionNamespace setVariable ["Waldo_startTime", ((missionNamespace getVariable ["Waldo_startTime", 180]) - 60) max 1, true];
	missionNamespace setVariable ["timelimit",       ((missionNamespace getVariable ["timelimit", 180]) - 60) max 1, true];
}] call Waldo_debugRegister;
["Round Flow", "End: Innocents Win", "Force ending END1", "server", { ["END1"] call Waldo_fnc_endRound }] call Waldo_debugRegister;
["Round Flow", "End: Traitors Win",  "Force ending END2", "server", { ["END2"] call Waldo_fnc_endRound }] call Waldo_debugRegister;
["Round Flow", "End: Time Up",       "Force ending END3", "server", { ["END3"] call Waldo_fnc_endRound }] call Waldo_debugRegister;
["Round Flow", "End: Jester Wins",   "Force ending END4", "server", { ["END4"] call Waldo_fnc_endRound }] call Waldo_debugRegister;

// Arena & World
["Arena & World", "Rebuild Arena",   "Re-run the arena builder at the current centre", "server", { [] call Waldo_fnc_buildArena; [] call Waldo_fnc_clearArenaPaths }] call Waldo_debugRegister;
["Arena & World", "Reselect Arena",  "Pick a new arena + loot (uses the sim count)",   "server", { [] call Waldo_fnc_selectArena; [] call Waldo_fnc_populateLoot; [] call Waldo_fnc_buildArena; [] call Waldo_fnc_clearArenaPaths }] call Waldo_debugRegister;
["Arena & World", "Repopulate Loot", "Re-scatter ground loot in the arena",            "server", { [] call Waldo_fnc_populateLoot }] call Waldo_debugRegister;
["Arena & World", "Clear Arena Paths", "Cut gates through any wall/fence line splitting the current arena", "server", { [] call Waldo_fnc_clearArenaPaths }] call Waldo_debugRegister;
["Arena & World", "Weather: Clear",  "Sun, no rain/fog",  "server", { 0 setOvercast 0;   forceWeatherChange; 0 setRain 0; 0 setFog 0 }] call Waldo_debugRegister;
["Arena & World", "Weather: Rain",   "Overcast + rain",   "server", { 0 setOvercast 1;   forceWeatherChange; 0 setRain 1; 0 setFog 0 }] call Waldo_debugRegister;
["Arena & World", "Weather: Fog",    "Heavy fog",         "server", { 0 setOvercast 0.5; forceWeatherChange; 0 setRain 0; 0 setFog 0.85 }] call Waldo_debugRegister;
["Arena & World", "Time: Dawn",  "Set time to 06:00", "server", { setDate [2035, 7, 6, 6, 0] }] call Waldo_debugRegister;
["Arena & World", "Time: Noon",  "Set time to 12:00", "server", { setDate [2035, 7, 6, 12, 0] }] call Waldo_debugRegister;
["Arena & World", "Time: Dusk",  "Set time to 19:00", "server", { setDate [2035, 7, 6, 19, 0] }] call Waldo_debugRegister;
["Arena & World", "Time: Night", "Set time to 23:00", "server", { setDate [2035, 7, 6, 23, 0] }] call Waldo_debugRegister;

// Karma & Sim
["Karma & Sim", "Reset My Karma", "Set your stored karma to 100", "server", {
	private _uid = getPlayerUID _this;
	if (_uid != "") then { profileNamespace setVariable ["Waldo_karma_" + _uid, 100]; saveProfileNamespace; };
	["[Waldo][debug] karma reset to 100"] remoteExec ["systemChat", _this];
}] call Waldo_debugRegister;
["Karma & Sim", "Tank My Karma", "Set karma to 0 (test next-round penalty)", "server", {
	private _uid = getPlayerUID _this;
	if (_uid != "") then { profileNamespace setVariable ["Waldo_karma_" + _uid, 0]; saveProfileNamespace; };
	["[Waldo][debug] karma set to 0"] remoteExec ["systemChat", _this];
}] call Waldo_debugRegister;
["Karma & Sim", "Simulate 1 Player",   "Size systems as if 1 player",  "server", { missionNamespace setVariable ["Waldo_debugPlayerCount", 1, true];  ["[Waldo][debug] sim count = 1 (use Reselect/Reassign)"] remoteExec ["systemChat", _this] }] call Waldo_debugRegister;
["Karma & Sim", "Simulate 5 Players",  "Size systems as if 5 players", "server", { missionNamespace setVariable ["Waldo_debugPlayerCount", 5, true];  ["[Waldo][debug] sim count = 5 (use Reselect/Reassign)"] remoteExec ["systemChat", _this] }] call Waldo_debugRegister;
["Karma & Sim", "Simulate 12 Players", "Size systems as if 12 players","server", { missionNamespace setVariable ["Waldo_debugPlayerCount", 12, true]; ["[Waldo][debug] sim count = 12 (use Reselect/Reassign)"] remoteExec ["systemChat", _this] }] call Waldo_debugRegister;
["Karma & Sim", "Simulate 24 Players", "Size systems as if 24 players","server", { missionNamespace setVariable ["Waldo_debugPlayerCount", 24, true]; ["[Waldo][debug] sim count = 24 (use Reselect/Reassign)"] remoteExec ["systemChat", _this] }] call Waldo_debugRegister;
["Karma & Sim", "Simulate: Off",       "Use the real player count again","server", { missionNamespace setVariable ["Waldo_debugPlayerCount", 0, true];  ["[Waldo][debug] sim count off"] remoteExec ["systemChat", _this] }] call Waldo_debugRegister;

// Player
["Player", "Toggle Godmode", "Enable / disable damage immunity", "local", {
	private _g = !(player getVariable ["Waldo_debugGod", false]);
	player setVariable ["Waldo_debugGod", _g];
	player allowDamage (!_g);
}] call Waldo_debugRegister;
["Player", "Heal Self",           "Restore full health",              "local", { player setDamage 0 }] call Waldo_debugRegister;
["Player", "Refill Ammo",         "Top up mags for your current weapon","local", {
	private _w = currentWeapon player;
	if (_w != "") then {
		private _mags = getArray (configFile >> "CfgWeapons" >> _w >> "magazines");
		if (count _mags > 0) then { player addMagazines [(_mags select 0), 5]; };
	};
}] call Waldo_debugRegister;
["Player", "Infinite Stamina",    "Toggle unlimited stamina",         "local", {
	private _s = !(player getVariable ["Waldo_debugStam", false]);
	player setVariable ["Waldo_debugStam", _s];
	player enableStamina (!_s);
}] call Waldo_debugRegister;
["Player", "Teleport to Centre",  "Jump to the arena centre",         "local", { player setPos (missionNamespace getVariable ["mapPos", getPosATL player]) }] call Waldo_debugRegister;
["Player", "Kill Self",           "Die now (test death / spectator / karma)", "local", { player setDamage 1 }] call Waldo_debugRegister;

// Diagnostics
["Diagnostics", "Dump Game State",   "Print round state to chat + .rpt",         "local", { call Waldo_debugDump }] call Waldo_debugRegister;
["Diagnostics", "State to Clipboard","Copy the state dump to the clipboard",     "local", { copyToClipboard (call Waldo_debugDump) }] call Waldo_debugRegister;
["Diagnostics", "Show Arena Info",   "Hint the arena centre / radius",           "local", { hint format ["Arena centre: %1\nRadius: %2", missionNamespace getVariable ["mapPos", []], missionNamespace getVariable ["mapRadius", 0]] }] call Waldo_debugRegister;

// Menu
["Menu", "Close Menu", "Close this panel (or press [)", "local", { closeDialog 1 }] call Waldo_debugRegister;

diag_log format ["[Waldo] debugInit: %1 test actions registered", count Waldo_debugRegistry];
