//////////////////////////////////////////////////////////////////
// Waldo_fnc_pregameScreen
// CLIENT: shows the "setting up the arena" hint until the server signals
// mapDone. Nil-safe so it can never spin on an unset variable.
//////////////////////////////////////////////////////////////////

while { !(missionNamespace getVariable ["mapDone", false]) } do {
	hintSilent parseText format ["<t align='center' size='1.0'><t color='#d11b1b' shadow='1'>%1</t>", localize "STR_TIA_Pregame_SettingUp"];
	sleep 0.25;
};
hintSilent "";
