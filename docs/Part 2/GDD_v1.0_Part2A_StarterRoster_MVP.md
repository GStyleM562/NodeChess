# GDD_v1.0_Part2A_StarterRoster_MVP.md

# Part 2A - Starter Roster (MVP Prototype)

Version: 1.0

Status: DRAFT — for human approval + Meshy production

> 8 figures for the "is it fun?" prototype (Lobby → Deck Builder → match vs bot).
> Each sheet follows the Character Template (Part 2A §21/§35), passes the AI Validator
> (Part 2A §32), and carries a **Tier 1** animation block (Part 5B) + a **Meshy prompt**.
> Numbers are a balanced starting point, **not** locked — tweak freely.

---

## Coverage matrix

| # | Figure | Class | Attack System | Stamina | Rarity | Evolves | Role in the test |
| - | ------ | ----- | ------------- | ------- | ------ | ------- | ---------------- |
| 1 | Ironclad Knight | Balanced | **Dice (D6)** | 2 | Common | — | Reliable baseline |
| 2 | Stone Golem | Tank | **Wheel** | 1 | Rare | — | Hard to remove, anchor |
| 3 | Shadowfang | Agile/Striker | **Coin** | 3 | Epic | — | High-risk goal rush |
| 4 | Sky Falcon | Agile/Controller | **Wheel** | 4 | Rare | — | Flight + push, mobility |
| 5 | Venom Spider | Debuffer | **Wheel** | 2 | Epic | 2 stages | Status control + Hidden Passive |
| 6 | Ember Dragon | Striker | **Dice → Dice** | 3→2 | Legendary | 3 stages | Showpiece Rank Up + Hidden Passive |
| 7 | Arcane Wisp | Controller | **Dice Sum (2d6)** | 2 | Epic | — | Displacement + phase |
| 8 | Coin Trickster | Specialist | **Double Coin** | 3 | Legendary | — | High variance |

**Attack systems covered:** Wheel ✓ · Dice ✓ · Coin ✓ · Dice Sum ✓ · Double Coin ✓ (all 5).
**Classes covered:** Balanced, Tank, Agile, Striker, Controller, Debuffer, Specialist ✓.

**Shared animation block (Tier 1, all figures):** `idle` (breathing loop), locomotion
(`move_walk` or `move_fly`), `deploy`, `attack` + `attack_heavy` (Gold/Purple), `defend`, `hit`,
`ko`. `rankup` only for evolving figures. Buffed = `idle` + aura overlay (no clip). Status idles are
**Tier 2 (later)**. Per-figure extras (jump/fly/phase) noted below.

---

# Art Direction — ALL figures (Chibi / Mini)

**Global style for every figure on the board: CUTE / CHIBI / MINI.** This applies to **every**
Meshy prompt below — the per-figure "Visual Theme" describes *who* the character is; render all of
them in this chibi/mini language.

- **Proportions:** oversized head, small rounded body, big expressive eyes, short stubby limbs — a
  collectible "mini figure" look (think Pokémon Duel figures on bases).
- **Forms:** rounded, soft, chunky, readable silhouettes; minimal sharp clutter.
- **Base:** each figure stands on a small base/pedestal sized to the board node.
- **Cute even when menacing** ("cute-menacing"): Spider, Golem and Adult Dragon stay charming and
  adorable, **never scary** — exaggerate personality, shrink the threat.
- **Consistent mini scale** across all figures so they read cleanly at board distance and look great
  in the combat close-up.

---

# 1. Ironclad Knight

**Data**
- Class: Balanced (Tank lean) · Rarity: Common · Stamina: 2
- Attack Type: Dice (D6) · Movement Traits: Heavy
- Resistances: — · Evolution: none

**Attack Pool (D6)**

| Face | Outcome |
| ---- | ------- |
| 1 | White 60 |
| 2 | White 80 |
| 3 | Blue |
| 4 | Blue |
| 5 | Purple ★ |
| 6 | Gold 40 |

**Passives (2/3)**
1. *Hold the Line* — On Defend: a **tie** also Immobilizes the attacker for 1 turn.
2. *Bulwark* (Aura) — Adjacent allies cannot be Pushed/Pulled.

**Hidden Passive:** none.

**Lore:** A disciplined frontline guardian who turns a stalemate into a trap.

**Meshy prompt**
- Visual Theme: heavy armored knight, blue+steel palette, tower shield. **Chibi/mini build** (big head, tiny stocky body, huge shield).
- Read: bulky silhouette, clearly a defender.
- Animation Notes: idle = slow breathing, shield set; attack = shield bash / sword chop; attack_heavy (Gold) = shoulder charge; ko = armor shatters, kneels.
- Sound: heavy metal clanks, low grunts.

