/*
 * Installs the local emergency UI-cleanup action. ACE self-interaction is the
 * primary path; vanilla addAction is installed only when ACE interaction is
 * unavailable. Safe to call on join and every respawn.
 */
if (!hasInterface || {isNull player}) exitWith {false};
if (player getVariable ["Waldo_UI_CleanupActionInstalled", false]) exitWith {true};

private _aceAvailable =
    isClass (configFile >> "CfgPatches" >> "ace_interact_menu")
    && {!isNil "ace_interact_menu_fnc_createAction"}
    && {!isNil "ace_interact_menu_fnc_addActionToObject"};

if (_aceAvailable) then {
    private _root = [
        "Waldo_UI_SelfRoot",
        localize "STR_TIA_UiCleanup_Root",
        "",
        {},
        {true}
    ] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions"], _root] call ace_interact_menu_fnc_addActionToObject;

    private _clear = [
        "Waldo_UI_ClearPanels",
        localize "STR_TIA_UiCleanup_Clear",
        "",
        {[] call Waldo_fnc_ClearUiPanels;},
        {true}
    ] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions", "Waldo_UI_SelfRoot"], _clear] call ace_interact_menu_fnc_addActionToObject;
    player setVariable ["Waldo_UI_CleanupInteractionMode", "ACE"];
} else {
    private _actionId = player addAction [
        format ["<t color='#79C7FF'>%1</t>", localize "STR_TIA_UiCleanup_Clear"],
        {[] call Waldo_fnc_ClearUiPanels;},
        [],
        -90,
        false,
        true,
        "",
        "alive _target && {_this isEqualTo _target}"
    ];
    player setVariable ["Waldo_UI_CleanupVanillaAction", _actionId];
    player setVariable ["Waldo_UI_CleanupInteractionMode", "VANILLA"];
};

player setVariable ["Waldo_UI_CleanupActionInstalled", true];
diag_log format ["[WMP UI] cleanup action installed mode=%1 clientOwner=%2", player getVariable ["Waldo_UI_CleanupInteractionMode", "NONE"], clientOwner];
true
