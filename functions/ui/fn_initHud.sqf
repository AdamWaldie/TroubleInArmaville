//////////////////////////////////////////////////////////////////
// Waldo_fnc_initHud
// CLIENT: shows the role badge (bottom-right) tinted by role, and a live
// credits readout for Traitors/Detectives.
//////////////////////////////////////////////////////////////////

disableSerialization;

// titleRsc recreates the display (a NEW object) every time it's called for
// the same class, rather than reusing whatever's already showing - and this
// function re-runs on every respawn and every debug role switch. Calling it
// unconditionally meant every one of those re-runs silently orphaned the
// PREVIOUS display: this function itself re-fetches _display fresh each time
// so its own controls (badge/credits/keybind row) kept working, but anything
// that captured a reference ONCE and kept it across time - the top bar's
// timer loop (Waldo_fnc_topBarTimer), started once and never re-fetching -
// was left writing to an orphaned, invisible display while the real one sat
// at its blank .hpp default forever. Only ever calling titleRsc when the
// resource doesn't already exist keeps the SAME display alive for the whole
// round, so every control reference taken anywhere stays valid.
if (isNull (uiNamespace getVariable ["TTTHud", displayNull])) then {
	titleRsc ["TTTHud", "PLAIN", 1, false];
};
waitUntil { !isNull (uiNamespace getVariable ["TTTHud", displayNull]) };
private _display = uiNamespace getVariable "TTTHud";

// The ping picker's controls live inside this same resource (see TTTHud in
// ui/TTTHud.hpp), which is created fresh for EVERY player at round start
// regardless of role - nothing ever defaulted it to hidden, so it sat there
// visible and empty for everyone until their first T hold. Waldo_fnc_pingWheelOpen
// is the only thing that should ever show it again after this.
(_display displayCtrl 3520) ctrlShow false;
Waldo_pingWheelOpen = false;

private _role = player getVariable ["role", "Innocent"];
private _color = [_role] call Waldo_roleColor;

// ============================================================================
// Selectable role crest style - entirely a per-player preference, not a
// server/lobby setting (there is no RoleCrestStyle mission param).
//
// Styles 1-8 are drawn artwork (ui/crests/*.paa), not arrangements of rects.
// Three thematic wells, per direction - GMod-TTT heritage, Armaville military
// identity, TTT evidence:
//
//                     idc 999/1000/1001/1272.
//   1 Struck Coin   - milled rim, recessed field, exergue at the foot
//   1 Enamel Pin    - cloisonne enamel in a brass cloison
//   2 Dog Tag       - brushed steel on a bead chain, hole punched through
//   3 Unit Patch    - satin stitch, merrowed amber edge
//   4 Crate Stencil - spray through a stencil; the glyph is the UNPAINTED part
//   5 Case File     - rubber clearance stamp on manila
//   6 Chalk Mark    - chalk on asphalt
//   7 Evidence Tag  - manila tag, brass eyelet punched top-right, string
//
// Each is three RscPictures: a base under the role element, a luminance-only role
// layer that ctrlSetTextColor multiplies to the role colour, and a detail layer
// over the top whose fixed colours (amber fittings, brass, chain) must NOT be
// tinted. That split is the whole reason a crest can be role-coloured and still
// keep fixed amber detailing.
//
// Waldo_roleCrestStylePref lives in THIS client's own profileNamespace (set via
// the H key -> Waldo_fnc_openStylePicker), so it's saved across sessions and
// never broadcast or read from anywhere else.
// ============================================================================
private _style = profileNamespace getVariable ["Waldo_roleCrestStylePref", 0];
// Original and Field Medallion both use the badge ring. Field Medallion's whole
// idea is to BE Original with a nameplate under it, so it inherits the same
// medallion - textures and tuned position included. Styles 2-9 are drawn crests
// and replace it outright.
// Only Field Medallion (slot 0) uses the badge ring. Styles 1-8 are drawn crests
// and replace it outright.
private _usesRing = (_style == 0);

{ (_display displayCtrl _x) ctrlShow _usesRing; } forEach [1272, 999, 1000, 1001];
// Original's full-width credits pill is retired with Original itself - Field
// Medallion carries the balance in its nameplate instead. Kept declared but always
// hidden rather than deleted, so the controls are there if a future style wants a
// pill again.
{ (_display displayCtrl _x) ctrlShow false; } forEach [1002, 1003, 1004, 1005, 1006];

