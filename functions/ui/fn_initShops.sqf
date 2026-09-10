//////////////////////////////////////////////////////////////////
// Waldo_fnc_initShops  (preInit = 1, runs on every machine)
// Defines shared helpers and the data-driven shop catalogs. Adding a shop
// item is now a single array entry here - no .hpp IDCs or switch cases.
//
// Catalog item format:
//   [ _name, _cost, _type, _onBuy, _onActivate, _tooltip ]
//     _type       : "passive" | "weapon" | "activation"
//     _onBuy      : code run immediately on purchase
//     _onActivate : code run when the player presses whichever of Y/U/J this
//                   item is assigned to (activation items - see
//                   Waldo_fnc_useActivationSlot / Waldo_fnc_assignActivationSlot).
//                   Must return TRUE when it should be consumed, FALSE to stay
//                   assigned (e.g. no valid target).
//
// Weapon/gear classnames are read from missionNamespace at click time (they are
// published by the dynamic arsenal, Waldo_fnc_buildArsenal), so the same catalog
// works on any mod loadout.
//////////////////////////////////////////////////////////////////

// Renders the "Purchased" panel (idc 1107 group) inside the given shop
// display, from the player's per-round purchase log (Waldo_purchases: array of
// [id, name, tip, type, onAct]). Shared by Waldo_fnc_openBuyMenu (on open) and
// Waldo_fnc_buyItem (on each buy) so every purchase shows what it does / how
// to use it without leaving the shop.
//
// Every call fully rebuilds the panel's runtime controls rather than patching
// them in place - the entry count and each activation item's key assignment
// can both change between calls, and this list stays short enough (bounded by
// what a round's credits can afford) that a full rebuild is simpler and safer
// than tracking per-row diffs. Previously created controls are tracked by idc
// (via a display variable) so they can be torn down before rebuilding - since
// every render is a full teardown+recreate, a row's idc has no meaning across
// two different renders, so display order is free to change between calls
// (see below) without anything relying on a row keeping the same idc.
//
// Rendered newest-purchase-first (most recent at the top, everything already
// there shifts down beneath it) - Waldo_purchases itself stays append-only
// (oldest at index 0, see Waldo_fnc_buyItem's pushBack) so a fresh purchase
// is always about-to-be-bought-again context, worth seeing without scrolling
// past everything bought earlier in the round.
Waldo_shopRenderPurchased = {
	params ["_display"];
	private _group = _display displayCtrl 1107;

	{ private _c = _display displayCtrl _x; if (!isNull _c) then { ctrlDelete _c }; }
		forEach (_display getVariable ["Waldo_purchRowIds", []]);
	private _newIds = [];

	// Displayed newest-first - a reversed COPY, never the stored array itself
	// (that has to stay append-only/oldest-first for Waldo_fnc_buyItem's
	// pushBack, and SQF's reverse mutates in place).
	private _purchases = +(player getVariable ["Waldo_purchases", []]);
	reverse _purchases;
	private _slots      = player getVariable ["Waldo_activationSlots", [-1, -1, -1]];
	private _backlog     = player getVariable ["Waldo_activationBacklog", []];
	private _keyLabels   = ["Y", "U", "J"];

	private _rowW    = 0.18 * safezoneW;
	private _lineH   = 0.030 * safezoneH;
	private _gapV    = 0.010 * safezoneH;
	private _btnW    = 0.034 * safezoneW;
	private _btnH    = 0.020 * safezoneH;
	private _btnGap  = 0.006 * safezoneW;
	private _idBase  = 2100;
	private _y = 0;

	if (count _purchases == 0) then {
		private _lbl = _display ctrlCreate ["RscStructuredText", _idBase, _group];
		_lbl ctrlSetPosition [0, 0, _rowW, _lineH * 2];
		_lbl ctrlSetStructuredText parseText "<t size='0.9' color='#9EA290'>Nothing purchased yet.</t>";
		_lbl ctrlCommit 0;
		_newIds pushBack _idBase;
	} else {
		{
			_x params ["_id", "_name", "_tip", "_type", ""];
			private _i = _forEachIndex;
			// Each row claims a block of 5 ids: 1 label + 3 slot buttons (+1 spare).
			private _idc = _idBase + (_i * 5) + 1;

			private _slotIdx = _slots findIf { _x == _id };
			private _isActivation = _type == "activation";
			private _used = _isActivation && {_slotIdx < 0} && {!(_id in _backlog)};
			private _statusTxt = "";
			if (_isActivation) then {
				_statusTxt = if (_slotIdx >= 0) then {
					format [" <t color='#F2BE55'>[%1]</t>", _keyLabels select _slotIdx]
				} else {
					if (_used) then { " <t color='#6a6f61'>[used]</t>" } else { " <t color='#E4514B'>[unassigned]</t>" }
				};
			};

			private _lbl = _display ctrlCreate ["RscStructuredText", _idc, _group];
			_lbl ctrlSetPosition [0, _y, _rowW, _lineH * 2];
			_lbl ctrlSetStructuredText parseText format [
				"<t size='1.0' color='#F2BE55'>%1</t>%2<br/><t size='0.85' color='#9EA290'>%3</t>",
				_name, _statusTxt, _tip
			];
			_lbl ctrlCommit 0;
			_newIds pushBack _idc;
			_y = _y + (_lineH * 2);

			if (_isActivation && {!_used}) then {
				{
					private _slot = _x;
					private _btnIdc = _idc + 1 + _slot;
					private _btn = _display ctrlCreate ["RscButton", _btnIdc, _group];
					_btn ctrlSetPosition [_slot * (_btnW + _btnGap), _y, _btnW, _btnH];
					_btn ctrlSetText (_keyLabels select _slot);
					_btn ctrlSetFontHeight (0.7 * _btnH);
					if (_slotIdx == _slot) then {
						_btn ctrlSetBackgroundColor [0.86, 0.68, 0.33, 1];
						_btn ctrlSetTextColor [0.1, 0.1, 0.08, 1];
					} else {
						_btn ctrlSetBackgroundColor [0.06, 0.065, 0.055, 0.92];
						_btn ctrlSetTextColor [0.75, 0.73, 0.68, 1];
					};
					_btn setVariable ["purchId", _id];
					_btn setVariable ["slotIdx", _slot];
					_btn ctrlAddEventHandler ["ButtonClick", {
						params ["_ctrl"];
						[(_ctrl getVariable "purchId"), (_ctrl getVariable "slotIdx")] call Waldo_fnc_assignActivationSlot;
						[ctrlParent _ctrl] call Waldo_shopRenderPurchased;
					}];
					_btn ctrlCommit 0;
					_newIds pushBack _btnIdc;
				} forEach [0, 1, 2];
				_y = _y + _btnH + _gapV;
			} else {
				_y = _y + _gapV;
			};
		} forEach _purchases;
	};

	_display setVariable ["Waldo_purchRowIds", _newIds];
};

