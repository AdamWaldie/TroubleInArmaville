# Trouble In Armaville

Trouble In Armaville is a fan-made Arma 3 recreation of *Trouble in Terrorist Town*. It is a homage to the original game mode, retaining its hidden roles, deduction, and equipment shops while using Arma's maps, weapons, and ballistics.

<p align="center">
  <img src="https://github.com/AdamWaldie/TTTARMA3/blob/main/wiki/Images/RoleTraitor.jpg?raw=true" alt="Traitor HUD" width="49%">
  <img src="https://github.com/AdamWaldie/TTTARMA3/blob/main/wiki/Images/BuyMenuTraitor.jpg?raw=true" alt="Traitor shop" width="49%">
</p>

## Four roles, one deduction game

- **Innocents** work out who lies and win when every Traitor is dead.
- **Traitors** know their teammates, share a shop, and win by killing everyone else.
- **Detectives** are public Innocents with tools for testing, DNA scanning, and radar.
- **Jesters** cannot win by force. They win when a non-Traitor kills them.

Bodies do not announce their killer. Players must find a body, call it in, and investigate the evidence. DNA decays. Other players can contaminate a scene. The Detective gets information, not certainty.

<p align="center">
  <img src="https://github.com/AdamWaldie/TTTARMA3/blob/main/wiki/Images/Scoreboard.jpg?raw=true" alt="In-round scoreboard" width="70%">
</p>

## Features

- A new arena chosen from the current terrain each round.
- Credits for role-based kills and shops for Traitors and Detectives.
- Dynamic weapon, clothing, loot, and airdrop discovery from the mods you load.
- Karma that carries across rounds.
- A private role briefing and the in-round scoreboard on **K**.
- Several role-crest styles, including a colourblind-safe palette.
- A first-time guide in the map screen.

The mission runs on Altis, Tanoa, Stratis, Livonia, and Malden. The release workflow builds a terrain-specific package for each one.

## Installation

1. Subscribe on the Steam Workshop, or download the matching terrain package from the [GitHub releases](https://github.com/AdamWaldie/TTTARMA3/releases).
2. For a manual install, unpack the package into your Arma 3 `MPMissions` folder.
3. Host the mission in multiplayer.

Each release uses the name `TroubleInArmaville_<version>.<Terrain>`. Livonia uses Arma's internal terrain name, `Enoch`.

## One server setting

Turn **Kill Messages** off in the server's difficulty settings. Every player slot uses the Civilian side, so Arma otherwise announces each kill to the whole server and exposes the killer.

## Lobby parameters

<p align="center">
  <img src="https://github.com/AdamWaldie/TTTARMA3/blob/main/wiki/Images/parameters.jpg?raw=true" alt="Lobby parameters screen" width="70%">
</p>

The lobby controls round timing, role assignment, karma, credits, loot, weather, time of day, arena size, and Testing Mode. See the [Lobby Parameters wiki page](https://github.com/AdamWaldie/TTTARMA3/wiki/Player-Lobby-Parameters) for the full list and the parameter-order rule.

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

The [wiki](https://github.com/AdamWaldie/TTTARMA3/wiki) covers the mechanics, shop catalogs, parameters, architecture, equipment discovery, and contribution standards.

## Dependencies

Arma 3 is the only requirement. CBA_A3, ACE3, ACRE2, and TFAR are optional. The mission detects them at runtime and keeps a vanilla path when they are absent.

## Links

- [GitHub repository](https://github.com/AdamWaldie/TTTARMA3)
- [Releases](https://github.com/AdamWaldie/TTTARMA3/releases)
- [Wiki](https://github.com/AdamWaldie/TTTARMA3/wiki)
- [Waldo's Mission Pack](https://github.com/AdamWaldie/WaldosMissionPack)

## License

MIT. See [LICENSE](LICENSE).