if (_usesRing) then {
	// GMod-style role crest: tint the circular badge and centre the role's
	// letter (T / D / I / J) in it.
	(_display displayCtrl 1000) ctrlSetTextColor _color;
	private _badge = _display displayCtrl 1001;
	_badge ctrlSetTextColor _color;
	_badge ctrlSetText toUpper (_role select [0, 1]);

	// Set explicitly rather than left to the hpp's sizeEx. Styles 0 and 1 share
	// this one control, and ctrlTextHeight below only reports a height for the
	// size actually in effect - leaving it implicit would make the centring
	// depend on whether some earlier call had changed it.
	_badge ctrlSetFontHeight (0.088 * safezoneH);

	// Real measured vertical centring, not a guessed offset: ST_VCENTER does NOT
	// mean "centre vertically" despite the name - BIKI documents it (with
	// ST_UP/ST_DOWN) as a vertical/rotated TEXT ORIENTATION mode that "should
	// not be mixed with any other styles", which is exactly what this control
	// used to do (ST_CENTER + ST_VCENTER) and almost certainly why the letter
	// rendered badly off-position rather than just high/low by a few pixels.
	// ctrlTextHeight reads back the engine's own actual rendered height for the
	// text just set, so this centres correctly regardless of the font's real
	// metrics instead of assuming a line-height ratio.
	private _badgeX = (safezoneW + safezoneX) - (0.175 * safezoneH);
	private _badgeY = (safezoneH + safezoneY) - (0.185 * safezoneH);
	private _badgeSize = 0.15 * safezoneH;
	private _textH = ctrlTextHeight _badge;

	// J's hook-shaped tail sits toward the bottom-right of its bounding box, so a
	// geometrically-centred J still reads as drifted right - unlike vertical
	// centring above, there's no engine measurement for "optical" glyph weight,
	// so this is a small eyeballed nudge specific to that one letter, not a
	// general formula. Confirmed live that the first attempt (-0.006) overshot
	// and put it too far left - halved rather than re-guessed from scratch.
	private _opticalNudgeX = if (_role == "Jester") then { -0.003 * safezoneH } else { 0 };

	_badge ctrlSetPosition [_badgeX + _opticalNudgeX, _badgeY + ((_badgeSize - _textH) / 2), _badgeSize, _textH];
	_badge ctrlCommit 0;
};

// Only Traitor/Detective have credits at all, so every style's credit-only
// controls (not just their text) are hidden for everyone else instead of
// sitting there empty.
private _hasCredits = _role in ["Traitor", "Detective"];

// _styleAlways/_styleCredits are idc's grouped by style index (0..8). Every
// control across every style is shown/hidden exactly once per call: the first
// pass hides every style except the selected one, the second then re-hides the
// selected style's credit-only controls if this role has none.
//
// Nothing in _styleCredits is a bordered sub-panel or an inset pocket - each
// entry is either transparent text sitting over a plate the style already
// fills, or (styles 1 and 2) an amber divider/rule whose whole job is to split
// off the balance's half of the composition. That's what makes the credits
// omittable without notice: hide them and the plate is simply plain, with no
// hole where a panel used to be.
private _styleAlways = [
	[1290, 1291, 1292, 1293],          // 0 - Field Medallion: nameplate under the ring
	[1300, 1301, 1302, 1303],                  // 1 - struckCoin
	[1310, 1311, 1312, 1313],                  // 2 - enamelPin
	[1320, 1321, 1322, 1323],                  // 3 - dogTag
	[1330, 1331, 1332, 1333],                  // 4 - unitPatch
	[1340, 1341, 1342, 1343],                  // 5 - crateStencil
	[1350, 1351, 1352, 1353],                  // 6 - caseFile
	[1360, 1361, 1362, 1363],                  // 7 - chalkMark
	[1370, 1371, 1372, 1373]                  // 8 - evidenceTag
];
private _styleCredits = [
	[1294, 1295],                      // 0 - amber tick + balance in the nameplate's right half
	[1304, 1305, 1306],                    // 1 - struckCoin
	[1314, 1315, 1316],                    // 2 - enamelPin
	[1324, 1325, 1326],                    // 3 - dogTag
	[1334, 1335, 1336],                    // 4 - unitPatch
	[1344, 1345, 1346],                    // 5 - crateStencil
	[1354, 1355, 1356],                    // 6 - caseFile
	[1364, 1365, 1366],                    // 7 - chalkMark
	[1374, 1375, 1376]                    // 8 - evidenceTag
];

