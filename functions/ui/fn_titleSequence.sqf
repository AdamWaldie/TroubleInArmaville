//////////////////////////////////////////////////////////////////
// Waldo_fnc_titleSequence
// CLIENT: the animated "location card" shown once the arena is ready.
//////////////////////////////////////////////////////////////////

private _missionTitle = getText (missionConfigFile >> "onLoadName");
// onLoadName is a "$STR_TIA_..." reference - getText normally resolves those
// itself, but resolve it here too so a raw key can never reach the screen.
if ((_missionTitle select [0, 5]) == "$STR_") then { _missionTitle = localize (_missionTitle select [1]); };
private _localeName = localize "STR_TIA_Title_LocaleName";
private _timeConfig = [dayTime, "ARRAY"] call BIS_fnc_timeToString;
private _time = format [localize "STR_TIA_Title_Hours", (_timeConfig select 0) + (_timeConfig select 1)];
private _date = format ["%1/%2/%3", date select 2, date select 1, date select 0];
private _localePos = format [localize "STR_TIA_Title_Grid", mapGridPosition player, _localeName];

[
	[
		[_missionTitle, "<t align='center' shadow='1' size='1.0' font='PuristaBold' color='#770000'>%1</t><br/>"],
		[_localePos,    "<t align='center' shadow='1' size='0.8' color='#808080'>%1</t><br/>"],
		[_date,         "<t align='center' shadow='1' size='0.7' font='PuristaBold'>%1</t><br/>", 5],
		[_time,         "<t align='center' shadow='1' size='0.6'>%1</t><br/>"]
	]
] spawn BIS_fnc_typeText;
