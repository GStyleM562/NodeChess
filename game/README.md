# NodeChess — Godot project (`game/`)

Godot **4.6.3** project. Current state = **MVP scaffold**: a 3D **Figure Preview** that proves the
Meshy models + animations are wired correctly. The full game (board, turns, lobby, deck, battle vs
bot) is built on top of this next.

## Open & run

1. Open **Godot 4.6.3** → Import → select `game/project.godot`.
2. Press **F5** (or Play). Main scene = `scenes/figure_preview.tscn`.

> Headless check (no editor): `Godot --headless --path game --import` then
> `Godot --headless --path game --script res://tools/verify_figures.gd`.

## Figure Preview controls

- **Prev / Next** — cycle figures.
- **Turntable** — toggle the slow rotation.
- **Clip buttons** — `idle, move_walk, move_run, attack, attack_heavy, defend, hit, ko`.
- Keyboard: **←/→** switch figures, **Space** = idle.

## Figure status

| Figure | Model | Animations (Tier 1) |
| ------ | ----- | ------------------- |
| Stone Golem | ✅ | ✅ 8 clips |
| Ironclad Knight | ✅ | ✅ 8 clips |
| Nightblade | ✅ | ✅ 8 clips |
| Rift Mage | ✅ | ✅ 8 clips |
| Venom Witch | ✅ | ✅ 8 clips |
| Storm Valkyrie | ✅ | ⚠️ 1 clip (needs full set) |
| Emberborn, Coin Trickster | ⏳ | pending |

All clip maps verified against the imported GLBs (0 unresolved).

## How figures are wired

- **`scripts/Roster.gd`** — the roster table: each figure's GLB path + an explicit
  Meshy-clip → Tier 1 map (e.g. `"idle": "Idle_3"`). Duplicates allowed in a deck (few figures).
- **`scripts/Figure3D.gd`** — loads a figure GLB, **normalizes its height** (consistent on-board
  scale), finds the `AnimationPlayer`, loops idle/walk, and plays clips by our Tier 1 names.
- **`scripts/FigurePreview.gd`** — the viewer scene (camera, light, base disc, UI).
- **`tools/verify_figures.gd`** — headless validator (lists imported anims, checks the map).

When a new figure GLB arrives, drop it in `assets/figures/<slug>/` and add one entry to `Roster.gd`.

## Layout

```
game/
  project.godot
  scenes/figure_preview.tscn
  scripts/{Figure3D, Roster, FigurePreview}.gd
  tools/verify_figures.gd
  assets/figures/<slug>/<slug>.glb   (+ ASSETS_GUIDE.md)
```

## Next (the real skeleton)

Rules engine (nodes/turns/combat/KO/rank-up/energy) → isometric 3D board → Lobby → Deck Builder →
match vs a Medium bot. Figures above slot straight in.