{
	private _isActiveStyle = (_forEachIndex == _style);
	{ (_display displayCtrl _x) ctrlShow _isActiveStyle; } forEach _x;
} forEach _styleAlways;
{
	private _show = (_forEachIndex == _style) && _hasCredits;
	{ (_display displayCtrl _x) ctrlShow _show; } forEach _x;
} forEach _styleCredits;

// The role colour is applied by tinting exactly ONE control per style: the crest's
// role layer. ctrlSetTextColor on an RscPicture multiplies the texture, and that
// layer is authored as luminance only, so multiplying it produces the role colour
// with the material's own shading intact.
//
// The base and detail layers are deliberately never touched. They hold the fixed
// colours - amber fittings, brass eyelet, bead chain, manila card, crate plank,
// asphalt - and tinting them would collapse each crest to a single hue, which is
// the exact failure the drawn artwork exists to avoid.
if (_style > 0) then {
	private _roleLayer = switch (_style) do {
		case 1: { 1301 };
		case 2: { 1311 };
		case 3: { 1321 };
		case 4: { 1331 };
		case 5: { 1341 };
		case 6: { 1351 };
		case 7: { 1361 };
		case 8: { 1371 };
	};
	(_display displayCtrl _roleLayer) ctrlSetTextColor _color;
};
// Original's own role-tinted parts: the badge ring is handled in the _usesRing
// block above, so this is just its credits pill's accent line.
// Original's credits-pill accent line, and Field Medallion's nameplate accent
// line. Both are flat rects rather than a texture layer, so they take a
// background colour, not a text colour.
if (_style == 0) then {
	(_display displayCtrl 1292) ctrlSetBackgroundColor [_color select 0, _color select 1, _color select 2, 1];
};

// Styles 2-9's letter. The box and size are MEASURED, not chosen:
// tools/crestart/fitletters.py takes each crest's body mask, subtracts the
// balance band, grows the largest rectangle that stays wholly inside it, and
// verifies the glyph is contained. This table is generated from that output, so it
// can't drift from the artwork.
//
// The letter's colour differs per crest, and that matters more than it sounds. The
// material already carries the role colour, so a role-tinted letter on a
// role-coloured field half-vanishes:
//   "cream" - a knockout, where the letter sits on the role element itself
//   "role"  - ink, for the two paper crests where the letter sits on pale card
//   "plank" - the crate's own olive, because on a real stencil the glyph is the
//             UNPAINTED part showing the surface through it
if (_style > 0) then {
	// [letter idc, xOff, yOff, w, h, sizeEx, colour] - offsets/sizes in safezoneH
	// from the badge anchor, matching the hpp block exactly.
	private _letterBox = switch (_style) do {
		case 1: { [1303, 0.039922, 0.038047, 0.080156, 0.080156, 0.072734, "cream"] };   // struckCoin
		case 2: { [1313, 0.038437, 0.038789, 0.083125, 0.083125, 0.074961, "cream"] };   // enamelPin
		case 3: { [1323, 0.0325, 0.062539, 0.089063, 0.038594, 0.034883, "cream"] };   // dogTag
		case 4: { [1333, 0.026562, 0.034336, 0.10687, 0.068281, 0.061602, "cream"] };   // unitPatch
		case 5: { [1343, 0.013203, 0.044727, 0.13359, 0.068281, 0.061602, "plank"] };   // crateStencil
		case 6: { [1353, 0.051797, 0.040273, 0.062344, 0.050469, 0.045273, "role"] };   // caseFile
		case 7: { [1363, 0.031016, 0.041016, 0.097969, 0.083125, 0.074961, "cream"] };   // chalkMark
		case 8: { [1373, 0.060703, 0.052891, 0.053437, 0.0475, 0.043047, "role"] };   // evidenceTag
	};
	_letterBox params ["_lIdc", "_lX", "_lY", "_lW", "_lH", "_lSize", "_lColour"];

	private _letter = _display displayCtrl _lIdc;
	_letter ctrlSetTextColor (switch (_lColour) do {
		case "role":  { _color };
		case "plank": { [0.227, 0.243, 0.165, 1] };
		default       { [0.95, 0.93, 0.86, 1] };
	});
	// The initial comes from the stringtable (STR_TIA_Role_<role>_Letter) rather
	// than the first character of the localised name: the letter boxes above
	// were measured for a single Latin-width glyph, so translators pick a
	// single glyph that fits (and the Jester nudge below still keys off the
	// role, not the letter).
	_letter ctrlSetText toUpper localize format ["STR_TIA_Role_%1_Letter", _role];
	// Before ctrlTextHeight, always - that command reports the height of the text
	// at whatever size is in effect, so measuring first centres against the wrong
	// size.
	_letter ctrlSetFontHeight (_lSize * safezoneH);
	private _lTextH = ctrlTextHeight _letter;
	// Same eyeballed optical nudge Original needs: J's hook-shaped tail sits toward
	// the bottom-right of its bounding box, so a geometrically centred J still reads
	// as drifted right. There's no engine measurement for optical glyph weight the
	// way there is for height, so this stays a small constant for that one letter.
	private _lNudge = if (_role == "Jester") then { -0.003 * safezoneH } else { 0 };
	_letter ctrlSetPosition [
		((safezoneW + safezoneX) - (0.175 * safezoneH)) + (_lX * safezoneH) + _lNudge,
		((safezoneH + safezoneY) - (0.185 * safezoneH)) + (_lY * safezoneH) + (((_lH * safezoneH) - _lTextH) / 2),
		_lW * safezoneH,
		_lTextH
	];
	_letter ctrlCommit 0;
};

