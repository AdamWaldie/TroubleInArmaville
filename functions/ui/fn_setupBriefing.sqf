//////////////////////////////////////////////////////////////////
// Waldo_fnc_setupBriefing
// CLIENT: writes a "How To Play" diary (map screen -> Diary) once per
// session, so a new player has a rules reference in-mission instead of
// needing the wiki open in a second window. Static content - nothing here
// depends on role or round state, so it's safe to call once, early, well
// before roles are even assigned.
//
// selectDiarySubject makes this the tab that's actually showing the first
// time a player opens the map, instead of leaving them to notice the
// "How To Play" tab exists and click over to it themselves - the whole
// point of putting the rules here is that a brand new player finds them
// without being told to go looking.
//
// Localised: every paragraph is its own STR_TIA_Guide_* stringtable entry.
// Highlighted words (keys, role names, shop items) are %n arguments rather
// than markup inside the translation, so translators never have to touch
// <t> tags and the colours can't drift between languages.
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};

// Wraps text in a colour span. _key is localised first when it's a
// stringtable key; plain text (e.g. "K") passes straight through.
private _hl = {
	params ["_txt", ["_hex", "#ffd23f"]];
	format ["<t color='%1'>%2</t>", _hex, [_txt] call Waldo_fnc_localize]
};
// A highlighted " / "-joined list of shop item names.
private _items = {
	[(_this apply { localize ("STR_TIA_Shop_" + _x) }) joinString " / "] call _hl
};
// One localised paragraph: [key, args...] with args already rendered.
private _p = {
	params ["_key"];
	format ([localize _key] + (_this select [1]))
};
private _record = {
	params ["_titleKey", "_body"];
	player createDiaryRecord ["WaldoHowToPlay", [localize _titleKey, "<t align='left'>" + _body + "</t>"]];
};

private _inno = ["STR_TIA_Role_Innocent", "#26bf1e"] call _hl;
private _trai = ["STR_TIA_Role_Traitor", "#bf3636"] call _hl;
private _dete = ["STR_TIA_Role_Detective", "#02b3ff"] call _hl;
private _jest = ["STR_TIA_Role_Jester", "#9a2ecc"] call _hl;
private _keyK = ["K"] call _hl;
private _keyB = ["B"] call _hl;
private _keyYUJ = ["Y / U / J"] call _hl;

player createDiarySubject ["WaldoHowToPlay", localize "STR_TIA_Guide_Subject"];

["STR_TIA_Guide_ObjTitle",
	(["STR_TIA_Guide_Obj1", ["STR_TIA_Guide_Innocents", "#26bf1e"] call _hl, ["STR_TIA_Guide_Traitors", "#bf3636"] call _hl] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_Obj2"] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_Obj3", _keyK] call _p)
] call _record;

["STR_TIA_Guide_RolesTitle",
	(["STR_TIA_Guide_RoleInnocent", _inno] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_RoleTraitor", _trai] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_RoleDetective", _dete] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_RoleJester", _jest] call _p)
] call _record;

["STR_TIA_Guide_ClockTitle",
	(["STR_TIA_Guide_Clock1"] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_Clock2"] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_Clock3", ["STR_TIA_Timer_Overtime", "#FFD166"] call _hl] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_Clock4"] call _p)
] call _record;

["STR_TIA_Guide_InvestTitle",
	(["STR_TIA_Guide_Invest1"] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_Invest2", ["STR_TIA_Action_IdentifyBody"] call _hl] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_Invest3", _keyK] call _p)
] call _record;

["STR_TIA_Guide_CreditsTitle",
	(["STR_TIA_Guide_Credits1"] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_Credits2", _keyB] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_Credits3", _keyYUJ] call _p)
] call _record;

["STR_TIA_Guide_TShopTitle",
	(["STR_TIA_Guide_TShopRadar", ["Radar"] call _items] call _p) + "<br/>" +
	(["STR_TIA_Guide_TShopBasics", ["MedicalKit", "Stamina", "NightVision"] call _items] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_TShopSuicide", ["SuicideBomb"] call _items] call _p) + "<br/>" +
	(["STR_TIA_Guide_TShopDefib", ["Defibrillator"] call _items] call _p) + "<br/>" +
	(["STR_TIA_Guide_TShopPower", ["FragGrenades", "BodyArmor", "C4Charge"] call _items] call _p) + "<br/>" +
	(["STR_TIA_Guide_TShopPistol", ["SilencedPistol"] call _items] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_TShopFirepower", ["RocketLauncher", "LongRifle"] call _items] call _p) + "<br/>" +
	(["STR_TIA_Guide_TShopTeleport", ["TeleportGrenades"] call _items] call _p) + "<br/>" +
	(["STR_TIA_Guide_TShopFakeHealth", ["FakeHealthStation"] call _items] call _p) + "<br/>" +
	(["STR_TIA_Guide_TShopBodyRemover", ["BodyRemover"] call _items, ["STR_TIA_Action_IdentifyBody"] call _hl] call _p) + "<br/>" +
	(["STR_TIA_Guide_TShopDeadRinger", ["DeadRinger"] call _items] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_TShopFalseFlag", ["FalseFlag"] call _items] call _p) + "<br/>" +
	(["STR_TIA_Guide_TShopDisguiser", ["Disguiser"] call _items] call _p)
] call _record;

["STR_TIA_Guide_DShopTitle",
	(["STR_TIA_Guide_DShopRadar", ["Radar"] call _items] call _p) + "<br/>" +
	(["STR_TIA_Guide_DShopUtility", ["MedicalKit", "SmokeGrenades", "Stamina", "NightVision", "Binoculars", "HealthStation", "FragGrenades", "FlowerPower"] call _items] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_DShopScanner", ["DNAScanner"] call _items] call _p) + "<br/>" +
	(["STR_TIA_Guide_DShopEnhanced", ["EnhancedScanner"] call _items] call _p) + "<br/>" +
	(["STR_TIA_Guide_DShopDefib", ["Defibrillator"] call _items] call _p) + "<br/>" +
	(["STR_TIA_Guide_DShopArmor", ["BodyArmor"] call _items] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_DShopTester", ["PortableTester"] call _items] call _p)
] call _record;

["STR_TIA_Guide_KarmaTitle",
	(["STR_TIA_Guide_Karma1"] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_Karma2"] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_Karma3"] call _p)
] call _record;

["STR_TIA_Guide_ControlsTitle",
	(["STR_TIA_Guide_CtrlMap", ["M"] call _hl] call _p) + "<br/>" +
	(["STR_TIA_Guide_CtrlScore", _keyK] call _p) + "<br/>" +
	(["STR_TIA_Guide_CtrlCrest", ["H"] call _hl] call _p) + "<br/>" +
	(["STR_TIA_Guide_CtrlHolster", ["L"] call _hl] call _p) + "<br/>" +
	(["STR_TIA_Guide_CtrlBuy", _keyB] call _p) + "<br/>" +
	(["STR_TIA_Guide_CtrlUse", _keyYUJ] call _p) + "<br/>" +
	(["STR_TIA_Guide_CtrlPing", ["STR_TIA_Key_THold"] call _hl] call _p) + "<br/><br/>" +
	(["STR_TIA_Guide_CtrlScroll", ["STR_TIA_Action_IdentifyBody"] call _hl] call _p)
] call _record;

player selectDiarySubject "WaldoHowToPlay";
