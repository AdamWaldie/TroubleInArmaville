# Waldo_fnc_* — Trouble In Armaville function library

All mission logic lives here as CBA/BIS-style functions compiled by the
`class CfgFunctions { class Waldo { ... } }` block in `description.ext`.
A file `functions/<group>/fn_<name>.sqf` becomes `Waldo_fnc_<name>`.

The engine entry points are thin: `init.sqf` (server) calls
`Waldo_fnc_loadParams` then spawns `Waldo_fnc_initServer`; `initPlayerLocal.sqf`
spawns `Waldo_fnc_initClient`; `config.sqf` holds optional dynamic-arsenal tuning;
`onPlayerRespawn.sqf` (mission root) is the engine's per-respawn hook, used to
re-home a revived player's state onto their new unit (see below).

## The game mode (intent)

Trouble in Terrorist Town is a hidden-role social-deduction round game:

- **Innocent / Civilian** — majority, no powers, no knowledge. Wins when every
  Traitor is dead.
- **Traitor / Terrorist** — hidden minority (~25%). Know each other, share a
  credit shop, get sabotage tools. Win by killing everyone who is not a Traitor.
- **Detective** — a publicly-known Innocent (blue) with investigation tools
  (test bodies/players) and a support shop. Same win goal as Innocents.
- **Jester** — deals no damage and cannot win normally. Traitors are told who
  they are. "Wins" only if a **non-Traitor** kills them, denying the normal
  sides. Being killed by a Traitor does nothing.

## Layout

| Group | Functions | Runs on |
|-------|-----------|---------|
| `config` | `loadParams`, `buildArsenal` | server |
| `core` | `resetState`, `initServer`, `initClient`, `applySpawnLoadout` | server / client |
| `arena` | `selectArena`, `buildArena`, `populateLoot`, `confineToArena` | server (confine: client) |
| `env` | `setupWeather` | server |
| `round` | `assignRoles`, `applyDetectiveLoadout`, `startRound`, `roundLoop`, `checkWin`, `endRound`, `onKilled`, `reviveRelink`, `roundMVP` | server |
| `systems` | `spawnAirdrop`, `applyKarma`, `c4Charge`, `identifyBody`, `dnaContaminate`, `spawnDecoyCorpse` | server |
| `ui` | `initShops` (preInit), `initHud`, `drawRoleIcons`, `openBuyMenu`, `buyItem`, `titleSequence`, `pregameScreen`, `scoreboard`, `mvpCelebrate` | client |
| `roles` | `traitorRadar`, `detectiveRadar`, `warpSmoke`, `suicideBomb`, `flowerPower`, `tester`, `revive`, `healthStation`, `holster`, `removeBody`, `dnaScanner`, `placeC4`, `traitorPing`, `pingShow`, `deadRinger`, `deadRingerTrigger` | client |
| `debug` | `debugInit` (preInit registry + API), `debugMenu` (client renderer), `debugExec` (server dispatch), `effectivePlayerCount` | every machine / client / server |
| `lang` | `localize` (resolves keys / `[fmt, args]`), `chat`, `hintL`, `addActionL` (per-client localised remoteExec targets) | every machine / client |

## Localisation

All player-facing text lives in `stringtable.xml` at the mission root, as
`STR_TIA_*` keys. Arma picks each player's own game language automatically
and falls back to English for anything untranslated.

Text is localised on the machine that **displays** it, never on the sender.
The server sends keys (or `["STR_TIA_Fmt", arg1, ...]` arrays, whose args
can themselves be keys) and the receiving client resolves them with
`Waldo_fnc_localize`. `Waldo_fnc_ShowUiNotification` and
`Waldo_fnc_topBarAnnounce` do this for you; for chat, hints and scroll
actions, remoteExec `Waldo_fnc_chat`, `Waldo_fnc_hintL` or
`Waldo_fnc_addActionL` instead of the raw `systemChat`/`hint`/`addAction`
commands. Config text (`description.ext`, `ui/*.hpp`) uses `"$STR_TIA_..."`.