// Field Medallion's nameplate carries the role's NAME, not its initial - the
// medallion above it already shows the letter, so repeating it would waste the
// bar. Set once here since it never changes for this HUD instance. Its box shrinks
// to the bar's left half when there's a balance to sit beside, and takes the whole
// bar when there isn't, so the plate never reads as half-empty.
if (_style == 0) then {
	private _name = _display displayCtrl 1293;
	_name ctrlSetText toUpper localize ("STR_TIA_Role_" + _role);
	private _nH = ctrlTextHeight _name;
	private _nX = if (_hasCredits) then { 0.004 } else { 0 };
	private _nW = if (_hasCredits) then { 0.080 } else { 0.150 };
	_name ctrlSetPosition [
		((safezoneW + safezoneX) - (0.175 * safezoneH)) + (_nX * safezoneH),
		((safezoneH + safezoneY) - (0.185 * safezoneH)) + (0.152 * safezoneH) + (((0.026 * safezoneH) - _nH) / 2),
		_nW * safezoneH,
		_nH
	];
	_name ctrlCommit 0;
};

// Credits text/tint per style - only runs for roles that actually have
// credits (_hasCredits), matching the idc's shown by the pass above.
if (_hasCredits) then {
	// idc of the control that actually displays the balance for the active
	// style, plus the box it should be centred in (offsets in safezoneH from
	// the badge anchor, matching that style's hpp geometry) and the format its
	// width can actually fit.
	//
	// NEVER tinted to the role colour - every role colour is a fairly dark,
	// saturated tone, and every one of these sits on a near-black plate, so
	// role-tinted credit text was low-contrast (worst on Traitor red, but
	// Detective/Jester weren't much better) no matter which style. They keep
	// their hpp-declared cream instead, which is high-contrast on near-black
	// regardless of role. This is the one deliberate deviation from Original's
	// exact original behaviour (which did tint 1002), kept because it's a real
	// contrast fix rather than a style change.
	//
	// Every one of these controls is ST_CENTER with no ST_VCENTER (that flag is
	// a vertical/rotated TEXT ORIENTATION mode, not "centre vertically" - see
	// the long comment above roleText in TTTHud.hpp), so they need the same real
	// ctrlTextHeight centring the letters get, redone every tick since the
	// text's rendered height changes as the number grows.
	//
	// Style 0 included. ST_CENTER only ever centred it horizontally, so its
	// balance had always rendered against the top of a 0.03H pill with all the
	// slack below it - visibly high in its own casing. Nothing about Original's
	// design intended that; it's the same measure-don't-guess fix the rest of
	// this HUD already had, applied to the one control that never got it.
	private _creditBox = switch (_style) do {
		case 0: { [1295, 0.086, 0.152, 0.060, 0.026, "STR_TIA_Hud_CreditsShort"] };   // Field Medallion
		case 1: { [1306, 0.020625, 0.12711, 0.11875, 0.02375, "STR_TIA_Hud_CreditsShort"] };   // struckCoin
		case 2: { [1316, 0.023594, 0.12934, 0.11281, 0.019297, "STR_TIA_Hud_CreditsShort"] };   // enamelPin
		case 3: { [1326, 0.019141, 0.10781, 0.12172, 0.017813, "STR_TIA_Hud_CreditsShort"] };   // dogTag
		case 4: { [1336, 0.0325, 0.1093, 0.095, 0.017813, "STR_TIA_Hud_CreditsShort"] };   // unitPatch
		case 5: { [1346, 0.019141, 0.11969, 0.12172, 0.017813, "STR_TIA_Hud_CreditsShort"] };   // crateStencil
		case 6: { [1356, 0.0072656, 0.14344, 0.14547, 0.017813, "STR_TIA_Buy_Credits"] };   // caseFile
		case 7: { [1366, 0.026562, 0.14641, 0.10687, 0.019297, "STR_TIA_Buy_Credits"] };   // chalkMark
		case 8: { [1376, 0.045859, 0.14344, 0.080156, 0.019297, "STR_TIA_Hud_CreditsShort"] };   // evidenceTag
		// 0 - Original. Keeps its own lowercase "%1 credits" wording rather than
		// being normalised to the other styles' CR/CREDITS - the full-width pill has
		// room for it, and it's part of what the style is.
		default { [1002, 0, -0.040, 0.150, 0.030, "STR_TIA_Hud_CreditsLower"] };
	};
	_creditBox params ["_creditTextIdc", "_cX", "_cY", "_cW", "_cBoxH", "_cFormat"];
	_cFormat = localize _cFormat;   // table holds stringtable keys
	private _credits = _display displayCtrl _creditTextIdc;

	// Token-guarded the same way the keybind-hint fade below is (and for the
	// same reason): this function re-runs on every respawn and every debug
	// role switch, and this spawn had no guard at all - each call stacked
	// another concurrent 0.5s polling loop on top of whatever earlier ones
	// hadn't exited yet (they only exit once ctrlParent is null or the
	// player is dead), so rapid role cycling piled up redundant loops all
	// fighting to set the same control's text.
	private _creditsTickerToken = (_display getVariable ["Waldo_creditsTickerToken", 0]) + 1;
	_display setVariable ["Waldo_creditsTickerToken", _creditsTickerToken];

	private _vX = ((safezoneW + safezoneX) - (0.175 * safezoneH)) + (_cX * safezoneH);
	private _vY = ((safezoneH + safezoneY) - (0.185 * safezoneH)) + (_cY * safezoneH);
	private _vW = _cW * safezoneH;
	private _vBoxH = _cBoxH * safezoneH;

	[_credits, _cFormat, _display, _creditsTickerToken, _vX, _vY, _vW, _vBoxH] spawn {
		params ["_credits", "_format", "_display", "_token", "_vX", "_vY", "_vW", "_vBoxH"];
		while {
			!isNull ctrlParent _credits
			&& {alive player}
			&& {(_display getVariable ["Waldo_creditsTickerToken", 0]) == _token}
		} do {
			_credits ctrlSetText format [_format, player getVariable ["points", 0]];
			private _h = ctrlTextHeight _credits;
			_credits ctrlSetPosition [_vX, _vY + ((_vBoxH - _h) / 2), _vW, _h];
			_credits ctrlCommit 0;
			sleep 0.5;
		};
	};
};

