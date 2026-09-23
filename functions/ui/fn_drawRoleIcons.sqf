//////////////////////////////////////////////////////////////////
// Waldo_fnc_drawRoleIcons
// CLIENT: installs ONE managed Draw3D handler that reveals roles per the
// viewer's own role:
//   - everyone sees the Detective,
//   - Traitors see other Traitors and the Jester in-world (also named
//     outright in the round-start card - Waldo_fnc_assignRoles - so they
//     have a way to avoid the credit penalty for killing them, see
//     Waldo_fnc_onKilled),
//   - Detectives additionally see the role of nearby corpses and of anyone
//     they have "tested".
//   - a dead/spectating viewer is out of the round and sees every living
//     player's role, matching what the on-demand scoreboard (K) already
//     grants them (fn_scoreboard.sqf's _viewerOut) - this is the always-on
//     equivalent for the free spectator camera.
// Labels shrink to a single letter past 25m. Size scales up with distance
// (see _drawTag) - drawIcon3D's size is a world-space fraction, so a fixed
// value shrinks into unreadability with range just like any other object
// would; a near-flat near/far size pair used to make far tags read as
// smaller even though they need to be bigger to stay legible at all. The
// handler id is stored so a second call replaces rather than stacks it.
// No line-of-sight/occlusion gate - a tag is visible through walls/terrain
// rather than risk randomly not showing when it's supposed to (see the
// comment inline below for what that used to chase).
//////////////////////////////////////////////////////////////////

// Replace any previous handler (guards against stacking).
private _old = missionNamespace getVariable ["Waldo_iconsEH", -1];
if (_old >= 0) then { removeMissionEventHandler ["Draw3D", _old]; };

// icon="" (text-only, no real icon) is very likely the source of the
// "Obsolete, sizeH and sizeW calculation missing" spam confirmed live
// (once per frame, per drawn tag - the timing lined up with role
// assignment starting to actually draw tags, not with anything radar-
// related, which fired much later): the engine tries to measure a
// texture's own size to compute an icon's sizeH/sizeW and there's no
// texture to measure when the path is empty. Passing a real (tiny, valid)
// icon path with width/height explicitly 0 keeps the exact same "no
// visible icon, text only" look while giving the engine something real to
// size against.
private _tagIcon = getText (configFile >> "CfgMarkers" >> "mil_dot" >> "icon");
missionNamespace setVariable ["Waldo_roleTagIcon", _tagIcon];

private _eh = addMissionEventHandler ["Draw3D", {

	// Draw a role tag above _pos: a manual black outline layer behind the
	// role-coloured glyph (the bold two-layer look was liked live) at a much
	// smaller, tightly-capped size (confirmed live: the previous pass
	// ballooned to cover the player model at range).
	//
	// The offset/misaligned-double-exposure look from the previous attempt
	// (confirmed live via screenshot) traced to drawIcon3D's OWN shadow=2 on
	// top of the manual black layer underneath - shadow=2 draws its own
	// built-in offset shadow copy, so that was three overlapping renders
	// (manual black layer + engine's own shadow copy + the coloured glyph),
	// not two, and the engine's shadow offset doesn't scale the same way the
	// manual layer's size delta does. Both layers now use shadow=0 - the
	// manual black layer IS the outline, nothing else drawing a second one
	// on top of it.
	private _icon = missionNamespace getVariable ["Waldo_roleTagIcon", ""];
	private _drawTag = {
		params ["_pos", "_color", "_word", "_dist"];
		private _far = _dist > 25;
		// _word is the role id; full localised name up close, the role's
		// stringtable initial (STR_TIA_Role_<role>_Letter) at range.
		private _label = localize format [["STR_TIA_Role_%1", "STR_TIA_Role_%1_Letter"] select _far, _word];
		private _size = (0.035 + (_dist * 0.0008)) min 0.07;
		drawIcon3D [_icon, [0.03, 0.03, 0.03, 1], _pos, 0, 0, 0, _label, 0, _size * 1.12, "PuristaBold", "center"];
		drawIcon3D [_icon, _color, _pos, 0, 0, 0, _label, 0, _size, "PuristaBold", "center"];
	};

	private _myRole = player getVariable ["role", "Innocent"];
	// Dead/spectating: sees everyone, but ONLY when the lobby's "Spectators
	// See All Roles" param is on (off by default - a dead player broadcasting
	// every living role to anyone they talk to, or simply narrating what
	// they see, otherwise leaks exactly the information the round is built
	// around). With it off, a dead viewer falls through to the SAME per-role
	// rules as a living player - _myRole still reads their own role
	// (setVariable persists through death), so a Traitor who dies still sees
	// their fellow Traitors/the Jester in spectator, and everyone still
	// always sees the Detective, same as before they died.
	private _viewerOut = !alive player && {missionNamespace getVariable ["Waldo_spectatorsSeeAllRoles", false]};

	{
		private _eyePos = getPosATL _x;
		_eyePos set [2, (_eyePos select 2) + 2];
		private _dist = player distance _x;

		// No line-of-sight gate. This used to require an unobstructed
		// checkVisibility raycast, which chased three different false
		// negatives across live testing - lighting (fixed: FIRE LOD not
		// VIEW), range flakiness, and incidental geometry (a leaf, a fence
		// rail) blocking a sightline a player could plainly see past. A tag
		// that's SUPPOSED to be showing but randomly isn't is a worse bug
		// than a tag that's technically visible through a wall - reliability
		// wins here, so the check is gone rather than patched a fourth time.
		if (_x != player) then {
			private _xRole = _x getVariable ["role", "Innocent"];

			if (_viewerOut) then {
				if (alive _x) then {
					[_eyePos, ([_xRole] call Waldo_roleColor), _xRole, _dist] call _drawTag;
				};
			} else {
				// Everyone sees the Detective.
				if (_xRole == "Detective") then {
					[_eyePos, ([_xRole] call Waldo_roleColor), "Detective", _dist] call _drawTag;
				};
				// Traitors see other Traitors.
				if (_xRole == "Traitor" && {_myRole == "Traitor"}) then {
					[_eyePos, ([_xRole] call Waldo_roleColor), "Traitor", _dist] call _drawTag;
				};
				// Traitors see the Jester too (in-world only, not by name).
				if (_xRole == "Jester" && {_myRole == "Traitor"}) then {
					[_eyePos, ([_xRole] call Waldo_roleColor), "Jester", _dist] call _drawTag;
				};
			};
		};
	} forEach allUnits;

	// Detective-only reveals.
	if (_myRole == "Detective") then {
		// Nearby corpses.
		{
			private _eyePos = getPosATL _x;
			_eyePos set [2, (_eyePos select 2) + 2];
			private _dist = player distance _x;
			if (_dist < 6) then {
				private _role = _x getVariable ["role", "Innocent"];
				[_eyePos, ([_role] call Waldo_roleColor), _role, _dist] call _drawTag;
			};
		} forEach allDeadMen;

		// Anyone the detective has tested stays revealed.
		{
			if (_x getVariable ["tested", false]) then {
				private _eyePos = getPosATL _x;
				_eyePos set [2, (_eyePos select 2) + 2];
				private _role = _x getVariable ["role", "Innocent"];
				private _dist = player distance _x;
				[_eyePos, ([_role] call Waldo_roleColor), _role, _dist] call _drawTag;
			};
		} forEach (allUnits + allDeadMen);
	};

}];

missionNamespace setVariable ["Waldo_iconsEH", _eh];
