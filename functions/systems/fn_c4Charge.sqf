//////////////////////////////////////////////////////////////////
// Waldo_fnc_c4Charge
// SERVER: spawns a traitor's timed explosive charge and runs its lifecycle.
// A visible object is placed; every machine gets a "Defuse" action on it (for
// anyone but the planter, within 3m). After the fuse it detonates unless it was
// defused first.
//
// params: [_owner, _pos]
//////////////////////////////////////////////////////////////////

if (!isServer) exitWith {};
params ["_owner", "_pos"];

private _charge = createVehicle ["Land_Suitcase_F", _pos, [], 0, "CAN_COLLIDE"];
_charge setVariable ["Waldo_c4Owner",   _owner, true];
_charge setVariable ["Waldo_c4Defused", false,  true];
// The charge carries the planter's DNA - a detective can scan it (before it
// blows, or during the window after it is defused) to track the traitor.
_charge setVariable ["Waldo_killerDNA",     _owner, true];
_charge setVariable ["Waldo_killerDNATime", time,   true];
_charge allowDamage false;
[_charge, _owner] call Waldo_fnc_dnaContaminate;

// Defuse action, broadcast to everyone. Condition matches Waldo_fnc_healthStation's
// own working pattern - "alive _this" only, nothing reading _target. This
// used to check "not the planter" and "not already defused" directly in
// the condition via _target getVariable [...], and the action never showed
// up at all (confirmed live, same failure as Waldo_fnc_fakeHealthStation's
// identical mistake - see the long comment there for why: _target is the
// crate itself, freshly createVehicle'd moments earlier in this very
// script, and a condition that throws resolving it is silently treated as
// false, not shown as an error). Both checks now live in the STATEMENT
// instead, which only ever runs after someone has already seen and clicked
// the action - hideOnUse still removes it after a successful defuse either
// way; this just stops a second, later click (or a planter's own click)
// from re-marking an already-defused charge.
[_charge, [
	["<t color='#ff3333'>%1</t>", "STR_TIA_Action_DefuseCharge"],
	{
		params ["_target", "_caller"];
		if (_caller != (_target getVariable ["Waldo_c4Owner", objNull]) && {!(_target getVariable ["Waldo_c4Defused", false])}) then {
			_target setVariable ["Waldo_c4Defused", true, true];
		};
	},
	nil, 6, true, true, "",
	"alive _this",
	3
]] remoteExec ["Waldo_fnc_addActionL", 0, _charge];   // title localised per client

[_charge, _owner] spawn {
	params ["_charge", "_owner"];
	private _boomAt = time + 15;
	while { time < _boomAt && {!isNull _charge} && {!(_charge getVariable ["Waldo_c4Defused", false])} } do {
		sleep 0.5;
	};
	if (isNull _charge) exitWith {};

	if (_charge getVariable ["Waldo_c4Defused", false]) exitWith {
		// Was a plain systemChat line - easy to miss entirely mid-firefight,
		// and reported as "no visible change" on a successful defuse. Every
		// other event in this mission (kills, purchases, role reveals) uses
		// the same rich notification card system now; this was the one
		// straggler still on the old chat-log-only feedback.
		[
			"STR_TIA_C4_Defused", "STR_TIA_C4_DefusedBody", "SUCCESS", 6, "TOP_RIGHT", "C4_DEFUSED", "STR_TIA_Identify_Source"
		] remoteExec ["Waldo_fnc_ShowUiNotification", 0];
		// Leave the defused charge (with its DNA) around briefly for forensics.
		[_charge] spawn { params ["_c"]; sleep 30; if (!isNull _c) then { deleteVehicle _c }; };
	};

	private _p = getPosATL _charge;
	deleteVehicle _charge;
	// SatchelCharge_Remote_Ammo_Scripted - Bo_Mk82 (tried per an earlier
	// request) confirmed "fucking huge" live, and Sh_82_HE (tried in
	// between) turned out to not even be createVehicle-able. Satchel is the
	// one alternative already verified to actually detonate reliably (same
	// "_Scripted" remote-charge family as DemoCharge_Remote_Ammo_Scripted,
	// which this mission's own placed charge already used successfully).
	// Wanted "a little more power than that satchel" without gambling on a
	// fourth unverified ammo class - two of them, both created at the exact
	// same point and detonated together, is guaranteed to still use the
	// one mechanism already proven to work, while genuinely increasing the
	// total blast/damage output rather than hoping a different class both
	// exists and behaves the same way.
	private _bomb1 = createVehicle ["SatchelCharge_Remote_Ammo_Scripted", _p, [], 0, "NONE"];   // same blast the suicide bomb uses
	private _bomb2 = createVehicle ["SatchelCharge_Remote_Ammo_Scripted", _p, [], 0, "NONE"];
	// A createVehicle'd bomb has no shooter by default, so anyone it kills would
	// resolve to a null culprit in Waldo_fnc_onKilled - no karma penalty for
	// blowing up a teammate, no DNA on the corpse, no round-kill credit. Tag the
	// planter as both shooter and instigator so C4 kills attribute exactly like
	// a gunshot would.
	_bomb1 setShotParents [_owner, _owner];
	_bomb2 setShotParents [_owner, _owner];
	// The scripted charge only detonates when damaged - this is what actually
	// triggers the blast.
	_bomb1 setDamage 1;
	_bomb2 setDamage 1;
};