// Top bar keybind row: a normal game gives no other indication of what's
// bound, so list whatever's actually relevant to this role (Waldo_keyHintsFor,
// shared with the scoreboard's own keybind panel). This re-runs on every
// debug role switch / respawn (same as the badge above), so it never shows a
// stale role's binds - each redraw also restarts the fade-out from fully
// visible, below.
//
// "%1: %2" (not "[%1] %2"): the dev keys ARE literally "[" and "]", so
// bracket-wrapping them produced the nonsensical "[[] Dev Menu" / "[]] Cycle
// Role" - a colon separator has no such collision with any key label.
//
// Two lines, not one: CT_STATIC never wraps (just cuts overflow), and 7 items
// under Testing Mode never fit one line at a readable size - split evenly
// across topBarHintText/topBarHintText2 (idc 3612/3613).
//
// Deliberately plain RscText (ctrlSetText) for both, not structured text with
// coloured <t> spans: needs precise centring via ctrlTextHeight (same fix as
// roleText above), and structured text was never verified to interact
// correctly with that command - safer to keep "needs colour" and "needs
// precise centring" apart than risk a repeat of this session's
// CT_STRUCTURED_TEXT/ST_VCENTER surprises.
private _hintsList = [_role] call Waldo_keyHintsFor;
private _half = ceil ((count _hintsList) / 2);
private _line1 = "";
private _line2 = "";
{
	_x params ["_key", "_label"];
	private _entry = format [localize "STR_TIA_Hud_KeyHint", _key, _label] + "     ";
	if (_forEachIndex < _half) then { _line1 = _line1 + _entry; } else { _line2 = _line2 + _entry; };
} forEach _hintsList;

