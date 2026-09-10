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
//////////////////////////////////////////////////////////////////

if (!hasInterface) exitWith {};

player createDiarySubject ["WaldoHowToPlay", "How To Play"];

player createDiaryRecord ["WaldoHowToPlay", [
	"Objective",
	"<t align='left'>Every round, everyone is secretly assigned a role. " +
	"<t color='#26bf1e'>Innocents</t> win when every Traitor is dead. " +
	"<t color='#bf3636'>Traitors</t> win by killing everyone who isn't a Traitor. " +
	"Nobody knows anyone else's role at the start except the Traitors, who know each other.<br/><br/>" +
	"Dying doesn't end your game - you drop into Spectator and can keep watching (and, per this " +
	"server's chat rules, keep talking to other dead players) until the round ends.<br/><br/>" +
	"Forgot who you're allowed to know about? Press <t color='#ffd23f'>K</t> any time mid-round - the " +
	"scoreboard's 'Your Briefing' panel repeats this same information live.</t>"
]];

player createDiaryRecord ["WaldoHowToPlay", [
	"The Roles",
	"<t align='left'>" +
	"<t color='#26bf1e'>Innocent</t> - the majority. No powers, no extra information - work it out from " +
	"behaviour, bodies, and what the Detective finds.<br/><br/>" +
	"<t color='#bf3636'>Traitor</t> - a hidden minority who know each other from the start. Shared credit " +
	"shop full of sabotage and counter-investigation tools. Win by killing everyone else.<br/><br/>" +
	"<t color='#02b3ff'>Detective</t> - a PUBLICLY known Innocent (everyone can see this role, and who's " +
	"holding it) with an investigation shop: role testing, a DNA scanner, radar. Wins alongside the " +
	"Innocents.<br/><br/>" +
	"<t color='#9a2ecc'>Jester</t> - deals no damage and can't win the normal way. The Traitors are told " +
	"who the Jester is; nobody else is. If anyone who ISN'T a Traitor kills the Jester, the Jester wins " +
	"instead and nobody else does. A Traitor who kills the Jester gets nothing for it and loses almost " +
	"everything they've saved up - it's a costly mistake, not a shortcut.</t>"
]];

player createDiaryRecord ["WaldoHowToPlay", [
	"The Round Clock & Overtime",
	"<t align='left'>Every round has a planned base length, shown as the round timer from the start. " +
	"Every death - anyone's - extends the clock a bit, so a round with a lot of killing runs longer than " +
	"a quiet one.<br/><br/>" +
	"Each extra death matters a little less than the last, though - there's no single death after which " +
	"extensions just stop, but a chaotic round can't run away forever either.<br/><br/>" +
	"Once the clock runs past its planned base length, that's <t color='#FFD166'>OVERTIME</t> - you'll see " +
	"a banner for it. The round is no longer running on its original timer at that point, only on however " +
	"much extra time the deaths so far have bought it.<br/><br/>" +
	"The arena itself has a hard boundary - wander too far and you'll be warned, then returned. It exists " +
	"to keep everyone in the same fight, not to trap you somewhere unfair; if a fence or wall ever seems " +
	"to be blocking a path that should exist, that's worth reporting.</t>"
]];

player createDiaryRecord ["WaldoHowToPlay", [
	"Investigation",
	"<t align='left'>Every kill leaves DNA on the body and on nearby dropped gear. A Detective's DNA " +
	"Scanner samples it and gives a hot/cold distance-and-bearing track to the suspect - older samples " +
	"and witnesses contaminating the scene both weaken the read, and a contaminated reading can point at " +
	"the wrong person entirely. The Detective is told when a scene is contaminated, never told whether a " +
	"given reading is the real one - that judgement call is the actual investigation.<br/><br/>" +
	"Any player can scroll-wheel a corpse and use <t color='#ffd23f'>Identify Body</t> to call in a death " +
	"to the whole server. That alone doesn't reveal the victim's role - only a Detective's call-in does " +
	"that, and it's what moves the scoreboard's CONFIRMED DEAD count. The action stays available until a " +
	"Detective uses it, even after someone else has already called the body in.<br/><br/>" +
	"Press <t color='#ffd23f'>K</t> any time for the in-round scoreboard: who's alive, whose body has been " +
	"found, and roles where you're allowed to know them. Kill counts only show once you're dead or " +
	"spectating - a live player never sees anyone's tally, theirs included.</t>"
]];

player createDiaryRecord ["WaldoHowToPlay", [
	"Credits & Economy",
	"<t align='left'>Traitors and Detectives start each round with credits (more in bigger lobbies) and " +
	"earn more over the round: a bonus for a confirmed enemy kill, and for Traitors, a team-wide bonus " +
	"for every few civilians killed.<br/><br/>" +
	"Low karma (see Fair Play below) reduces next round's starting credits. Spend what you have in your " +
	"role's shop (<t color='#ffd23f'>B</t>) on weapons, gear, and one-shot ACTIVATION items (explosives, " +
	"decoys, disguises, and the like) - prices roughly track how powerful or how disruptive to the other " +
	"side's investigation an item is, not just raw combat strength.<br/><br/>" +
	"Activation items go on the <t color='#ffd23f'>Y / U / J</t> keys via the buy menu - press the " +
	"assigned key to use one. Buy more than 3 and the extras queue up, backfilling a slot automatically " +
	"as one frees up. The Purchased panel in the shop always shows what you own and how to use it.</t>"
]];

