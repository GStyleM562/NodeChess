# GDD Context Summary — NodeChess (v1.0)

> Condensed reference of the full GDD (Parts 1–5). Written so anyone (or any tool) can
> get the whole game in one read without revisiting every document. Source of truth is
> still the individual `GDD_v1.0_*` files; this is a navigational summary.

---

## 0. One-line pitch

A **3D tactical board battler** for **Android (portrait)**, multiplayer-capable but **MVP = vs CPU**.
Six "Figures" per player move across a node board, fight via **probability combat** (no HP), can
**Rank Up mid-match**, and win by **reaching the enemy Goal**. Feel target: *Pokémon Duel × Clash Royale*.

---

## 1. Core Rules (Part 1)

- **Figures:** exactly **6 per player**. Properties: Name, Rank Stages, Stamina, Attack Type, Attack Pool, Status Resistances, Passives, Movement Traits, Evolution Data.
- **No HP.** Combat is binary → loser is **KO'd** instantly, sent to **KO Bench** (5-turn cooldown, then back to Main Bench).
- **Turns:** strictly alternating, **1 action per turn**, never skippable. Actions: **Deploy / Move / Attack** (move can chain into attack — single action).
- **Movement:** **Stamina** = max nodes traversable. Partial moves allowed. Enemies block; **Jump** (spend remaining stamina to hop an enemy) and **Phase** (ignore blocking) exist.
- **Surround KO:** a Figure fully surrounded by **enemies** (no escape node) is KO'd. Friendlies never cause it.
- **Combat resolution order (11 steps):** Declare → Modifiers → Buff Nodes → Passives → Debuffs → Attack Roll → Winner → Status → KO check → Rank Up check → Victory check.
- **Attack Types:** **Wheel** (custom % segments), **Dice** (D4–D12, default D6), **Coin**, plus **Double Coin** and **Dice Sum (2dN)**.
- **Color hierarchy:**
  - **White** = damage. Beats Gold (by damage), loses to Purple.
  - **Purple** = special/stars (★1–3). Beats White, loses to Gold.
  - **Gold** = special offensive. Beats Purple, can lose to White, immune to Purple effects.
  - **Blue** = defensive, **highest priority — beats White/Purple/Gold**.
  - **Red** = Miss, always loses.
  - Ties = nothing happens, both remain.
- **Status effects:** Paralysis, Immobilized, Fear, Weakened (+ future: Burn/Poison/Freeze/Silence/Confusion/Sleep/Curse/Mark/Shield Break). Duration in turns; expire automatically.
- **Rank Up:** temporary (match-only). Trigger = **KO an enemy in combat**. Cleanses debuffs, can change Attack Pool/Type/Stamina/Passives/etc. Resets to base form next match.
- **Energy:** player-owned resource. Start 0, **+1 at start of each turn**, **cap 10**. Only spent on Modifiers.
- **Modifiers:** 3 equipped per player, hidden until first use, then public. Have Energy cost / cooldown / uses. Resolve **before** combat.
- **Buff Nodes:** board objectives; require charge time (leaving resets progress); grant Offensive/Defensive/Utility/Economy/Objective effects; have cooldowns/ownership.
- **Entrances:** deploy points (2–3 per map); one figure per node; occupied entrance is unusable by anyone.
- **Goals:** each player has one. **Enter enemy Goal = immediate victory.** Secondary victory = enemy can't deploy / has no active figures / entrances blocked.
- **Resolution priority (global):** Passives → Modifiers → Buff Nodes → Debuffs → Attack Roll → Status → KO → Rank Up → Victory.

## 2. Content Framework (Part 2)

