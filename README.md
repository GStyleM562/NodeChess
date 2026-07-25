# NodeChess

**NodeChess** — a Tactical Board Battler (top-down, Android, portrait, online 1v1).

This repository hosts the **full project**: the Godot 4.6 game, the Node.js
relay server for online play, and the design documentation.

| Folder | What it is |
| ------ | ---------- |
| [`game/`](game/) | The Godot 4.6 project (GDScript). Tests live in [`game/tools/`](game/tools/) — 50 headless suites, runner `run_suite.ps1`. |
| [`nodechess_server/`](nodechess_server/) | Node.js WebSocket relay (rooms by code + random matchmaking), deployed on Render. |
| [`docs/`](docs/) | Design docs (GDD Parts 1–5), changelog, pending work, legal. |

## Where to start

- **Current state & recent work:** [CHANGELOG](docs/CHANGELOG.md)
- **What's left to launch:** [PENDIENTES_Lanzamiento](docs/PENDIENTES_Lanzamiento.md)
- **The whole game design in one read:** [GDD Context Summary](docs/GDD_Context_Summary.md)
- **UI/UX rules to follow:** [UIUX_Juicy_Hall](docs/UIUX_Juicy_Hall.md)
- **Legal (MX) & Play Console:** [terminosycondiciones](docs/terminosycondiciones.md)

## Documentation

All design documents live under [`docs/`](docs/), organized by part:

| Part | Topic |
| ---- | ----- |
| **Part 1** | [Core Rules](docs/Part%201%20Core%20Rules/) |
| **Part 2** | [Character Framework, Modifiers, Deck Builder, Maps](docs/Part%202/) · [Starter Roster (MVP)](docs/Part%202/GDD_v1.0_Part2A_StarterRoster_MVP.md) |
| **Part 3** | [PvE Framework](docs/Part%203/) |
| **Part 4** | [Economy & Progression](docs/Part%204/) |
| **Part 5** | [UI/UX & Visual Direction](docs/Part%205%20Design%20UIUX/) · [Character Animation & Liveliness](docs/Part%205%20Design%20UIUX/GDD_v1.0_Part5B_CharacterAnimation.md) |

Visual references: [docs/Images Reference/](docs/Images%20Reference/)

## Status

| Property | Value |
| -------- | ----- |
| Build | 0.33 (versionCode 33) |
| Document Status | Rules Locked |
| Target Platform | Android (portrait) |
| Genre | Tactical Board Battler |
| Multiplayer | Yes — rooms by code + random matchmaking (Render relay `v25`) |
| Tests | 50/50 green |
| Engine | Godot 4.6.3 |
