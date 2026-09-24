# Trouble In Armaville

Trouble in Terrorist Town, rebuilt in Arma 3. Hidden roles, a round timer, credit shops, and DNA forensics turn every death into a question.

## Playing or hosting

- **[Roles and Win Conditions](Player-Roles-and-Win-Conditions)** covers the four roles and the order in which endings resolve.
- **[Shops and Items](Player-Shops-and-Items)** lists the Traitor and Detective catalogs, purchase rules, and activation slots.
- **[Investigation Mechanics](Player-Investigation-Mechanics)** explains DNA, contamination, Identify Body, Dead Ringer, False Flag, and Disguiser.
- **[Lobby Parameters](Player-Lobby-Parameters)** explains every host setting.

## Contributing

- **[Community Localisations](Dev-Community-Localisations)** explains how to correct or add translations and validate them in-game.
- **[Architecture](Dev-Architecture)** maps the function library, round state, and respawn flow.
- **[Equipment System](Dev-Equipment-System)** explains dynamic arsenal discovery.
- **[Dev and Test Mode](Dev-Test-Mode)** explains the solo test framework and simulated players.
- **[Code Standards](Dev-Code-Standards)** records the naming and implementation patterns used here.

## Quick facts

- Arma 3 is required. CBA_A3, ACE3, ACRE2, and TFAR are optional.
- Each round ends with a full mission restart (`BIS_fnc_endMissionServer`).
- The mission discovers equipment from the mods loaded at mission start. It has no modpack preset files.
- The project uses the MIT License. See [LICENSE](https://github.com/AdamWaldie/TTTARMA3/blob/main/LICENSE).

Start with the [repository README](https://github.com/AdamWaldie/TTTARMA3/blob/main/README.md) for installation.