// Per-role keybind list, shared by the top bar's horizontal row
// (Waldo_fnc_initHud) and the scoreboard's right-side panel
// (Waldo_fnc_scoreboard) - one source of truth so the two never drift out of
// sync. Returns [key, label] pairs rather than pre-formatted strings so each
// caller can join/colour them however its own layout needs (horizontal vs
// stacked). Dev-only binds are appended only when Testing Mode is actually on.
Waldo_keyHintsFor = {
	params ["_role"];
	private _hints = [["L", "Holster"], ["K", "Scoreboard"], ["H", "Role Crest Style"]];
	if (_role in ["Traitor", "Detective"]) then {
		_hints pushBack ["B", "Buy Menu"];
		_hints pushBack ["Y U J", "Use Item"];
	};
	if (_role == "Traitor") then {
		_hints pushBack ["T (hold)", "Ping"];
	};
	if (missionNamespace getVariable ["TestingFlag", false]) then {
		_hints pushBack ["[", "Dev Menu"];
		_hints pushBack ["]", "Cycle Role"];
	};
	_hints
};

// Swaps the player's vest, carrying over whatever was already stored in the
// old one instead of discarding it - Arma's addVest always replaces (and
// empties) the currently-worn vest, no way around that, but there's no
// reason a shop "upgrade" should also erase everything the player was
// carrying. Best-effort: if the new vest has less cargo space than the old
// one, whatever doesn't fit is silently dropped (same as any other
// over-capacity add), not an error.
Waldo_swapVestKeepCargo = {
	params ["_newVest"];
	private _oldContainer = vestContainer player;
	private _mags = magazinesAmmoCargo _oldContainer;
	private _items = itemCargo _oldContainer;
	player addVest _newVest;
	private _newContainer = vestContainer player;
	{ _x params ["_cls", "_ammo"]; _newContainer addMagazineAmmoCargo [_cls, 1, _ammo]; } forEach _mags;
	{ _x params ["_cls", "_cnt"]; _newContainer addItemCargo [_cls, _cnt]; } forEach _items;
};

