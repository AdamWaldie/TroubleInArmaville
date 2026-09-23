//////////////////////////////////////////////////////////////////
// Waldo_fnc_showRoleCard
// CLIENT: round-start notification wrapper around Waldo_fnc_roleBriefingText.
// remoteExec'd once per player from Waldo_fnc_assignRoles, with data already
// redacted server-side for exactly this viewer - fires the instant
// TraitorList/DetectiveList/JesterList are broadcast, tight enough on timing
// that a fresh remoteExec sent directly to this one player is safer than
// trusting those public variables have already replicated here.
//
// Replaces the old "There is a Detective/Jester this round" broadcasts (sent
// to literally everyone, un-tailored) and the Traitor-only team card - one
// personalised card per player. The same content is also re-viewable any
// time from the scoreboard's "Your Briefing" panel (Waldo_fnc_scoreboard),
// which calls Waldo_fnc_roleBriefingText itself rather than this wrapper.
//
// params: [_role, _teammateNames, _detectiveName, _jesterExists, _jesterName]
//   (see Waldo_fnc_roleBriefingText for what each means)
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};
params ["_role", "_teammateNames", "_detectiveName", "_jesterExists", "_jesterName"];

// This fires for every player at the start of every round - the one
// guaranteed once-per-round hook every client hits, so it's also where
// Waldo_fnc_ShowUiNotification's registry/queue get force-cleared. Normally
// each card's own duration handles its own cleanup, but Waldo_fnc_ClearUiPanels
// is otherwise only ever triggered by the LOCAL player's own death - a
// notification channel (e.g. "IDENTIFY") whose cleanup thread got cut short
// for any reason (a round ending mid-sleep, a JIP reconnect, anything) would
// otherwise stay marked "occupied" in the registry forever for a player who
// simply hasn't died yet, silently queueing every future card on that
// channel and never actually showing any of them again - exactly the "no
// feedback at all" report Identify Body's notifications ran into.
[] call Waldo_fnc_ClearUiPanels;

private _body = [_role, _teammateNames, _detectiveName, _jesterExists, _jesterName] call Waldo_fnc_roleBriefingText;

[
	localize "STR_TIA_Brief_CardTitle", _body,
	"INFO", 20, "TOP_RIGHT", "ROLECARD", toUpper localize ("STR_TIA_Role_" + _role)
] call Waldo_fnc_ShowUiNotification;
