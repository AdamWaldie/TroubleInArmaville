/*
 * Author: WaldoTheWarfighter
 * Draws a reusable, accessible WMP notification card on the local client.
 * Transient cards queue FIFO per channel and stack safely across channels.
 * Persistent cards replace the current owner of their channel.
 * Duration 0 keeps the card visible until it is replaced or cleared.
 *
 * Arguments:
 * 0: Title <STRING or ARRAY> - plain text, STR_TIA_ key, or [fmtKey, args...]
 * 1: Message <STRING, TEXT or ARRAY> - same forms as Title
 *
 * Title, message and source are resolved with Waldo_fnc_localize on THIS
 * client, so the server can send keys and every player reads the card in
 * their own game language.
 * 2: State <STRING> INFO | SUCCESS | WARNING | ERROR (default INFO)
 * 3: Duration <NUMBER> seconds, 0 = persistent (default 8)
 * 4: Placement <STRING> TOP | TOP_RIGHT | CENTER | BOTTOM_LEFT | BOTTOM_RIGHT
 * 5: Channel <STRING> replacement/ownership key (default MISSION)
 * 6: Source label <STRING or ARRAY> (default WALDOS MISSION PACK)
 * 7: Policy <STRING> AUTO | FIFO | REPLACE (default AUTO)
 * 8: Priority <NUMBER> mission metadata for arbitration/reporting (default 0)
 * 9: Allow permitted local placement override <BOOL> (default false)
 *
 * Return: STRING token, or empty string if queued while no gameplay display exists.
 *
 * Example:
 * ["SUPPLY DELIVERED", "The forward crate is ready.", "SUCCESS", 8, "TOP", "LOGISTICS"]
 *     call Waldo_fnc_ShowUiNotification;
 */
if (!hasInterface) exitWith {""};

params [
    ["_title", "STR_TIA_Notify_Notice", ["", []]],
    ["_message", ""],
    ["_state", "INFO", [""]],
    ["_duration", 8, [0]],
    ["_placement", "TOP", [""]],
    ["_channel", "MISSION", [""]],
    ["_source", "STR_TIA_Notify_DefaultSource", ["", []]],
    ["_policy", "AUTO", [""]],
    ["_priority", 0, [0]],
    ["_allowLocalOverride", false, [true]],
    ["_fromQueue", false, [true]]
];

private _display = findDisplay 46;
if (isNull _display) exitWith {
    _this spawn {
        private _deadline = diag_tickTime + 20;
        waitUntil {uiSleep 0.1; !isNull (findDisplay 46) || {diag_tickTime >= _deadline}};
        if (!isNull (findDisplay 46)) then {_this call Waldo_fnc_ShowUiNotification;};
    };
    ""
};

// A card is created on display 46, and in practice that drew OVER this mission's
// own dialogs rather than under them - a Golden Airdrop card landed on top of the
// style picker and covered its title. Rather than fight the engine's layering,
// hold the card while one of our dialogs is open and let the existing FIFO queue
// carry it: the dialog's onUnload drains the queue on close, so nothing is lost,
// it just arrives a moment later. Guarded on _fromQueue so a card being drained
// can't re-queue itself forever.
if ((uiNamespace getVariable ["Waldo_uiModalOpen", false]) && {!_fromQueue}) exitWith {
    private _queue = +(uiNamespace getVariable ["Waldo_UiPanelQueue", []]);
    _queue pushBack [_title, _message, _state, _duration, _placement, _channel, _source,
                     _policy, _priority, _allowLocalOverride, false];
    uiNamespace setVariable ["Waldo_UiPanelQueue", _queue];
    "QUEUED"
};

// Localised here rather than at the top: the deferred/modal-queue paths above
// re-enter this function with the original args, so resolving once at draw
// time is enough and keeps queued requests language-neutral.
_title = [_title] call Waldo_fnc_localize;
_message = [_message] call Waldo_fnc_localize;
_source = [_source] call Waldo_fnc_localize;

_state = toUpper _state;
_channel = toUpper _channel;
_placement = [_channel, _placement, _allowLocalOverride] call Waldo_fnc_ResolveUiPanelPlacement;
_policy = toUpper _policy;
if (_policy isEqualTo "AUTO") then {_policy = if (_duration <= 0) then {"REPLACE"} else {"FIFO"};};
if !(_policy in ["FIFO", "REPLACE"]) then {_policy = "FIFO";};
private _semantic = switch (_state) do {
    // Colour only - no [OK]/[!]/[X]/[i] token. Those read as console output rather
    // than as this mission's UI, and the title already says what happened: the
    // state is carried by the accent stripe and the title's colour instead.
    case "SUCCESS": {["#6CE5A8", ""]};
    case "WARNING": {["#FFD166", ""]};
    case "ERROR": {["#FF6161", ""]};
    default {["#79C7FF", ""]};
};
_semantic params ["_colour", "_symbol"];