// Role -> RGBA colour (shared by HUD, icons, menus, radar, ping wheel) -
// every one of those calls this same function, so the accessibility check
// below is the ONE place a colourblind-safe palette needs to live for it to
// apply everywhere "where appropriate" instead of needing to be threaded
// through each caller individually.
//
// Waldo_accessibilityMode lives in profileNamespace (toggled from the
// role crest style picker, H key), same per-player/no-gameplay-effect
// reasoning as Waldo_roleCrestStylePref. Palette is the Okabe-Ito
// colourblind-safe set (vermillion/blue/reddish-purple/bluish-green),
// chosen because it stays pairwise-distinguishable under all three common
// forms of colour vision deficiency, not just one.
Waldo_roleColor = {
	params ["_role"];
	private _cb = profileNamespace getVariable ["Waldo_accessibilityMode", false];
	if (_cb) then {
		switch (_role) do {
			case "Traitor":   { [0.835, 0.369, 0, 1] };
			case "Detective": { [0, 0.447, 0.698, 1] };
			case "Jester":    { [0.8, 0.475, 0.655, 1] };
			default           { [0, 0.62, 0.451, 1] };
		};
	} else {
		switch (_role) do {
			case "Traitor":   { [0.75, 0.21, 0.21, 1] };
			case "Detective": { [0.01, 0.45, 1, 1] };
			case "Jester":    { [0.4, 0, 0.5, 1] };
			default           { [0.12549, 0.72941, 0.09412, 1] };
		};
	};
};

// Role colour as a "#rrggbb" string - same accessibility-aware palette as
// Waldo_roleColor (this just re-encodes whatever that already returned),
// for anything building <t color='#...'> structured text rather than an
// RGBA array (drawIcon3D, ctrlSetBackgroundColor, etc. want the array form
// directly and should keep calling Waldo_roleColor). Was duplicated locally
// in Waldo_fnc_openBuyMenu and (as a hardcoded, non-accessible map) in
// Waldo_fnc_scoreboard - both now call this instead.
Waldo_roleColorHex = {
	params ["_role"];
	private _c = [_role] call Waldo_roleColor;
	private _byte = {
		params ["_v"];
		private _d = "0123456789abcdef";
		private _n = (round (_v * 255)) max 0 min 255;
		(_d select [floor (_n / 16), 1]) + (_d select [_n mod 16, 1])
	};
	"#" + ([_c select 0] call _byte) + ([_c select 1] call _byte) + ([_c select 2] call _byte)
};

