# Trouble In Armaville

Trouble In Armaville recreates *Trouble in Terrorist Town*, the fan-favourite Garry's Mod deception game, in Arma 3. This fan-made homage brings its hidden roles and equipment shops to Arma's towns, forests, and gunfights.

Most of you are Innocents. A few are Traitors, trying to kill everyone else while passing themselves off as part of the group. You'll spend a round searching for weapons, watching other players, and arguing about who fired first. If you're a Traitor, you'll need an explanation when someone finds the body.

<p align="center">
  <img src="https://github.com/AdamWaldie/TroubleInArmaville/blob/main/wiki/Images/RoleTraitor.jpg?raw=true" alt="Traitor HUD" width="49%">
  <img src="https://github.com/AdamWaldie/TroubleInArmaville/blob/main/wiki/Images/BuyMenuTraitor.jpg?raw=true" alt="Traitor shop" width="49%">
</p>

## Playing a round

- **Innocent:** Work out who the Traitors are and help kill them, or survive until time runs out. Most players are on your side.
- **Traitor:** You know your teammates. Coordinate your kills and spend shop credits on weapons or deception tools. You win when everyone outside your team is dead.
- **Detective:** Everyone knows your role. Use your investigation shop to test suspects and examine bodies. You win alongside the Innocents.
- **Jester:** Provoke an Innocent or Detective into killing you to steal the round. You cannot deal damage, and the Traitors know who you are.

Your private briefing tells you your role. After a death, survivors have to find the body and piece together what happened. Anyone can report a body, but a Detective can reveal its role to everyone. If you die, you spectate unless someone revives you with a defibrillator.

The Detective's DNA Scanner tracks a suspect's distance and bearing. Old samples lose strength, and players near a fresh scene can contaminate the evidence. A Portable Tester gives a definite role check, but you have to get close to the suspect to use it.

Traitors have ways to interfere. Plant someone else's DNA with False Flag, copy their loadout with Disguiser, or remove the body altogether. Dead Ringer lets you fake a death and leave a decoy corpse. A Traitor's defibrillator even brings a dead player back onto the Traitor team, while a Detective's preserves their original role.

<p align="center">
  <img src="https://github.com/AdamWaldie/TroubleInArmaville/blob/main/wiki/Images/Scoreboard.jpg?raw=true" alt="In-round scoreboard" width="70%">
</p>

## Maps, equipment, and settings

Each round chooses a new arena on the current terrain. Search it for loot and watch for airdrops, using Arma's weapons, optics, and ballistics. The mission draws weapons and clothing from loaded mods as well as vanilla gear.

Role-based kills earn shop credits. Killing teammates lowers your karma, which carries across rounds and can reduce your starting credits. Karma recovers over subsequent rounds.

Press **K** to review your briefing and the scoreboard. The map screen includes a first-time guide, and the role HUD has several crest styles and a colourblind-safe palette.

The mission runs on Altis, Tanoa, Stratis, Livonia, and Malden. The release workflow builds a terrain-specific package for each one.

## Get a game running

Bring a group for multiplayer. Arma 3 is required, along with access to your chosen terrain. CBA_A3, ACE3, ACRE2, and TFAR are optional, and the mission works without them.

1. Subscribe on the Steam Workshop, or download the matching terrain package from the [GitHub releases](https://github.com/AdamWaldie/TroubleInArmaville/releases).
2. For a manual install, unpack the package into your Arma 3 `MPMissions` folder.
3. Host the mission in multiplayer.

Each release uses the name `TroubleInArmaville_<version>.<Terrain>`. Livonia uses Arma's internal terrain name, `Enoch`.

Turn **Kill Messages** off in the server's difficulty settings. Every player slot uses the Civilian side, so Arma otherwise announces each kill to the whole server and exposes the killer.

## Lobby parameters

<p align="center">
  <img src="https://github.com/AdamWaldie/TroubleInArmaville/blob/main/wiki/Images/parameters.jpg?raw=true" alt="Lobby parameters screen" width="70%">
</p>

The lobby controls round timing, role assignment, karma, credits, loot, weather, time of day, arena size, and Testing Mode. See the [Lobby Parameters wiki page](https://github.com/AdamWaldie/TroubleInArmaville/wiki/Player-Lobby-Parameters) for the full list and the parameter-order rule.

## Keys

| Key | Action |
|---|---|
| **B** | Open the Traitor or Detective shop |
| **Y / U / J** | Use the activation item assigned to that slot |
| **L** | Holster or lower your weapon |
| **K** | Open the scoreboard and role briefing |
| **H** | Choose a role-crest style |
| **T** | Hold to choose and send a Traitor ping |
| **[** | Open the dev/test menu when Testing Mode is on |
| **]** | Cycle your role when Testing Mode is on |

## Testing and development

Enable **Testing Mode** in the lobby to run a solo round. It adds the dev menu, instant role cycling, test dummies, simulated players, shop and ability actions, arena controls, and forced round endings. Normal games cannot access these tools.

The [wiki](https://github.com/AdamWaldie/TroubleInArmaville/wiki) covers the mechanics, shop catalogs, parameters, architecture, equipment discovery, and contribution standards.

## Links

- [GitHub repository](https://github.com/AdamWaldie/TroubleInArmaville)
- [Releases](https://github.com/AdamWaldie/TroubleInArmaville/releases)
- [Wiki](https://github.com/AdamWaldie/TroubleInArmaville/wiki)
- [Waldo's Mission Pack](https://github.com/AdamWaldie/WaldosMissionPack)

## License

MIT. See [LICENSE](LICENSE).