Role names, shop item names, ping kinds and similar values stay English
internally (they're ids that code compares); only the text drawn on screen
is localised. `tools/ci/stringtable_checker.py` fails CI if code references
a key that doesn't exist or a translation breaks its `%n` placeholders.

## Equipment — dynamic, intent-aware arsenal

Equipment is discovered at runtime, not hand-listed per modpack.
`Waldo_fnc_buildArsenal` runs once in `loadParams` (server), scans the loaded
`CfgWeapons` a single time, and classifies what is actually available:

- weapons are bucketed by **config inheritance** (`isKindOf` on `Rifle` /
  `Pistol` / `Launcher`, so mods that inherit from the base classes are picked
  up) and then by **power** — a primary's default-magazine ammo `hit` and round
  count sort it into low / standard / sniper / LMG;
- clothing is bucketed by `ItemInfo` type (uniform / vest / headgear);
  backpacks are a separate scan over `CfgVehicles` (`isKindOf Bag_Base`),
  since they don't live under `CfgWeapons` like everything else here;
- thermal optics are auto-detected (via `OpticsModes` `visionMode`) and
  blacklisted from loot.

- gear is discovered too: NVGs (`ItemInfo` type 617), plain binoculars
  (`isKindOf Binocular`, so rangefinders/designators are excluded), the
  highest-`armor` vest that still has some cargo capacity (picking by armour
  alone can land on a heavy plate-carrier variant with none), and the first
  explosive throwable off the `Throw` weapon's muzzles (frag grenade).

It then publishes the exact globals the mission consumes (`lootPriWeapons`,
`lootSecWeapons`, `lootAttachments`, `airdropLoadouts`, `TraitorRifle`/`*Mag`/
`*Optics`, `TraitorLauncher`/`*Mag`, `ShopPistol`/`*Mag`/`*Suppressor`,
`ShopArmorVest`, `ShopFrag`, `ShopNVG`, `ShopBinocular`, `uniformsConfig`,
`headgearsConfig`, `vestsConfig`, `backpacksConfig`, `detectiveConfig`) by **intent**:

| Intent | Pool |
|--------|------|
| Ground loot | low-powered primaries + sidearms (falls back to standard rifles if too few low-powered exist), plus a modest chance of a discovered vest or backpack per building |
| Airdrops (reward) | snipers + LMGs + standard rifles |
| Traitor "Long Rifle" | the highest-`hit` sniper found, with a compatible optic |
| Traitor "Rocket Launcher" | any launcher found |
| Shop gear | silenced sidearm, highest-`armor` vest with cargo space, frag grenade, NVG, binoculars |
| Spawn / detective clothing | discovered uniforms / vests / headgear (never a backpack - that's loot only) |

Every bucket has a **built-in vanilla classname fallback**, so an empty category
(e.g. a total-conversion with no pistols) never breaks a round, and consumers
keep their own `isNil`/`getVariable` guards. Because it is a drop-in for those
globals, `Waldo_fnc_spawnAirdrop`, the shop and the spawn/detective loadouts
needed no changes; `Waldo_fnc_populateLoot` was extended to also place vests
and backpacks as loot on top of weapons.

### There are no modpack presets

Equipment discovery is the *only* source — there are no `modpacks/*.sqf` files
and no equipment lobby param. To change the gear pool, change the mods you launch
Arma with; the mission adapts automatically. The only optional knobs are the
power thresholds in `config.sqf` (`Waldo_arsenalLowMaxHit` /
`Waldo_arsenalSniperMinHit` / `Waldo_arsenalLmgMinRounds`), read at the top of
`buildArsenal` with the defaults shown there.

> Lobby params are read by index in `loadParams`, so `DetectiveEnabled` (21) is
> kept **last** in `description.ext`'s `class Params`; append any new param after
> it so existing indices never shift.

## Adding a shop item

Edit the catalog in `ui/fn_initShops.sqf`. Each entry is:

```
[ _name, _cost, _type, _onBuy, _onActivate, _tooltip ]
```

- `_type`: `"passive"` | `"weapon"` | `"activation"`.
- `_onBuy`: runs immediately on purchase.
- `_onActivate`: for activation items, runs when the player presses whichever
  of **Y** / **U** / **J** the item is bound to; return `true` to consume the
  item, `false` to keep it assigned (e.g. no target). Called as
  `[_purchId, _slotIdx] call _onActivate` - almost every item ignores these
  (SQF discards unused params), but an item whose real "was it used?" outcome
  only resolves later, after some async UI interaction rather than at the
  instant the key is pressed, needs them to self-consume once that later
  outcome actually happens (see the Disguiser: it opens a picker dialog and
  returns `false` immediately, then the dialog's own pick callback consumes
  the item via `Waldo_fnc_consumeActivationItem`, not this return value).

Activation items are assigned to the first free of 3 key slots (Y/U/J) on
purchase, or held in a backlog if all 3 are already taken
(`Waldo_fnc_registerActivationSlot`); the player can reassign any owned,
not-yet-used activation item to a different slot from the Purchased panel
(`Waldo_fnc_assignActivationSlot`). Pressing a bound key runs the item's
`_onActivate` and, on success, promotes the oldest backlogged item (if any)
into the freed slot (`Waldo_fnc_useActivationSlot`).

The buy menu (`Waldo_fnc_openBuyMenu`) builds its cards from the catalog at
runtime, so no `.hpp` changes are needed. The dialog is a centred panel with a
role-tinted header, a scrollable card grid coloured by affordability, and a
footer that shows the hovered item's name, cost, type and `_tooltip` (so write
`_tooltip` as the item's description). Buying refreshes credits + affordability
in place and leaves the shop open (`Waldo_fnc_buyItem`); Esc or **Close** exits.
A second panel, **Purchased**, lists everything bought this round with its
`_tooltip` as a how-to-use reminder, and — for activation items — a live
Y/U/J key-assignment row (`Waldo_purchases`, reset each round in
`assignRoles`; rendered at runtime by `Waldo_shopRenderPurchased`, which fully
rebuilds the panel's controls on every purchase or reassignment) — so you're
never stuck remembering what an item does, or which key fires it, after
you've bought it.

The traitor and detective catalogs each carry ~14 items — offence (silenced
sidearm, frags, launcher, long rifle), utility (radar, stamina, night vision,
body armor), investigation/counter-investigation (tester, DNA scanner +
Enhanced Scanner, body remover, dead ringer, false flag), and role tools
(defibrillator, health station, C4 charge). The silenced sidearm, body armor,
frag, night vision and binoculars are all sourced from the dynamic arsenal
(`ShopPistol*`, `ShopArmorVest`, `ShopFrag`, `ShopNVG`, `ShopBinocular`), so they
follow the loaded mods.

## Investigation & counter-investigation mechanics

Beyond the original role-reveal tester, there's now a full forensics loop with
real risk on both sides:

- **DNA scanner** (Detective) reads DNA left by `Waldo_fnc_onKilled` on bodies
  **and** on dropped gear (weapon holders near a corpse), and by placed traitor
  equipment (a C4 charge carries its planter's DNA, even after being defused).
  Sampling starts a track (distance + bearing) on the suspect. Traces **decay**
  — an old sample gives a shorter track.
- **Contamination** (`Waldo_fnc_dnaContaminate`) is the reason this isn't a free
  "read and shoot": for 90s after a body/item appears, every *different* player
  who comes within 3m of it counts as a witness, and each one raises a chance
  the scanner **misdirects** the detective onto an innocent bystander instead of
  the real suspect. The detective is told the scene is contaminated (so they
  know to be wary) but never whether *this* reading is the real one.
- **Enhanced Scanner** (Detective passive) halves the misdirection chance,
  extends the track's duration/floor, and adds forensic detail — time since
  death and the murder weapon (`Waldo_deathTime` / `Waldo_deathWeapon`, both
  recorded by `onKilled`) — when scanning a body.
- **Identify Body**: any player can call in a corpse to confirm the death to
  everyone, but only a **Detective** identification reveals the victim's role
  (`Waldo_fnc_identifyBody`, `Waldo_roleRevealed`). This also drives the
  scoreboard's "confirmed dead" count.
- **False Flag** (Traitor passive): arms your next kill to leave a random living
  innocent's DNA at the scene instead of yours.
- **Dead Ringer** (Traitor activation): arms a 25s window where a lethal hit is
  faked instead of killing you. A `HandleDamage` guard (installed once in
  `initClient`) caps the damage and calls `Waldo_fnc_deadRingerTrigger`, which
  ragdolls you (`setUnconscious`, `allowDamage false` — a scripted
  approximation of "faking it," not true invisibility) and spawns a decoy corpse
  nearby (`Waldo_fnc_spawnDecoyCorpse`, tagged role Innocent so investigating it
  is misleading). You recover after 20s.
- **Body Remover** (Traitor activation): destroys a corpse outright, denying any
  of the above entirely.

## Traitor coordination

**T** sends a silent ping to every fellow Traitor (`Waldo_fnc_traitorPing` /
`Waldo_fnc_pingShow`) — no audio or text an innocent could overhear. The type is
auto-detected from what you're aiming at: a living player gives a **Target**
ping (orange, tracks them live); anything else gives a **Location** ping (red,
static point).

## Round MVP

At round end, `Waldo_fnc_roundMVP` (called from `endRound`, before
`BIS_fnc_endMissionServer`) finds whoever has the most kills this round
(`Waldo_roundKills`) and broadcasts `Waldo_fnc_mvpCelebrate` to everyone: the
intro music replays, a short coloured-smoke "fireworks" burst pops over the
arena, and a banner names the MVP (or "Round Complete" if nobody scored a kill).
`endRound` sleeps 6s afterward so it has time to play before the mission
restarts.

## Top bar (warmup / round timer + keybind row + announcements)

A centred, top-of-screen bar replaces the old server-broadcast round-timer
hint and the old bottom-left key-hints panel:

- During warmup (role selection), a separate `TTTWarmup` resource shows
  "Selecting Roles: N" in the same position/casing the round timer will take
  over once the round goes live - role isn't assigned yet during warmup, so
  there's nothing for `TTTHud` itself to show. Driven by `Waldo_fnc_warmupBar`
  (started from `fn_initClient.sqf` right after the pregame "arena ready"
  wait), which counts down locally from `Waldo_warmupEndAt` (the server `time`
  warmup ends at, broadcast once by `fn_initServer.sqf`) - same
  compute-locally-from-broadcast-state approach as the round timer below,
  instead of a per-second `remoteExec`'d hint. It also exits early if the dev
  "Skip Warmup" flag fires. It's a `cutRsc`, not a `titleRsc` like `TTTHud`:
  it runs during the same window as the mission's title-card animation
  (`Waldo_fnc_titleSequence`, built on `titleText`), and `titleText`/`titleRsc`
  share one engine-wide layer while `cutRsc` has its own - so the two don't
  evict each other, and `Waldo_fnc_warmupBar` explicitly clears its own
  `cutRsc` on every exit path instead of relying on `TTTHud`'s later
  `titleRsc` call to do it (that only evicts same-layer resources).
- Once the round is live, the timer row (part of the `TTTHud` title resource,
  same as the role badge) shows the civilian countdown, labelled ("Round
  M:SS"), plus a labelled "Deadline" for Traitors only ("Deadline M:SS") -
  the round's real hard end time (grows on every death), not a "time left as
  a Traitor" countdown, so the label describes what the number is rather than
  who sees it. It's driven by `Waldo_fnc_topBarTimer`, started once per client from
  `fn_initClient.sqf` (never restarted on respawn), which computes the
  remaining time locally from already-broadcast state (`Waldo_startTime`,
  `timelimit`, `Waldo_roundLiveAt`) instead of the server formatting and
  `remoteExec`-ing a string to every client every second. `Waldo_roundLiveAt`
  is the server `time` the round went live at; the dev "freeze" debug flag
  keeps it in lockstep with real time so the display doesn't quietly keep
  counting down while everything else is paused (`Waldo_fnc_roundLoop`). A
  thin accent bar under the timer doubles as a progress indicator: it shrinks
  toward the centre as the civilian clock runs down, and flashes once 30s or
  less remain.
- The keybind row below that lists whatever's relevant to your current role
  (`Waldo_keyHintsFor`, shared with the scoreboard's own keybind panel - see
  below), split across two stacked lines (a single `RscText` never wraps, it
  only clips overflow, and Testing Mode's full key list doesn't fit one line),
  redrawn on every respawn/role change by `Waldo_fnc_initHud`. It's visible
  for a few seconds after each redraw, then fades out completely (not just
  dimmed) rather than sitting on screen for the whole round - a token guard
  stops an in-flight fade from a previous redraw from clobbering a fresh one
  if you respawn again before the last fade finished.
- A banner directly below the keybind row "pops out" for one-off callouts
  during a live round (airdrops, currently) - it fades in, holds a few
  seconds, then fades back out, rather than an instant hint-style pop. Driven
  by `Waldo_fnc_topBarAnnounce` (`[_text, _color, _hold] remoteExec [...]`),
  token-guarded the same way as the keybind row's fade so a newer announcement
  always supersedes a still-fading-out older one instead of fighting it.
  `Waldo_fnc_spawnAirdrop` uses it for both normal and golden airdrop drops.

The scoreboard (`Waldo_fnc_scoreboard`, **K**) also shows the same
`Waldo_keyHintsFor` list, stacked vertically in a panel attached to its right
edge, as a standing reference that doesn't fade.

## Keys

- **B** — open your buy menu (Traitor / Detective).
- **Y / U / J** — use the activation item bound to slot 1 / 2 / 3 (reassign from the buy menu's Purchased panel).
- **L** — holster / lower weapon.
- **K** — toggle the in-round scoreboard.
- **T** — hold to pick a ping type (Target / Location / Danger / Regroup Here / Enemy Spotted), release to send it (Traitors only).
- **[** — open the dev/test menu (**only** when the **Testing Mode** parameter is on).
- **]** — instantly cycle your own role Innocent → Traitor → Detective → Jester (Testing Mode only).

## Testing / dev mode

Set the **Enable Testing Mode** lobby parameter to *Yes* to unlock a solo-friendly
test framework. Beyond the original behaviour (phase markers echoed to chat and the
"Traitors win" auto-end suppressed so a lone tester is never kicked out), pressing
**[** in-round opens an extensible console (`Waldo_fnc_debugMenu`) that renders a
registry of test tools grouped by category. Everything is gated on `TestingFlag`:
the key does nothing, the server dispatch refuses to run, and the simulated
player-count override is ignored when Testing Mode is off, so normal games are
completely unaffected.

Built-in tools cover every area of the game:

- **Roles** — become any role (or press **]** to cycle instantly, no menu), or
  re-run role assignment. Every switch is complete and reversible: role lists,
  detective loadout, shop access and the Jester fire-block are all reconciled, so
  you can hop between roles on the fly and each one behaves exactly as in a real
  game. Shop roles are handed a usable test balance on switch.
- **Loadout & shops** — grant credits, open either shop, or run every shop
  purchase effect at once.
- **Abilities** — fire each Traitor/Detective power (radars, warp smoke, flower
  power, health station, suicide bomb, holster) directly.
- **Test dummies** — spawn captive role dummies (deaths routed through
  `Waldo_fnc_onKilled`, so kill-credit / Jester clean-kill / karma work solo) or
  an armed hostile for combat testing; clear them all in one click. These do
  **not** count toward win conditions.
- **Simulated players** — spawn AI that genuinely participate in the win check:
  traitor sims join `TraitorList` (so END1 needs them dead), non-traitor sims
  mark that a non-traitor side exists (so END2 becomes reachable). Build a roster,
  then "Kill Sim Traitors" (be a non-traitor → **END1**) or "Kill Sim Innocents"
  (be a traitor → **END2**) and watch the ending resolve. "Clear Sim Players"
  tears the scenario down and repairs the lists.
- **Round flow** — skip warmup, freeze the clock, add/subtract time, or force any
  ending (END1–END4).
- **Arena & world** — rebuild/reselect the arena, repopulate loot, and set
  weather / time of day.
- **Karma & sim** — set your karma, and **simulate a lobby size** so arena
  scaling, traitor counts and credit scaling can be tested solo.
- **Player** — godmode, heal, refill ammo, infinite stamina, teleport, kill self.
- **Diagnostics** — dump game state to chat/`.rpt` or the clipboard.

Testing the endings also hardened `Waldo_fnc_checkWin` for **live** games: every
roster test is null-safe, and both team-win endings now require a Traitor side to
have existed — with the Traitors-win ending additionally requiring that
non-Traitors existed this round (`Waldo_hadNonTraitors`, set in `assignRoles`).
That closes the degenerate all-Traitor lobby that used to insta-win. The
simulated-player roster is only mixed in under Testing Mode, so a normal game's
win check is otherwise unchanged.

### Extending it

The action list is a **registry**, not a hardcoded menu. Register a tool from any
code that runs at preInit on every machine (this mission's `Waldo_fnc_debugInit`,
or a future module's own preInit):

```sqf
["Category", "Label", "Tooltip", "local"|"server", { /* _this = acting unit */ }]
    call Waldo_debugRegister;
```

- `"local"` code runs on the clicking client; `"server"` code is dispatched to
  the server **by index** (no code crosses the wire) and run with the clicking
  unit as `_this`, keeping authoritative state correct.
- The menu groups entries by `Category` in `Waldo_debugCatOrder` and rebuilds
  itself automatically — no UI, dispatch or `description.ext` edits needed.
- Scripted testing: `"airdrop" call Waldo_debug` runs the first tool whose label
  matches. `Waldo_fnc_effectivePlayerCount` is the shared hook that lets size
  logic honour the simulated lobby size.

### Mod independence

The framework carries no mod-specific classnames. Weapon/gear tools run the
shop's own `_onBuy` effects, which read the dynamic-arsenal globals with vanilla
fallbacks, so they follow whatever mods are loaded. Spawned test units (dummies,
simulated players, hostile) go through one helper, `Waldo_debugMakeUnit`, which:

- reads its unit class from `Waldo_debugCivUnit` / `Waldo_debugEnemyUnit`,
  **validating** it and falling back to a base-game class (`C_man_1` /
  `O_Soldier_F`) that exists in every install, and
- dresses non-enemy units from the discovered `uniformsConfig` /
  `headgearsConfig` / `vestsConfig`, so they look like the current players.

To point the spawn units at your own classes, set `Waldo_debugCivUnit` /
`Waldo_debugEnemyUnit` in `config.sqf` (a commented example is there); with no
config, testing works out of the box under any mods.

## State model & replay safety

Each round ends via `BIS_fnc_endMissionServer`, i.e. a full mission restart, so
`missionNamespace` is wiped every round. `Waldo_fnc_resetState` re-initialises
all round state defensively, and consumers wait on `Waldo_configReady` so they
never read config before the modpack/params are published. Karma is the only
cross-round state and lives in `profileNamespace`; `Waldo_fnc_applyKarma` decays
and prunes it so it can never accumulate unbounded.

Init progress is logged as `[Waldo][server]` / `[Waldo][client]` phase markers
in the `.rpt` (and on-screen when the **Testing Mode** parameter is on) to make
replay stalls easy to trace.

### Respawn is a NEW unit, not the old one restored

A truly dead unit (`damage` 1, `Killed` fired) can never be revived in place -
Arma's respawn always creates a brand-new object. `Waldo_fnc_revive` forces an
early respawn (`setPlayerRespawnTime 0`) and stashes the intent on the corpse;
`onPlayerRespawn.sqf` (the engine's per-respawn hook, which hands back the new
unit directly) then re-homes everything onto it: role via `Waldo_fnc_reviveRelink`
(also repoints `TraitorList`/`DetectiveList`/`JesterList` off the dead reference),
credits/kills/purchases, the per-life `MPKilled`/`HandleDamage` handlers
`Waldo_fnc_initClient` bound to the old unit object (they don't follow the
`player` command across a respawn), the Jester fire-block, and a basic loadout
via `Waldo_fnc_applySpawnLoadout`. Anything that reaches for `player` at call
time (not a captured object reference) - like the `ace_unconscious` handler in
`initClient` - already tracks a respawn on its own and needs no re-homing.
