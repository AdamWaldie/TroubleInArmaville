//////////////////////////////////////////////////////////////////
// Waldo_fnc_scoreboard
// CLIENT: toggles an IN-ROUND scoreboard (bound to K). Lists every player with
// their alive/dead status, whether their body has been FOUND, and their role
// — but role is shown only where the viewer is allowed to know it: own role;
// any player once a Detective has identified their body (Waldo_roleRevealed
// - publicly "confirmed"); the public Detective; Traitors see fellow
// Traitors + the Jester (never the reverse - the Jester does not see
// Traitors here, matching Waldo_fnc_drawRoleIcons); and a dead viewer (out
// of the round) sees everything. Per-round kill counts are shown ONLY to a
// dead/spectating viewer - a live player never sees anyone's kill tally,
// theirs included, since that number is its own metagaming tell regardless
// of whether the role itself is hidden. Nothing is tracked between rounds.
//
// Being dead alone no longer reveals a role - identification does (see
// Waldo_fnc_identifyBody), matching the Detective-only role-reveal design.
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};
disableSerialization;

// Toggle closed if already open.
if !(isNull (uiNamespace getVariable ["WaldoScore", displayNull])) exitWith { closeDialog 1; };

private _myRole    = player getVariable ["role", "Innocent"];
// Dead players only see everything when the lobby's "Spectators See All
// Roles" param is on (off by default) - same gate as Waldo_fnc_drawRoleIcons,
// so the on-demand scoreboard and the always-on 3D tags never disagree.
// With it off, _reveal below still falls through on its own per-role terms
// (own role, Detective, Traitor-sees-Traitor/Jester), which is what keeps a
// dead Traitor seeing their team here too.
private _viewerOut = !alive player && {missionNamespace getVariable ["Waldo_spectatorsSeeAllRoles", false]};
// Separate from role visibility entirely: a per-round kill tally is its own
// tell (a suspiciously active "Innocent" this round is exactly the kind of
// metagaming clue an alive player shouldn't get handed on a silver platter
// mid-round). Spectators - genuinely out of the round, nothing left for
// them to act on - still get it, same reasoning as their broader
// Waldo_spectatorsSeeAllRoles carve-out above, just unconditional since
// there's no equivalent "own role" exception needed for a number.
private _viewerIsSpectator = !alive player;
private _traitors  = missionNamespace getVariable ["TraitorList", []];
private _detectives = missionNamespace getVariable ["DetectiveList", []];
private _jesters    = missionNamespace getVariable ["JesterList", []];

private _rowFor = {
	params ["_p"];
	private _role     = _p getVariable ["role", "Innocent"];
	private _alive    = alive _p;
	private _kills    = _p getVariable ["Waldo_roundKills", 0];
	private _found    = _p getVariable ["Waldo_identified", false];
	private _revealed = _p getVariable ["Waldo_roleRevealed", false];   // Detective-confirmed -> public knowledge

	private _reveal = (_p == player)
		|| _viewerOut
		|| _revealed
		|| (_role == "Detective")
		|| {_myRole == "Traitor" && {(_p in _traitors) || {_role == "Jester"}}};

	private _roleTxt = if (_reveal) then {
		toUpper ((localize ("STR_TIA_Role_" + _role)) + (["", " " + localize "STR_TIA_Score_Confirmed"] select _revealed))
	} else { localize "STR_TIA_Score_Unknown" };
	// Waldo_roleColorHex, not a locally hardcoded map - this used to be its
	// own switch with fixed hex values, which meant the scoreboard's role
	// colours silently ignored the colourblind-accessibility setting every
	// other role-coloured surface in this HUD (radar, HUD crest, shop, ping
	// wheel) already respects.
	private _hex     = if (_reveal) then { [_role] call Waldo_roleColorHex } else { "#9EA290" };
	private _status  = if (_alive) then {
		format ["<t color='#6FCB74'>%1</t>", localize "STR_TIA_Score_Alive"]
	} else {
		if (_found) then { format ["<t color='#F2BE55'>%1</t>", localize "STR_TIA_Score_Found"] } else { format ["<t color='#9EA290'>%1</t>", localize "STR_TIA_Score_Missing"] };
	};
	private _killsTxt = if (_viewerIsSpectator) then { format [localize "STR_TIA_Score_Kills", format ["<t color='#F2BE55'>%1</t>", _kills]] } else { "" };

	format [
		"<t size='1.05' color='#F2EFE3'>%1</t>    %2    <t color='%3'>%4</t>    %5<br/>",
		name _p, _status, _hex, _roleTxt, _killsTxt
	]
};