private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
private _existingIndex = _registry findIf {(_x param [0, ""]) isEqualTo _channel};
if (_policy isEqualTo "FIFO" && {!_fromQueue} && {_existingIndex >= 0 || {({(_x param [3, ""]) isEqualTo _placement} count _registry) >= 3}}) exitWith {
    private _request = [_title, _message, _state, _duration, _placement, _channel, _source, _policy, _priority, _allowLocalOverride, false];
    private _queue = +(uiNamespace getVariable ["Waldo_UiPanelQueue", []]);
    private _identity = format ["%1|%2|%3|%4", _channel, _title, _message, _state];
    private _duplicate = _queue findIf {
        format ["%1|%2|%3|%4", toUpper (_x param [5, "MISSION"]), _x param [0, ""], _x param [1, ""], toUpper (_x param [2, "INFO"])] isEqualTo _identity
    };
    if (_duplicate < 0) then {_queue pushBack _request;};
    uiNamespace setVariable ["Waldo_UiPanelQueue", _queue];
    "QUEUED"
};
if (_existingIndex >= 0) then {
    private _old = _registry deleteAt _existingIndex;
    {if (!isNull _x) then {ctrlDelete _x;};} forEach (_old param [1, []]);
};

// Back to the simpler shadow + casing + accent-stripe recipe (its original
// design intent, before a header-band experiment made it feel like a
// different, wider kind of panel than the compact nameplate it's meant to
// be). Colours are this mission's own WALDO_* values (see ui/common.hpp)
// and its role palette (Waldo_roleColor in fn_initShops.sqf: Traitor red,
// Detective blue, Jester purple, Innocent green), not the WMP defaults -
// the INFO state deliberately isn't blue, so a card is never mistaken for
// a Detective-blue "info" state next to an actual Detective-blue role
// crest.
private _shadow = _display ctrlCreate ["RscText", -1];
private _frame = _display ctrlCreate ["RscText", -1];
private _accent = _display ctrlCreate ["RscText", -1];
private _content = _display ctrlCreate ["RscStructuredText", -1];
_shadow ctrlSetBackgroundColor [0, 0, 0, 0.82];
_frame ctrlSetBackgroundColor [0.07, 0.075, 0.065, 1];   // fully opaque near-black casing
_accent ctrlSetBackgroundColor (switch (_state) do {
    case "SUCCESS": {[0.435, 0.796, 0.455, 1]};   // matches the shop's existing "[OK] PURCHASED" green
    case "WARNING": {[0.85, 0.62, 0.20, 1]};      // WALDO_ACCENT gold
    case "ERROR":   {[0.894, 0.318, 0.294, 1]};   // matches the shop's existing "[X] NOT ENOUGH CREDITS" red
    default         {[0.85, 0.62, 0.20, 1]};      // WALDO_ACCENT gold - the shared amber thread every role UI now uses
});
_content ctrlSetBackgroundColor [0, 0, 0, 0];

private _messageText = if ((typeName _message) isEqualTo "TEXT") then {str _message} else {_message};
_content ctrlSetStructuredText parseText format [
    "<t align='left' font='PuristaMedium' color='#9FB3C8' size='0.72'>%1</t><br/>" +
    "<t align='left' font='PuristaBold' color='%2' size='1.12' shadow='1'>%3%4</t><br/>" +
    "<t align='left' font='PuristaMedium' color='#F2EFE3' size='0.88'>%5</t>",
    toUpper _source,
    _colour,
    _symbol,
    _title,
    _messageText
];

private _visibleW = safeZoneW;
private _visibleH = safeZoneH;
// Narrower across the board than the round timer bar (0.36 * safezoneW) -
// a nameplate-style card reads as compact and pinned to its corner, not as
// a second wide banner competing with the timer bar above it.
private _panelW = switch (_placement) do {
    case "BOTTOM_RIGHT": {_visibleW * 0.19};
    case "TOP_RIGHT": {_visibleW * 0.22};
    case "BOTTOM_LEFT": {_visibleW * 0.26};
    case "CENTER": {_visibleW * 0.24};
    default {_visibleW * 0.22};
};
private _padX = _visibleW * 0.010;
private _padY = _visibleH * 0.008;
private _maximumContentH = _visibleH * 0.22;
_content ctrlSetPosition [0, 0, _panelW - (2 * _padX), _maximumContentH];
_content ctrlCommit 0;
private _contentH = (((ctrlTextHeight _content) + (_visibleH * 0.006)) max (_visibleH * 0.07)) min _maximumContentH;
private _panelH = _contentH + (2 * _padY);
private _accentH = (_visibleH * 0.004) max 0.002;
{_x ctrlShow true;} forEach [_shadow, _frame, _accent, _content];

private _token = format ["%1_%2", diag_tickTime, random 1e9];
private _controls = [_shadow, _frame, _accent, _content];
_registry pushBack [_channel, _controls, _token, _placement, _panelW, _panelH, _padX, _padY, _accentH, _contentH, _priority, diag_tickTime];
uiNamespace setVariable ["Waldo_UiPanelRegistry", _registry];
[] call Waldo_fnc_ReflowUiPanels;

if (_duration > 0) then {
    [_channel, _token, _duration] spawn {
        params ["_channel", "_token", "_duration"];
        uiSleep (_duration max 1);
        private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
        private _index = _registry findIf {
            (_x param [0, ""]) isEqualTo _channel && {(_x param [2, ""]) isEqualTo _token}
        };
        if (_index >= 0) then {
            private _entry = _registry deleteAt _index;
            {if (!isNull _x) then {ctrlDelete _x;};} forEach (_entry param [1, []]);
            uiNamespace setVariable ["Waldo_UiPanelRegistry", _registry];
            [] call Waldo_fnc_ReflowUiPanels;
            [] call Waldo_fnc_DrainUiNotificationQueue;
        };
    };
};

_token