**Animation block (Tier 1):** idle ✓ · move_walk ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓ · (Heavy: no displacement reaction).

**Validator:** PASS — D6 valid, 2 passives ≤3, 1 trait ≤3.

---

# 2. Stone Golem

**Data**
- Class: Tank · Rarity: Rare · Stamina: 1
- Attack Type: Wheel · Movement Traits: Heavy, Anchor
- Resistances: Immune Push, Immune Pull · Evolution: none

**Attack Pool (Wheel — total 100%)**

| Segment | Prob |
| ------- | ---- |
| Blue | 35% |
| White 80 | 30% |
| White 50 | 15% |
| Gold 40 | 10% |
| Red (Miss) | 10% |

**Passives (2/3)**
1. *Bedrock* (Aura) — Cannot be displaced or swapped (reinforces Heavy/Anchor).
2. *Counter-Stone* — On Defend: a **Blue** win also Pushes the attacker 1 node.

**Hidden Passive:** none.

**Lore:** A walking wall. You don't move it — you go around it, if you can.

**Meshy prompt**
- Visual Theme: rocky stone golem, mossy cracks, glowing blue core, oversized arms. **Chibi/mini build** (big boulder head/body, stubby legs) — cute, not scary.
- Read: huge, immovable, low and wide.
- Animation Notes: idle = very slow heave, core pulse; move = single heavy step; attack = boulder fist slam; attack_heavy (Gold) = ground pound; ko = crumbles into rubble.
- Sound: grinding stone, deep impacts.

**Animation block (Tier 1):** idle ✓ · move_walk (slow) ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓ · (immovable: ignores pushed/pulled).

**Validator:** PASS — Wheel = 100%, Blue 35% ≤35, Miss 10% ≤30, 2 passives, 2 traits.

---

# 3. Shadowfang

**Data**
- Class: Agile / Striker · Rarity: Epic · Stamina: 3
- Attack Type: Coin · Movement Traits: Jump
- Resistances: — · Evolution: none

**Attack Pool (Coin)**

| Result | Outcome |
| ------ | ------- |
| Heads 49.5% | White 100 |
| Tails 49.5% | Purple ★★ (Fear) |
| Miss 1% | Red |

**Passives (2/3)**
1. *Pounce* — On Move: if it moved 2+ nodes before attacking, **Miss is rerolled once**.
2. *Bloodthirst* — On Enemy KO: may move 1 node immediately (no extra action).

**Hidden Passive:** none.

**Lore:** A blur of fang and shadow that punishes any opening.

**Meshy prompt**
- Visual Theme: black wolf with violet energy markings. **Chibi/mini build** (big head, big eyes, small body, oversized paws) — cute but fierce.
- Read: low, agile, predatory silhouette.
- Animation Notes: idle = alert crouch, tail flick; move_run = sprint; jump = leap over enemy; attack = lunge bite; attack_heavy (Purple) = shadow-fanged maul; ko = dissolves into shadow.
- Sound: growls, quick whooshes.

**Animation block (Tier 1):** idle ✓ · move_walk/run ✓ · jump ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓.

**Validator:** PASS — Coin Miss 1% ≤5, 2 passives, 1 trait.

---

# 4. Sky Falcon

**Data**
- Class: Agile / Controller · Rarity: Rare · Stamina: 4
- Attack Type: Wheel · Movement Traits: Hover (fly, ignore terrain)
- Resistances: — · Evolution: none

**Attack Pool (Wheel — total 100%)**

| Segment | Prob |
| ------- | ---- |
| White 50 | 30% |
| Gold 30 (Push 1) | 20% |
| Purple ★ | 15% |
| Blue | 10% |
| Red (Miss) | 25% |

**Passives (2/3)**
1. *Aerial* — Hover: flies over terrain (cosmetic terrain ignored; still blocked by occupancy unless jumping).
2. *Dive* — On Attack after flying 3+ nodes this turn: **Push 1 becomes Push 2**.

**Hidden Passive:** none.

**Lore:** Strikes from above, shoves the enemy off the objective, and is gone.

**Meshy prompt**
- Visual Theme: falcon, blue+gold plumage, wind motifs. **Chibi/mini build** (big head, round body, tiny talons, oversized wings) — cute.
- Read: winged, always airborne, light.
- Animation Notes: idle = hover with wing flaps; move_fly = gliding swoop; attack = talon strike / wing buffet (push); attack_heavy (Gold) = dive-bomb; ko = feathers scatter, spirals down.
- Sound: wing beats, screech.

**Animation block (Tier 1):** idle (hover) ✓ · **move_fly** ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓ · (never grounded).

**Validator:** PASS — Wheel = 100%, Miss 25% ≤30, low Blue (agile), 2 passives, 1 trait.

---

# 5. Venom Spider

