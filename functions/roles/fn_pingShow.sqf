//////////////////////////////////////////////////////////////////
// Waldo_fnc_pingShow
// CLIENT: displays a traitor coordination ping (from Waldo_fnc_traitorPing) for
// ~15 seconds. Only ever remote-executed onto Traitor machines.
//
// params: [_from, _kind, _where]
//   _kind  : "Target" (tracks a living unit live, orange marker, labelled
//            TARGET) | "Location" | "Danger" | "Regroup Here" | "Enemy Spotted"
//            (all four: a static point, differing only by colour/label).
//   _where : the targeted unit (Target) or a position (everything else).
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};
params ["_from", "_kind", "_where"];

private _isTarget = _kind == "Target";

// Per-kind styling: 3D icon colour + label prefix, map marker colour. Icon
// SHAPE reuses only the two vanilla marker icons already confirmed to render
// correctly in-game (dot_ca / destroy_ca) - kinds are told apart by colour and
// label instead of guessing at unverified vanilla icon paths.
private _style = switch (_kind) do {
	case "Target":        { [[1, 0.55, 0.05, 1],   "ColorOrange", "STR_TIA_Ping_TagTarget"] };
	case "Danger":        { [[1, 0.1, 0.1, 1],     "ColorRed",    "STR_TIA_Ping_TagDanger"] };
	case "Regroup Here":  { [[0.15, 0.75, 0.35, 1], "ColorGreen",  "STR_TIA_Ping_TagRegroup"] };
	case "Enemy Spotted": { [[1, 0.85, 0.05, 1],    "ColorYellow", "STR_TIA_Ping_TagEnemy"] };
	default               { [[0.85, 0.2, 0.2, 1],   "ColorRed",    "STR_TIA_Ping_TagPing"] };   // "Location"
};
_style params ["_color", "_markerColor", "_prefixKey"];
private _prefix = localize _prefixKey;
private _icon = ["\A3\ui_f\data\map\markers\military\dot_ca.paa", "\A3\ui_f\data\map\markers\military\destroy_ca.paa"] select _isTarget;

[_from, _isTarget, _where, _color, _icon, _prefix, _markerColor] spawn {
	params ["_from", "_isTarget", "_where", "_color", "_icon", "_prefix", "_markerColor"];
	private _sender = name _from;

	private _mk = format ["ttt_ping_%1_%2", _sender, round (diag_tickTime * 100)];

	private _eh = addMissionEventHandler ["Draw3D", {
		_thisArgs params ["_isTarget", "_where", "_color", "_icon", "_sender", "_mk", "_prefix"];
		private _valid = if (_isTarget) then { !isNull _where && {alive _where} } else { true };
		if (_valid) then {
			private _p = if (_isTarget) then { (getPosATL _where) vectorAdd [0,0,2] } else { _where };
			private _tag = format [localize "STR_TIA_Ping_WorldTag", _prefix, _sender];
			drawIcon3D [_icon, _color, _p, 1, 1, 0, _tag, 1, 0.04, "PuristaBold"];
			// A target ping is meant to track a moving person, not just the spot
			// they were standing in when pinged - keep the map marker glued to
			// them every frame, same as the 3D world icon already does.
			if (_isTarget) then { _mk setMarkerPosLocal (getPosATL _where); };
		};
	}, [_isTarget, _where, _color, _icon, _sender, _mk, _prefix]];

	private _mkPos = if (_isTarget) then { getPosATL _where } else { _where };
	createMarkerLocal [_mk, _mkPos];
	_mk setMarkerTypeLocal (["mil_dot", "mil_destroy"] select _isTarget);
	_mk setMarkerColorLocal _markerColor;
	_mk setMarkerTextLocal format [localize "STR_TIA_Ping_MapTag", _prefix, _sender];

	sleep 15;

	removeMissionEventHandler ["Draw3D", _eh];
	deleteMarkerLocal _mk;
};