player createDiaryRecord ["WaldoHowToPlay", [
	"Traitor Shop",
	"<t align='left'>" +
	"<t color='#ffd23f'>Radar</t> - pulses everyone's position AND role for 30s, then recharges. Cheap on " +
	"purpose.<br/>" +
	"<t color='#ffd23f'>Medical Kit / Stamina / Night Vision</t> - basic self-sufficiency, also kept " +
	"cheap.<br/><br/>" +
	"<t color='#ffd23f'>Suicide Bomb</t> - detonate yourself, taking anyone nearby with you.<br/>" +
	"<t color='#ffd23f'>Defibrillator</t> - revive any body onto your own team.<br/>" +
	"<t color='#ffd23f'>Frag Grenades / Body Armor / C4 Charge</t> - straightforward power and " +
	"survivability.<br/>" +
	"<t color='#ffd23f'>Silenced Pistol</t> - no gunshot report to give you away.<br/><br/>" +
	"<t color='#ffd23f'>Rocket Launcher / Long Rifle</t> - real firepower, priced to match.<br/>" +
	"<t color='#ffd23f'>Teleport Grenades</t> - throw red smoke, warp to where it lands (never outside the " +
	"arena boundary).<br/>" +
	"<t color='#ffd23f'>Fake Health Station</t> - a decoy that detonates on whoever uses it, except " +
	"you.<br/>" +
	"<t color='#ffd23f'>Body Remover</t> - destroys a corpse outright: no DNA, no Identify Body, nothing " +
	"left to investigate.<br/>" +
	"<t color='#ffd23f'>Dead Ringer</t> - your next lethal hit is faked: you ragdoll, a decoy corpse drops, " +
	"and you're warped somewhere safe inside the arena, out of sight.<br/><br/>" +
	"<t color='#ffd23f'>False Flag</t> - your next kill's DNA points to another living player instead of " +
	"you.<br/>" +
	"<t color='#ffd23f'>Disguiser</t> - pick a living player and copy their exact loadout for 60s, with a " +
	"countdown shown top-right; any DNA you leave behind while disguised points to them too. The most " +
	"expensive item in the shop - it undermines the investigation on two fronts at once (how you look AND " +
	"what you leave behind), not just one.</t>"
]];

player createDiaryRecord ["WaldoHowToPlay", [
	"Detective Shop",
	"<t align='left'>" +
	"<t color='#ffd23f'>Radar</t> - pulses everyone's position (not role) for 45s, then recharges. Kept " +
	"cheap so map awareness is never the credit decision.<br/>" +
	"<t color='#ffd23f'>Medical Kit / Smoke Grenades / Stamina / Night Vision / Binoculars / Health " +
	"Station / Frag Grenades / Flower Power</t> - cheap utility (and one novelty).<br/><br/>" +
	"<t color='#ffd23f'>DNA Scanner</t> - sample DNA off a body or evidence, then track the suspect " +
	"hot/cold (see Investigation above). Limited uses per purchase, and priced to be the shop's default, " +
	"affordable investigative buy.<br/>" +
	"<t color='#ffd23f'>Enhanced Scanner</t> - upgrades the DNA Scanner: halves the misdirection risk, " +
	"longer/steadier tracks, and reveals time-of-death plus the murder weapon. Requires the DNA Scanner " +
	"first.<br/>" +
	"<t color='#ffd23f'>Defibrillator</t> - brings a body back as whatever it already was.<br/>" +
	"<t color='#ffd23f'>Body Armor</t> - survive long enough to keep investigating.<br/><br/>" +
	"<t color='#ffd23f'>Portable Tester</t> - aim at someone within 3m and instantly, guaranteed reveal " +
	"their role. Deliberately the single most expensive item here - it's a shortcut that trivialises " +
	"investigation, not the intended path, and is priced to make the DNA Scanner the shop's real answer.</t>"
]];

player createDiaryRecord ["WaldoHowToPlay", [
	"Fair Play & Karma",
	"<t align='left'>Killing a teammate outside your own role's rules - an Innocent killing another " +
	"Innocent, a Detective killing an Innocent, and so on - is Random Deathmatch (RDM). It docks your " +
	"karma, a value that carries over between rounds and slowly decays back toward neutral each round it " +
	"doesn't happen again. Low karma reduces how many credits you start your NEXT round with, scaled down " +
	"the lower it gets - not an instant zero, but a real, growing cost.<br/><br/>" +
	"A Traitor killing a fellow Traitor is treated more leniently, since you already knew who they were, " +
	"but it still costs a small credit penalty and a smaller karma hit than genuine RDM.<br/><br/>" +
	"Killing the Jester as a Traitor is its own hard mistake (see The Roles above): no win progress for " +
	"your team, and it strips your banked credits down to almost nothing.</t>"
]];

player createDiaryRecord ["WaldoHowToPlay", [
	"Controls",
	"<t align='left'>" +
	"<t color='#ffd23f'>M</t> - Map (this page lives under its Diary tab)<br/>" +
	"<t color='#ffd23f'>K</t> - Scoreboard + your live role briefing<br/>" +
	"<t color='#ffd23f'>H</t> - Role crest style picker<br/>" +
	"<t color='#ffd23f'>L</t> - Holster weapon<br/>" +
	"<t color='#ffd23f'>B</t> - Buy menu (Traitor/Detective)<br/>" +
	"<t color='#ffd23f'>Y / U / J</t> - Use the activation item bound to that slot<br/>" +
	"<t color='#ffd23f'>T (hold)</t> - Ping wheel (Traitor)<br/><br/>" +
	"Scroll-wheel a corpse for Identify Body, or a Health Station / defusable charge for their own " +
	"actions.</t>"
]];

player selectDiarySubject "WaldoHowToPlay";