**Data**
- Class: Debuffer · Rarity: Epic · Stamina: 2
- Attack Type: Wheel · Movement Traits: —
- Resistances: Resist Fear (−1 turn) · Evolution: 2 stages (Spider → Broodmother)

**Attack Pool — Stage 1 (Wheel — total 100%)**

| Segment | Prob |
| ------- | ---- |
| Purple ★ (Fear) | 25% |
| Purple ★★ (Weakened) | 15% |
| Blue | 15% |
| White 40 | 20% |
| Red (Miss) | 25% |

**Passives (2/3)**
1. *Venom Bite* — Purple wins also apply **Weakened** (1 turn) in addition to their listed effect.
2. *Skittering* — On Defend: a tie lets the Spider retreat 1 node after combat.

**Hidden Passive (Stage 2, earned Rank Up only):** *Venom Aura* (Aura) — adjacent enemies have **−1 Stamina** on their next turn.

**Evolution — Stage 2 (Broodmother):** Rank Up changes (1–3 attrs): Purple ★★ Fear segment grows to 25%, unlocks *Venom Aura*. Stamina stays 2.

**Lore:** Weaves a web of fear; the longer you linger, the weaker you get.

**Meshy prompt**
- Visual Theme: spider, dark chitin + toxic green glow, big fangs. Broodmother = larger, egg-sac, more legs. **Chibi/mini build** (big round body, big cute eyes, short legs) — cute-menacing, not scary.
- Read: creepy, low, many-legged.
- Animation Notes: idle = skittering twitch; move = scuttle; attack = fang stab (Purple venom spray); attack_heavy (Purple★★) = web-and-bite; rankup = molts into Broodmother (dramatic); ko = curls up.
- Sound: chittering, hissing.

**Animation block (Tier 1):** idle ✓ · move_walk (scuttle) ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓ · **rankup** ✓ (Spider→Broodmother).

**Validator:** PASS — Wheel = 100%, Purple 40% total ≤ designer range, Miss 25%, 2 passives + 1 hidden (earned only), evolution 2 ≤4.

---

# 6. Ember Dragon  *(showpiece — Rank Up)*

**Data**
- Class: Striker · Rarity: Legendary · Stamina: 3 → 2 → 2
- Attack Type: Dice (D6, improves per stage) · Movement Traits: — (gains nothing / Fast at stage 1)
- Resistances: Immune Burn (self) · Evolution: 3 stages (Baby → Young → Adult)

**Stage 1 — Baby Dragon (Dice D6, Stamina 3, mobile/low damage)**

| Face | Outcome |
| ---- | ------- |
| 1 | White 40 |
| 2 | White 60 |
| 3 | Red (Miss) |
| 4 | Purple ★ |
| 5 | Gold 30 |
| 6 | White 80 |

**Stage 2 — Young Dragon (Dice D6, Stamina 2)**

| Face | Outcome |
| ---- | ------- |
| 1 | White 60 |
| 2 | White 80 |
| 3 | Purple ★ |
| 4 | Gold 40 |
| 5 | White 100 |
| 6 | White 90 |

**Stage 3 — Adult Dragon (Dice D6, Stamina 2) — unlocks Hidden Passive**

| Face | Outcome |
| ---- | ------- |
| 1 | White 80 |
| 2 | Gold 50 |
| 3 | Purple ★★ (Weakened) |
| 4 | White 100 |
| 5 | Gold 60 |
| 6 | White 120 |

**Passives (1/3 base)**
1. *Fledgling Resolve* — On Rank Up: cleanse all debuffs (in addition to the standard Rank Up cleanse) and gain +1 Stamina until end of next turn.

**Hidden Passive (Adult, earned Rank Up only):** *Burning Aura* (Aura) — at the start of their turn, adjacent enemies become **Weakened** (1 turn).

**Lore:** From clumsy hatchling to sky-tyrant — each kill stokes the fire.

**Meshy prompt**
- Visual Theme: 3-stage dragon, **all stages chibi/mini** (big head, small rounded body). Baby = super cute, stubby wings, orange. Young = ember scales, small wings. Adult = bigger & horned but still chibi and cute-menacing (lava-veined, smoke) — never scary.
- Read: clearly escalates in size/menace per stage.
- Animation Notes: idle = breathing with ember puffs; move = flutter (baby) → stride; attack = bite/claw; attack_heavy (Gold) = fire breath; **rankup = the hero moment** (glow → rise → transform → new form revealed, 2–3s, skippable); ko = collapses, embers fade.
- Sound: chirps (baby) → roars (adult), fire whoosh.

**Animation block (Tier 1, per stage):** idle ✓ · move_walk ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓ · **rankup** ✓ (×2 transitions, visibly different per stage).

**Validator:** PASS — all D6 valid, stars ≤★★, evolution 3 ≤4, 1 base passive + 1 hidden (earned only).

