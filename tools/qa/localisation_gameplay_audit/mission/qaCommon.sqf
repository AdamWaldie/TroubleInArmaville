// Shared result helpers for the disposable audit mission.
TTT_QA_Findings = [];
TTT_QA_Check = {
	params ["_id", "_ok", ["_detail", ""]];
	if (_ok) then {
		diag_log format ["TTT QA PASS: %1 %2", _id, _detail];
	} else {
		TTT_QA_Findings pushBack [_id, _detail];
		diag_log format ["TTT QA FAIL: %1 %2", _id, _detail];
	};
	_ok
};

TTT_QA_Capture = {
	params ["_id"];
	diag_log format ["TTT QA CAPTURE READY: %1", _id];
	uiSleep 3;
};

TTT_QA_CloseSurface = {
	closeDialog 1;
	hintSilent "";
	[] call Waldo_fnc_ClearUiPanels;
	openMap false;
	uiSleep 0.5;
};
