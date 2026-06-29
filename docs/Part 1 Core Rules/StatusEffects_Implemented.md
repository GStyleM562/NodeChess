# Status Effects — Implemented Definitions (NodeChess)

> The GDD (Part 2A §29) lists 13 statuses but, because the game has **no HP**, it
> never defined what most of them *do*. This file is the implemented source of
> truth. All effects live in `game/scripts/GameState.gd` and are covered by
> `game/tools/test_statuses.gd`.

There is **no HP**: combat is binary (win → KO). So statuses work by one of three
mechanisms: **gate an action**, **debuff the roll**, or act as a **lethal timer**.

## Apply / cleanse
- Applied when a winning **Purple** segment carries a matching `fx` label (see
  `FX_STATUS`), or by passives/auras.
- **Rank Up** and the **Cleanse** modifier remove *all* statuses (DOT timers included).
- Default duration `STATUS_DUR = 4` game-turns (~2 rounds). DOTs last longer.

| Status | `fx` label | Effect (no-HP model) | Mechanism |
|--------|-----------|----------------------|-----------|
| Fear | Miedo | Cannot **attack** | gate |
| Immobilized | Inmovilizado | Cannot **move** | gate |
| Paralysis | Paralizado | Cannot move **nor** attack | gate |
| Weakened | Debilitado | Roll: **−20 dmg, −1★** | roll debuff |
| **Freeze** | Congelado | Cannot move nor attack **and** its Blue defence collapses to a Miss | gate + roll |
| **Sleep** | Sueño | Cannot move nor attack; **wakes** (cleared) the moment it enters combat | gate (self-clearing) |
| **Burn** | Quemadura | **Lethal timer** — KO after `BURN_TURNS = 6` game-turns; also **−10 dmg** while burning | DOT + roll debuff |
| **Poison** | Veneno | **Lethal timer** — KO after `POISON_TURNS = 8` game-turns (slower, no roll penalty) | DOT |
| **Silence** | Silencio | Its **Purple** specials fizzle to a Miss | roll (purple→red) |
| **Shield Break** | Escudo Roto | Its **Blue** defence collapses to a Miss | roll (blue→red) |
| **Confusion** | Confusión | When **attacking**, 50% chance the roll fumbles to a Miss | roll (random→red) |
| **Curse** | Maldición | **Loses ties** — a tie counts as a loss for the cursed (unless both rolled a Miss, or both cursed) | outcome flip |
| **Marked** | Marcado | The **opponent** attacking this figure gets **+20 dmg / +1★** (easier to KO) | opponent roll buff |

## Design notes / tunables
- **Burn/Poison are genuinely lethal** (the timer *is* the kill, since there is no
  HP). They are strong, so: they only trigger from a **Purple win** carrying the
  `fx`, they are **cleansable** (Rank Up / Cleanse), and **no built-in roster
  figure uses them yet** — they exist for **Character-Creator** content. Tune
  `BURN_TURNS` / `POISON_TURNS` / `BURN_DMG_PEN` in `GameState.gd`.
- `burning_aura` (Emberborn's hidden passive) still applies **Weakened**, not Burn,
  to avoid an auto-KO aura on an existing figure.
- Freeze and Shield Break share the "Blue → Miss" effect; Freeze adds the gate.

## Still pending (per GDD, not blocking)
- Displacement: **Dash, Retreat, Teleport** (Push/Pull/Swap done).
- Movement traits with real pathfinding: **Phase, Aerial/Hover, Anchor, Fast Recovery**.
- **Resistances** (Immunity / −duration / Conversion).
- **Buff Node states** (Charging/Active/Cooldown) and **Trap** modifiers.
- **Loaded Dice** passive UI.