// --- Traitor shop ---
// Costs are ranked by power and, more importantly, by how much an item
// undermines the OTHER team's ability to investigate - not by raw kill
// output alone. Cheap (1): Radar and Medical Kit, so a Traitor can always
// afford basic map awareness and self-sufficiency from credit 1, without
// that costing them the round's real economy decision. Mid (2): standard
// kill/utility tools, including Silenced Pistol - reusable and removes the
// gunshot tell, but priced alongside the rest of the mid tier rather than
// the investigation-erasing tier below it. Expensive (3-4): tools that
// actively corrupt or erase the investigation itself (Fake Health Station
// and Body Remover destroy/hide evidence, Teleport Grenades and Long Rifle
// put real distance between a kill and its scene, False Flag frames an
// innocent outright), so those have to be earned through play rather than
// being turn-one defaults. Disguiser (5) is priced above all of them -
// unlike any single-axis item above it, it corrupts BOTH the visual trail
// (walk right up to someone wearing their target's gear) and the forensic
// one (DNA misattribution) at once, for a sustained 60s window rather than
// a single kill.
Waldo_traitorShop = [
	["Suicide Bomb", 2, "activation",
		{},
		{ [] call Waldo_fnc_suicideBomb; true },
		"Detonate yourself (press your assigned key)"],

	["Radar", 1, "passive",
		{ [] call Waldo_fnc_traitorRadar; },
		{},
		"Pulses everyone's position (and role) for 30s, then refreshes"],

	["Rocket Launcher", 3, "weapon",
		{
			// Confirmed via .rpt, three separate times: magazine-before-weapon,
			// a retry-after-weapon-exists, and plain addWeapon instead of
			// addWeaponGlobal ALL still left it unloaded (most recently
			// launch_RPG32_green_F / RPG32_F, loaded=false). Every one of
			// those was still fundamentally an incremental "add a magazine,
			// hope the engine chambers it" operation, and none of them
			// actually solves a genuine no-free-cargo-space case if that's
			// what this is.
			//
			// setUnitLoadout is a different code path entirely: it sets a
			// unit's COMPLETE loadout atomically from a loadout array
			// instead of incrementally adding items into (possibly full)
			// containers one at a time. The launcher slot is index 1 of that
			// array (Arma's own "secondaryWeapon" - BI's docs literally
			// call it that; primary is index 0, handgun is index 2), and
			// each weapon slot's own format is
			// [weapon, muzzle, flashlight, optics, [magazine, ammoCount], [], ""].
			// Splicing the launcher + its magazine directly into the
			// existing loadout (not overwriting anything else the player is
			// already carrying) and setting it back in one call is the last
			// resort short of manually auditing cargo capacity live.
			private _launcherMag = missionNamespace getVariable ["TraitorLauncherMag", "NLAW_F"];
			private _launcher = missionNamespace getVariable ["TraitorLauncher", "launch_NLAW_F"];
			private _loadout = getUnitLoadout player;
			_loadout set [1, [_launcher, "", "", "", [_launcherMag, 1], [], ""]];
			player setUnitLoadout _loadout;
			diag_log format ["[Waldo][client] Rocket Launcher purchase: launcher=%1 mag=%2 loaded=%3", _launcher, _launcherMag, _launcherMag in (magazines player)];
		},
		{},
		// Raised from 2 - highest raw AOE power in the shop, priced to match.
		"A single-use rocket launcher"],

	["Stamina", 1, "passive",
		{ player enableStamina false; },
		{},
		// Lowered from 2 - minor movement convenience, not worth gating like
		// the tools above; matches the Detective shop's own Stamina price.
		"Never run out of stamina"],

	["Teleport Grenades", 3, "weapon",
		{ player addMagazines ["SmokeShellRed", 2]; [] call Waldo_fnc_warpSmoke; },
		{},
		// Raised from 2 - puts real distance between a kill and its scene,
		// which is an investigation-defeating tool as much as a combat one.
		"Throw red smoke to teleport to it (vanilla throw only)"],

	["Long Rifle", 3, "weapon",
		{
			// addWeapon auto-chambers a compatible magazine ALREADY IN
			// INVENTORY at the moment the weapon is added, not the other way
			// around - addMagazine after addWeapon (the previous fix) still
			// spawned it unloaded, because at that point there was nothing
			// yet for the weapon to pick up. Magazines (the chambered one
			// AND the spares) have to go in first.
			// See the Rocket Launcher entry above for why this is plain
			// addWeapon now, not addWeaponGlobal - same latent risk, applied
			// consistently even though only the launcher was reported broken.
			private _rifleMag = missionNamespace getVariable ["TraitorRifleMag", "7Rnd_408_Mag"];
			player addMagazines [_rifleMag, 3];
			player addWeapon (missionNamespace getVariable ["TraitorRifle", "srifle_LRR_F"]);
			player addPrimaryWeaponItem (missionNamespace getVariable ["TraitorRifleOptics", "optic_LRPS"]);
		},
		{},
		// Raised from 2 - long effective range is its own kind of power here.
		"A powerful long-range rifle"],

	// Kept at 2 (not raised) despite being genuinely powerful (an extra
	// Traitor teammate) - it's the one Traitor tool that's fundamentally
	// about teamwork with a fellow Traitor rather than solo play, and this
	// shop is meant to keep that affordable, not price it out.
	["Defibrillator", 2, "activation",
		{},
		{ [] call Waldo_fnc_revive },
		"Aim at a body and press your assigned key to revive them as a Traitor"],

	["Silenced Pistol", 2, "weapon",
		{
			// See the Rocket Launcher entry above - plain addWeapon, not
			// addWeaponGlobal (this already runs locally on the buyer's own
			// client); magazines still have to be in inventory BEFORE the
			// weapon is added for addWeapon to find and chamber one.
			private _pistolMag = missionNamespace getVariable ["ShopPistolMag", "16Rnd_9x21_Mag"];
			player addMagazines [_pistolMag, 3];
			player addWeapon (missionNamespace getVariable ["ShopPistol", "hgun_P07_F"]);
			private _s = missionNamespace getVariable ["ShopPistolSuppressor", ""];
			if (_s != "") then { player addHandgunItem _s; };
		},
		{},
		"A suppressed sidearm - quiet kills leave no gunshot to give you away"],

	["Frag Grenades", 2, "weapon",
		{ player addMagazines [(missionNamespace getVariable ["ShopFrag", "HandGrenade"]), 2]; },
		{},
		"Two fragmentation grenades"],

	["Body Armor", 2, "passive",
		{ [missionNamespace getVariable ["ShopArmorVest", "V_PlateCarrier2_rgr"]] call Waldo_swapVestKeepCargo; },
		{},
		"A heavy plate carrier - soak an extra hit or two"],

	["Medical Kit", 1, "weapon",
		{ player addItem "Medikit"; player addItem "FirstAidKit"; },
		{},
		// Lowered from 2, alongside Radar - both stay affordable turn one on
		// purpose, matching the Detective shop's own Medical Kit price.
		"A medikit + first aid kit to patch yourself up"],

	["Fake Health Station", 3, "weapon",
		{ [] call Waldo_fnc_fakeHealthStation; },
		{},
		// Raised from 2 - a lethal deception trap aimed squarely at whoever's
		// trying to help, one of the more anti-investigative kill tools here.
		"Deploy a decoy - identical to a real Health Station until someone uses it, then it detonates. You're safe from your own trap."],

	["Body Remover", 3, "activation",
		{},
		{ [] call Waldo_fnc_removeBody },
		// Raised from 2 - erases the Detective's evidence outright, not just
		// evades it.
		"Aim at a corpse and press your assigned key to destroy it, denying the Detective a body to test"],

	["C4 Charge", 2, "activation",
		{},
		{ [] call Waldo_fnc_placeC4 },
		"Drop a timed explosive at your feet - it blows in 15s unless someone defuses it"],

	["Night Vision", 1, "weapon",
		{ player addWeapon (missionNamespace getVariable ["ShopNVG", "NVGoggles"]); },
		{},
		// Lowered from 2 - minor situational utility, matches the Detective
		// shop's own Night Vision price.
		"Night-vision goggles - own the dark rounds"],

	["Dead Ringer", 3, "activation",
		{},
		{ [] call Waldo_fnc_deadRinger },
		"Arms a 25s window: your next lethal hit is faked - you ragdoll like a kill and a decoy body appears, but you're not really dead"],

	["False Flag", 4, "passive",
		// No standalone hint here - fn_buyItem.sqf's own "PURCHASED" shop-panel
		// confirmation (and its hint fallback for when the panel isn't open)
		// already covers this; a second unconditional hint on top of that
		// stacked both on screen at once for every purchase.
		{ player setVariable ["Waldo_falseFlag", true, true]; },
		{},
		// Raised from 3 - directly frames another living player for the kill,
		// one of the most investigation-corrupting items available, priced to
		// match (though Disguiser below now edges it out, since that one
		// corrupts the visual trail too, not just the forensic one). Can land
		// on the Detective, not just an Innocent - see fn_onKilled.sqf.
		"Your next kill leaves another living player's DNA at the scene instead of yours"],

	["Disguiser", 5, "activation",
		{},
		{
			params ["_purchId", "_slotIdx"];
			// Opening the picker never consumes the item on its own - only
			// an actual pick does (Waldo_fnc_disguiserActivate), since
			// pressing the key and then hitting ESC must leave it untouched.
			[_purchId, _slotIdx] call Waldo_fnc_disguiserOpen;
			false
		},
		"Press your assigned key to pick a living player - copy their exact current loadout for 60s. Any DNA you'd leave behind while disguised points to them instead of you."]
];

