//////////////////////////////////////////////////////////////////
// Waldo_fnc_deadRinger
// CLIENT: traitor activation item (Y/U/J, whichever it's bound to). Arms a
// 25s window: the next hit you take in that time - any hit, not just a
// lethal one, see the HandleDamage guard installed once in
// Waldo_fnc_initClient - is faked instead of dealing damage
// (Waldo_fnc_deadRingerTrigger). Whoever shot you sees you go down normally -
// they just don't know you're not actually dead.
//
// Returns true (consumed on arming; the trigger itself is separate).
//////////////////////////////////////////////////////////////////

if (player getVariable ["Waldo_deadRingerArmed", false]) exitWith {
	["STR_TIA_DeadRinger_Title", "STR_TIA_DeadRinger_AlreadyArmed", "WARNING", 3, "BOTTOM_LEFT", "DEADRINGER", "STR_TIA_Role_Traitor"] call Waldo_fnc_ShowUiNotification;
	false
};

player setVariable ["Waldo_deadRingerArmed", true];
["STR_TIA_DeadRinger_Title", "STR_TIA_DeadRinger_Armed", "SUCCESS", 4, "BOTTOM_LEFT", "DEADRINGER", "STR_TIA_Role_Traitor"] call Waldo_fnc_ShowUiNotification;

[] spawn {
	sleep 25;
	if (player getVariable ["Waldo_deadRingerArmed", false]) then {
		player setVariable ["Waldo_deadRingerArmed", false];
		["STR_TIA_DeadRinger_Title", "STR_TIA_DeadRinger_Expired", "INFO", 3, "BOTTOM_LEFT", "DEADRINGER", "STR_TIA_Role_Traitor"] call Waldo_fnc_ShowUiNotification;
	};
};

true