---

# 7. Arcane Wisp

**Data**
- Class: Controller · Rarity: Epic · Stamina: 2
- Attack Type: Dice Sum (2d6) · Movement Traits: Phase
- Resistances: — · Evolution: none

**Attack Pool (2d6 sum)**

| Sum | Outcome |
| --- | ------- |
| 2 | Red (Miss) |
| 3 | White 20 |
| 4 | Purple ★ (Push 1) |
| 5 | Blue |
| 6 | Gold 30 (Swap) |
| 7 | White 50 |
| 8 | Purple ★★ (Pull 1) |
| 9 | Blue |
| 10 | Gold 40 |
| 11 | White 80 |
| 12 | Purple ★★★ (Swap + Push 1) |

**Passives (2/3)**
1. *Blink* — On Move: may Phase through 1 enemy (already enabled by trait; this guarantees it costs no extra stamina).
2. *Arcane Pull* — All Push/Pull/Swap distances from this figure +1 at sum ≥ 10.

**Hidden Passive:** none.

**Lore:** A mote of living spellfire that rearranges the battlefield at will.

**Meshy prompt**
- Visual Theme: floating arcane wisp — a tiny cloaked spectral **chibi** (big hood, big glowing eyes, little body), blue-violet glow, runes orbiting. **Chibi/mini build.**
- Read: ethereal, semi-transparent, hovering.
- Animation Notes: idle = gentle bob, runes rotate; move/phase = dissolves and reforms through obstacles; attack = bolt / telekinetic shove (push/pull/swap); attack_heavy (Gold/Purple) = reality-warp swap; ko = winks out.
- Sound: arcane hums, chimes, whooshes.

**Animation block (Tier 1):** idle ✓ · move_walk (float) ✓ · **phase** ✓ (core locomotion) · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓.

**Validator:** PASS — 2d6 valid (higher = generally stronger), stars ≤★★★, 2 passives, 1 trait. Note Swap-into-Goal triggers Surround-KO check before Victory (Part 2A §17).

---

# 8. Coin Trickster

**Data**
- Class: Specialist · Rarity: Legendary · Stamina: 3
- Attack Type: Double Coin · Movement Traits: —
- Resistances: — · Evolution: none

**Attack Pool (Double Coin — each coin 50/50, results combined)**

| Coin A | Coin B | Combined result | Prob |
| ------ | ------ | --------------- | ---- |
| H (White 60) | H (Gold 40) | **White 100** | 25% |
| H (White 60) | T (Blue) | **Blue** | 25% |
| T (Purple ★) | H (Gold 40) | **Gold 50** | 25% |
| T (Purple ★) | T (Blue) | **Purple ★★** | 25% |

**Passives (1/3)**
1. *Loaded Dice* (Once Per Match) — Reroll one of its own coins after a flip.

**Hidden Passive:** none.

**Lore:** Fortune's favorite. Every flip is a gamble — usually a winning one.

**Meshy prompt**
- Visual Theme: flamboyant trickster/jester, gold coins motif, purple+gold, mischievous. **Chibi/mini build** (big head, big grin, small body) — cute and playful.
- Read: flashy, theatrical, mid-size.
- Animation Notes: idle = tossing a coin, sly grin; move = jaunty stride; attack = coin-flick / cane strike; attack_heavy (Gold/Purple) = cascade of coins; ko = pratfall, coins scatter.
- Sound: coin jingles, chuckles, whooshes.

**Animation block (Tier 1):** idle ✓ · move_walk ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓.

**Validator:** PASS — Double Coin combination designer-defined, 1 passive, stars ≤★★.

---

# Notes for Meshy production

- **Priority order** (sells the prototype fastest): **Ember Dragon** (Rank Up showpiece) → **Stone Golem** & **Ironclad Knight** (readable defenders) → **Shadowfang** & **Sky Falcon** (mobility/flight) → **Venom Spider** (status + 2nd evo) → **Arcane Wisp** & **Coin Trickster** (specialists).
- **Medium poly + LODs** — figures appear on the board (medium distance) and in the combat close-up.
- **Shared skeleton where possible** (humanoid: Knight, Trickster; quadruped: Shadowfang) → reuse a Godot `AnimationLibrary` (Part 5B §7).
- **Per-figure animation = the Tier 1 list above.** Evolving figures (Dragon ×3 forms, Spider ×2) need a model per stage + a `rankup` transition.

# Status & Next

Status: **DRAFT** — awaiting human approval. Once approved:
1. Hand each figure's **Meshy prompt + animation block** to Meshy.
2. These sheets define the **data schema** for the Godot project (Part B): they become `.tres`/JSON
   resources (Figure → stats, attack pool, passives, evolution, animation map).

END OF STARTER ROSTER