// --- Detective shop ---
// Costs are ranked to steer play toward actual investigation (DNA sampling,
// contamination trade-offs, following a track) rather than a single
// instant-reveal button. Portable Tester is a guaranteed, immediate role
// reveal with none of that - trivial to use, trivially ends the mystery -
// so it's the single most expensive item in the shop. The DNA Scanner path
// (Scanner + its cheaper Enhanced Scanner upgrade) costs less in total to
// make it the shop's clear "correct" investigative purchase. Radar and
// Medical Kit stay at their floor price (1) so map awareness and
// self-sufficiency are never the credit decision that's gating real
// investigative spending.
Waldo_detectiveShop = [
	["Portable Tester", 3, "activation",
		{},
		{ [] call Waldo_fnc_tester },
		// Raised from 2 to the top of the shop - an instant, guaranteed role
		// reveal at melee range trivializes investigation outright; this is
		// deliberately the most expensive item a Detective can buy.
		"Aim at a player or body within 3m and press your assigned key to reveal their role"],

	["DNA Scanner", 2, "activation",
		{ player setVariable ["Waldo_dnaScannerCharges", 3, true]; },
		{ [] call Waldo_fnc_dnaScanner },
		"Aim at a body and press your assigned key to sample the killer's DNA, then track them down (3 uses)"],

	["Enhanced Scanner", 1, "passive",
		{ player setVariable ["Waldo_enhancedScanner", true, true]; },
		{},
		// Cheapest upgrade in the shop - rewards committing further to the
		// DNA path (better odds, more detail) rather than gating it behind
		// another expensive purchase on top of the base Scanner.
		"Upgrades the DNA Scanner: longer/steadier tracking, half the contamination risk, and reveals time-of-death + weapon",
		"DNA Scanner"],   // _requires: does nothing without the base scanner - greyed out in the shop until owned

	["Radar", 1, "passive",
		{ [] call Waldo_fnc_detectiveRadar; },
		{},
		"Pulses all positions for 45s, then refreshes"],

	["Smoke Grenades", 1, "weapon",
		{ player addMagazines ["SmokeShell", 2]; },
		{},
		"Two smoke grenades"],

	["Stamina", 1, "passive",
		{ player enableStamina false; },
		{},
		"Never run out of stamina"],

	["Flower Power", 1, "weapon",
		{ [] call Waldo_fnc_flowerPower; },
		{},
		"Your bullets turn into flowers (novelty)"],

	["Health Station", 1, "weapon",
		{ [] call Waldo_fnc_healthStation; },
		{},
		"Deploy a station - use its action to fully heal yourself"],

	["Defibrillator", 2, "activation",
		{},
		{ [] call Waldo_fnc_revive },
		"Aim at a body and press your assigned key to bring them back"],

	["Frag Grenades", 1, "weapon",
		{ player addMagazines [(missionNamespace getVariable ["ShopFrag", "HandGrenade"]), 2]; },
		{},
		"Two fragmentation grenades"],

	["Body Armor", 2, "passive",
		{ [missionNamespace getVariable ["ShopArmorVest", "V_PlateCarrier2_rgr"]] call Waldo_swapVestKeepCargo; },
		{},
		"A heavy plate carrier - stay standing long enough to catch the traitor"],

	["Medical Kit", 1, "weapon",
		{ player addItem "Medikit"; player addItem "FirstAidKit"; },
		{},
		"A medikit + first aid kit to patch yourself up"],

	["Binoculars", 1, "weapon",
		{ player addWeapon (missionNamespace getVariable ["ShopBinocular", "Binocular"]); },
		{},
		"Binoculars for watching suspects from range"],

	["Night Vision", 1, "weapon",
		{ player addWeapon (missionNamespace getVariable ["ShopNVG", "NVGoggles"]); },
		{},
		"Night-vision goggles - keep watch in the dark"]
];

diag_log "[Waldo] initShops: catalogs ready";