private _hintBoxX = ((safezoneX + (0.5 * safezoneW)) - (0.18 * safezoneW)) + (0.015 * safezoneW);
private _hintBoxW = (0.36 * safezoneW) - (0.030 * safezoneW);
private _hintRowH = 0.0375 * safezoneH;
private _hintRow1Y = (safezoneY + (0.015 * safezoneH)) + (0.068 * safezoneH);
private _hintRow2Y = _hintRow1Y + _hintRowH;

private _hintTextCtrl = _display displayCtrl 3612;
private _hintText2Ctrl = _display displayCtrl 3613;
_hintTextCtrl ctrlSetText _line1;
_hintText2Ctrl ctrlSetText _line2;

{
	_x params ["_ctrl", "_rowY"];
	private _h = ctrlTextHeight _ctrl;
	_ctrl ctrlSetPosition [_hintBoxX, _rowY + ((_hintRowH - _h) / 2), _hintBoxW, _h];
	_ctrl ctrlCommit 0;
} forEach [[_hintTextCtrl, _hintRow1Y], [_hintText2Ctrl, _hintRow2Y]];

// Visible for a few seconds after every (re)draw - a fresh round start or a
// role change is exactly when this is worth glancing at - then fades out
// COMPLETELY (box and both text lines alike, not just dimmed to a resting
// alpha): this is a one-time reminder, not a permanent reference (that's what
// the scoreboard's own keybind panel is for). A token guard (same idiom as
// WaldosMissionPack's SafeStart countdown, Waldo_SafeStart_TimerToken) stops
// an in-flight fade from a PREVIOUS redraw from clobbering a fresh one if
// this function re-runs again (rapid role changes / quick respawns) before
// the last fade finished.
private _hintShadowCtrl = _display displayCtrl 3610;
private _hintBgCtrl = _display displayCtrl 3611;
_hintShadowCtrl ctrlSetBackgroundColor [0, 0, 0, 0.55];
_hintShadowCtrl ctrlCommit 0;
_hintBgCtrl ctrlSetBackgroundColor [0.105, 0.11, 0.095, 0.85];
_hintBgCtrl ctrlCommit 0;
_hintTextCtrl ctrlSetTextColor [0.95, 0.93, 0.86, 1];
_hintTextCtrl ctrlCommit 0;
_hintText2Ctrl ctrlSetTextColor [0.95, 0.93, 0.86, 1];
_hintText2Ctrl ctrlCommit 0;

private _hintFadeToken = (_display getVariable ["Waldo_hintFadeToken", 0]) + 1;
_display setVariable ["Waldo_hintFadeToken", _hintFadeToken];
[_hintShadowCtrl, _hintBgCtrl, _hintTextCtrl, _hintText2Ctrl, _display, _hintFadeToken] spawn {
	params ["_shadowCtrl", "_bgCtrl", "_textCtrl", "_text2Ctrl", "_display", "_token"];
	sleep 8;
	if (isNull _shadowCtrl || {isNull _bgCtrl} || {isNull _textCtrl} || {isNull _text2Ctrl}) exitWith {};
	if ((_display getVariable ["Waldo_hintFadeToken", 0]) != _token) exitWith {};   // superseded by a newer redraw
	_shadowCtrl ctrlSetBackgroundColor [0, 0, 0, 0];
	_shadowCtrl ctrlCommit 3;
	_bgCtrl ctrlSetBackgroundColor [0.105, 0.11, 0.095, 0];
	_bgCtrl ctrlCommit 3;
	_textCtrl ctrlSetTextColor [0.95, 0.93, 0.86, 0];
	_textCtrl ctrlCommit 3;
	_text2Ctrl ctrlSetTextColor [0.95, 0.93, 0.86, 0];
	_text2Ctrl ctrlCommit 3;
};