// Living first, then the dead.
private _live = allPlayers select { alive _x };
private _dead = allPlayers select { !alive _x };
private _body = "";
{ _body = _body + ([_x] call _rowFor); } forEach (_live + _dead);
if (_body == "") then { _body = format ["<t color='#9EA290'>%1</t>", localize "STR_TIA_Score_NoPlayers"]; };

createDialog "WaldoScore";
waitUntil { !isNull (uiNamespace getVariable ["WaldoScore", displayNull]) };
private _display = uiNamespace getVariable "WaldoScore";

// Let K close it too (the main handler can't fire while a dialog is focused).
_display displayAddEventHandler ["KeyDown", { if ((_this select 1) == 37) then { closeDialog 1; true } else { false } }];

// "Confirmed" here means called-in (Waldo_identified), matching the wiki's own
// wording - identifying a body "always confirms the death to the whole
// server" regardless of who calls it in. Waldo_roleRevealed is a stricter,
// Detective-only flag; keying the header count on that instead meant a
// regular player's call-in updated the per-row FOUND status but never moved
// this count, reading as "the scoreboard does nothing for it."
private _confirmedDead = { !alive _x && {_x getVariable ["Waldo_identified", false]} } count allPlayers;
(_display displayCtrl 3301) ctrlSetText format [
	localize "STR_TIA_Score_Header",
	count _live, count allPlayers, _confirmedDead
];
(_display displayCtrl 3300) ctrlSetStructuredText parseText _body;

// "Your Briefing" panel (idc 3330) - the same content the round-start card
// showed (Waldo_fnc_showRoleCard), re-viewable any time from here so
// missing/forgetting the transient notification doesn't lose it for the
// round. Redaction happens HERE, the same way the row-by-row _reveal rule
// above does - Traitors get their teammates (+ the Jester if one exists),
// everyone gets the public Detective's name, nobody outside the Traitor
// team gets the Jester's name, only that one exists. Never derived from
// anything the server didn't already broadcast to every client as public
// data (TraitorList/DetectiveList/JesterList) - this is a display filter
// over that, exactly like every other role-visibility check in this file.
private _briefMates = if (_myRole == "Traitor") then { (_traitors - [player]) apply { name _x } } else { [] };
private _briefDetName = if (count _detectives > 0) then { name (_detectives select 0) } else { "" };
private _briefJesterExists = count _jesters > 0;
private _briefJesterName = if (_myRole == "Traitor" && {_briefJesterExists}) then { name (_jesters select 0) } else { "" };
private _briefText = [_myRole, _briefMates, _briefDetName, _briefJesterExists, _briefJesterName] call Waldo_fnc_roleBriefingText;
(_display displayCtrl 3330) ctrlSetStructuredText parseText _briefText;

// Keybind reference panel (attached to the right edge, idc 3320) - same
// per-role list the top bar shows (Waldo_keyHintsFor), just stacked vertically
// here since this panel is tall and narrow rather than wide and short.
private _kbList = [_myRole] call Waldo_keyHintsFor;
private _kbBody = "";
// Colon separator, not bracket-wrapped: the dev keys ARE literally "[" and
// "]", and wrapping them ("[%1]") produces the same "[[]"/"[]]" collision
// fixed in the top bar's own keybind row (fn_initHud.sqf) - a colon has no
// such collision with any key label.
{ _x params ["_key", "_label"]; _kbBody = _kbBody + format ["<t color='#F2BE55'>%1:</t> %2<br/>", _key, _label]; } forEach _kbList;
(_display displayCtrl 3320) ctrlSetStructuredText parseText _kbBody;