- **Character classes** (categorize, don't restrict): Balanced, Agile, Tank, Debuffer, Buffer, Striker, Controller, Specialist.
- **Stamina guide:** Tank 1–2, Balanced 2, Agile 3–4, Extreme 5. Rarity affects acquisition only, **never power**.
- **Passives:** max 3 (+ Hidden Passives unlocked only via *earned* Rank Up, not direct deploy). Triggers: OnDeploy/Move/Attack/Defend/KO/EnemyKO/RankUp/BuffNode/Modifier/Goal/Aura/OncePerMatch/Cooldown.
- **Movement Traits:** Jump, Phase, Heavy (no push), Anchor (no swap), Hover (ignore terrain), Fast Recovery (−1 KO cooldown).
- **Displacement:** Push, Pull, Swap, Dash, Retreat, Teleport (Swap into enemy Goal → Surround-KO check before Victory).
- **Evolution:** 1–4 stages (recommend 3); 1–3 attribute changes per stage; can introduce weaknesses, not just power.
- **AI validators** exist for Characters / Modifiers / Buff Nodes / Decks / Maps — AI-generated content MUST pass (regenerate on INVALID); humans may override warnings.
- **Modifiers:** categories = Attack/Defense/Utility/Control/Economy/Rank/Revive/Trap/Special. Cost tiers 1–10. Traps placed on nodes, hidden until triggered.
- **Deck:** **6 Figures + 3 Modifiers** (no duplicate Modifiers). Must be 6/6 + 3/3 to queue. Up to 20 saved decks; sharing via codes.
- **Collection:** favorites, tags, wishlist, search/filter/sort, skins (cosmetic only), Encyclopedia (silhouette → seen → owned), completion %.
- **Maps:** symmetrical (MVP), 18–60 nodes, 2–3 entrances, 0–4 buff nodes. Archetypes: Aggro / Control / Fortress / Triple Spawn / Ring / Crossroads / Temple. Combat expected by turn 2–6 depending on type. Connections can be H/V/Diagonal. Map Validator enforces symmetry, reachability, spawn fairness, mobile readability.

## 3. PvE (Part 3) — *the MVP focus*

- **Primary MVP goal: "Validate if the game is fun" via VS CPU.** PvP is secondary.
- Modes: **VS CPU** (MVP), Tutorials (10 planned), Puzzle Battles, Boss Battles (PvE-only, may break rules).
- **Bots never cheat** (no hidden info, no extra stats — bosses excepted). Difficulty = decision depth: Easy(0–1) / Medium(1) / Hard(2) / Expert(3+ turns).
- **Personalities:** Aggressive, Defensive, Goal Rusher, Buff Controller, Rank Up Lover, Turtle, Random, Expert. Bot = Difficulty + Personality.
- **AI loop:** each turn → generate legal actions → score → execute best. Expert priority list: Win > Prevent loss > Rank Up > Buff Node > KO > Protect Goal > Reposition > Deploy > Fallback move.

## 4. Economy (Part 4) — LOCKED, MVP mostly disabled

- **No Pay-To-Win, no gameplay-energy gate.** Cosmetics & collection only.
- Currencies: Soft / Premium / Event. Acquisition: chests, shop, fragments, events, challenges, campaigns. Duplicates allowed (convertible to fragments/currency).
- Player level unlocks features (e.g. PvP at L10). Pity system, daily/weekly missions (MVP disabled), optional ads (never mandatory/interrupting).

## 5. UI/UX & Visual Direction (Part 5)

- **Feel:** 40% Pokémon Duel + 40% Clash Royale + 10% Marvel Snap + 10% modern mobile. Dark, futuristic, elegant, minimal.
- **Color palette:** Primary **Blue**, Secondary **Orange**, Accent **Gold**, Success Green, Danger Red, Background Dark Gray. Buff Node states: Inactive=Gray, Charging=Orange/Yellow, Active=Blue, Cooldown=Red.
- **Home:** top bar (avatar/level/currencies/energy/inbox/settings), large character centerpiece (idle anim), ≤5 big bottom buttons (Play/Decks/Collection/Shop/Events).
- **Deck Builder:** Clash-Royale-style; deck tabs, 6 figures + 3 modifiers, scrollable collection w/ filters, tap-for-detail popup (with 3D model).
- **Battle:** board = 70–80% of screen, HUD 20–30%. Combat darkens board, enlarges figures, shows roll (≤5s). Energy bottom-left, big End-Turn bottom-right.
- **Mobile rules:** portrait mandatory, touch targets ≥48×48dp, 60 FPS target (30 acceptable low-end), colorblind mode, animation skip, combat ×2 speed.
- **MVP screens (critical):** Home, Deck Builder, Collection, Battle, Rewards, Figure Detail.
- **Claude Design constraints:** SHOULD follow GDD, suggest layout/hierarchy/icons/accessibility/microinteractions. SHOULD NOT invent mechanics/currencies/menus/PvP/battle systems.

---

## 6. Project status snapshot (as of 2026-06-21)

| Part | Topic | Status |
| ---- | ----- | ------ |
| 1 | Core Rules | LOCKED |
| 2 | Content (Characters, Modifiers, Buff Nodes, Deck, Collection, Maps) | LOCKED |
| 3 | PvE Framework | WIP ~90% |
| 4 | Economy & Progression | LOCKED |
| 5 | UI/UX & Visual Direction | LOCKED (100%) |

**Tooling available:** Godot 4.6.3 (`F:\Godot`), Meshy (3D assets/animations/board), Claude Design (UI mockups).

**MVP target (recommended build order):** Lobby → Deck Builder → single VS-CPU match on one small symmetrical map, with a Medium bot, to answer the GDD's core question: *is it fun?*
