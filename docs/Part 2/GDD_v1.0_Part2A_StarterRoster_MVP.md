# GDD_v1.0_Part2A_StarterRoster_MVP.md

# Part 2A - Starter Roster (MVP Prototype)

Version: 1.1

Status: DRAFT — for human approval + Meshy production

> 8 figures for the "is it fun?" prototype (Lobby → Deck Builder → match vs bot).
> Each sheet follows the Character Template (Part 2A §21/§35), passes the AI Validator
> (Part 2A §32), and carries a **Tier 1** animation block (Part 5B) + a **Meshy prompt**.
> Numbers are a balanced starting point, **not** locked — tweak freely.
>
> **v1.1 — ALL figures are now humanoid / bipedal.** Meshy currently animates humanoids only, so
> the former animal/creature figures (wolf, bird, spider, dragon, wisp) were re-skinned as humanoids
> **keeping their exact gameplay** (class, attack system, stamina, attack pool, passives, evolution,
> traits). One shared, Mixamo-friendly animation approach for the whole roster.

---

## Coverage matrix

| # | Figure | Class | Attack System | Stamina | Rarity | Evolves | Role in the test |
| - | ------ | ----- | ------------- | ------- | ------ | ------- | ---------------- |
| 1 | Ironclad Knight | Balanced | **Dice (D6)** | 2 | Common | — | Reliable baseline |
| 2 | Stone Golem | Tank | **Wheel** | 1 | Rare | — | Hard to remove, anchor |
| 3 | Nightblade | Agile/Striker | **Coin** | 3 | Epic | — | High-risk goal rush |
| 4 | Storm Valkyrie | Agile/Controller | **Wheel** | 4 | Rare | — | Flight + push, mobility |
| 5 | Venom Witch | Debuffer | **Wheel** | 2 | Epic | 2 stages | Status control + Hidden Passive |
| 6 | Emberborn | Striker | **Dice → Dice** | 3→2 | Legendary | 3 stages | Showpiece Rank Up + Hidden Passive |
| 7 | Rift Mage | Controller | **Dice Sum (2d6)** | 2 | Epic | — | Displacement + blink |
| 8 | Coin Trickster | Specialist | **Double Coin** | 3 | Legendary | — | High variance |

**Attack systems covered:** Wheel ✓ · Dice ✓ · Coin ✓ · Dice Sum ✓ · Double Coin ✓ (all 5).
**Classes covered:** Balanced, Tank, Agile, Striker, Controller, Debuffer, Specialist ✓.
**All humanoid/bipedal** → one shared rig approach; humanoid clips fillable from Mixamo.

**Shared animation block (Tier 1, all figures):** `idle` (breathing loop), locomotion
(`move_walk`/`move_fly`/`phase`), `deploy`, `attack` + `attack_heavy` (Gold/Purple), `defend`,
`hit`, `ko`. `rankup` only for evolving figures. Buffed = `idle` + aura overlay (no clip). Status
idles are **Tier 2 (later)**. Per-figure extras (jump/fly/phase) noted below.

---

# Art Direction — ALL figures (Chibi / Mini, humanoid)

**Global style for every figure on the board: CUTE / CHIBI / MINI, humanoid.** This applies to
**every** Meshy prompt below — the per-figure "Visual Theme" describes *who* the character is; render
all of them in this chibi/mini language.

- **Proportions:** oversized head, small rounded body, big expressive eyes, short stubby limbs — a
  collectible "mini figure" look (think Pokémon Duel figures on bases).
- **Forms:** rounded, soft, chunky, readable silhouettes; minimal sharp clutter.
- **Base:** each figure stands on a small base/pedestal sized to the board node.
- **Cute even when menacing** ("cute-menacing"): Golem, Venom Witch and Infernal Warlord stay
  charming and adorable, **never scary** — exaggerate personality, shrink the threat.
- **Humanoid / bipedal:** every figure has a head, torso, two arms, two legs (wings/cloaks/extra
  gear are fine on top) so Meshy can rig + animate it.
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
- Visual Theme: heavy armored knight, blue+steel palette, tower shield. **Chibi/mini humanoid** (big head/helm, tiny stocky body, huge shield).
- Read: bulky silhouette, clearly a defender.
- Animation Notes: idle = slow breathing, shield set; attack = shield bash / sword chop; attack_heavy (Gold) = shoulder charge; ko = armor shatters, kneels.
- Sound: heavy metal clanks, low grunts.

**Animation block (Tier 1):** idle ✓ · move_walk ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓ · (Heavy: no displacement reaction).

**Production:** ✅ **DONE** — `ironclad_knight/ironclad_knight.glb` (textured, 24-joint rig, 8 clips: Idle_5/Walking/Running/Attack/Axe_Spin/Shield_Push_Left/Hit_Reaction_1/Dead).

**Validator:** PASS — D6 valid, 2 passives ≤3, 1 trait ≤3. Humanoid.

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
- Visual Theme: rocky stone golem **(bipedal humanoid build)**, mossy cracks, glowing blue core, oversized arms. **Chibi/mini** (big boulder head/body, stubby legs) — cute, not scary.
- Read: huge, immovable, low and wide.
- Animation Notes: idle = very slow heave, core pulse; move = single heavy step; attack = boulder fist slam; attack_heavy (Gold) = ground pound; ko = crumbles into rubble.
- Sound: grinding stone, deep impacts.

**Animation block (Tier 1):** idle ✓ · move_walk (slow) ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓ · (immovable: ignores pushed/pulled).

**Production:** ✅ **DONE** — `game/assets/figures/stone_golem/stone_golem.glb` (textured, biped rig, 8 clips: Idle/Walking/Running/Attack/Axe_Spin/Block2/Hit_Reaction/Knock_Down).

**Validator:** PASS — Wheel = 100%, Blue 35% ≤35, Miss 10% ≤30, 2 passives, 2 traits. Humanoid (biped).

---

# 3. Nightblade  *(was Shadowfang — re-skinned humanoid, same gameplay)*

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
1. *Lunge* — On Move: if it moved 2+ nodes before attacking, **Miss is rerolled once**.
2. *Bloodthirst* — On Enemy KO: may move 1 node immediately (no extra action).

**Hidden Passive:** none.

**Lore:** A hooded assassin who turns a single opening into a finish.

**Meshy prompt**
- Visual Theme: **chibi/mini humanoid assassin**, dark hooded cloak, twin violet-energy daggers, lean and nimble.
- Read: low, agile, predatory silhouette; hood + blades read instantly.
- Animation Notes: idle = alert crouch, blade twirl; move_run = sprint; jump = leap over enemy; attack = dagger lunge; attack_heavy (Purple) = spinning twin-stab; ko = collapses into shadow.
- Sound: cloth swish, quick blade whooshes.

**Animation block (Tier 1):** idle ✓ · move_walk/run ✓ · jump ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓. Humanoid → Mixamo covers all.

**Validator:** PASS — Coin Miss 1% ≤5, 2 passives, 1 trait. Humanoid.

---

# 4. Storm Valkyrie  *(was Sky Falcon — re-skinned humanoid, same gameplay)*

**Data**
- Class: Agile / Controller · Rarity: Rare · Stamina: 4
- Attack Type: Wheel · Movement Traits: Hover (winged flight, ignore terrain)
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
1. *Aerial* — Winged flight: flies over terrain (cosmetic terrain ignored; still blocked by occupancy unless jumping).
2. *Dive* — On Attack after flying 3+ nodes this turn: **Push 1 becomes Push 2**.

**Hidden Passive:** none.

**Lore:** A winged warrior who strikes from above, shoves the enemy off the objective, and is gone.

**Meshy prompt**
- Visual Theme: **chibi/mini humanoid valkyrie** with feathered wings, blue+gold armor, a light spear, wind motifs.
- Read: winged humanoid, light, hovering.
- Animation Notes: idle = hover with slow wing flaps; move_fly = gliding swoop; attack = spear thrust / wing buffet (push); attack_heavy (Gold) = dive-strike; ko = wings fold, spirals down.
- Sound: wing beats, light battle-cry.

**Animation block (Tier 1):** idle (hover) ✓ · **move_fly** ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓. Flight = humanoid "floating/hover" clip (Mixamo).

**Validator:** PASS — Wheel = 100%, Miss 25% ≤30, low Blue (agile), 2 passives, 1 trait. Humanoid.

---

# 5. Venom Witch  *(was Venom Spider — re-skinned humanoid, same gameplay)*

**Data**
- Class: Debuffer · Rarity: Epic · Stamina: 2
- Attack Type: Wheel · Movement Traits: —
- Resistances: Resist Fear (−1 turn) · Evolution: 2 stages (Venom Witch → Plague Matron)

**Attack Pool — Stage 1 (Wheel — total 100%)**

| Segment | Prob |
| ------- | ---- |
| Purple ★ (Fear) | 25% |
| Purple ★★ (Weakened) | 15% |
| Blue | 15% |
| White 40 | 20% |
| Red (Miss) | 25% |

**Passives (2/3)**
1. *Venom Hex* — Purple wins also apply **Weakened** (1 turn) in addition to their listed effect.
2. *Hexstep* — On Defend: a tie lets the Witch retreat 1 node after combat.

**Hidden Passive (Stage 2, earned Rank Up only):** *Venom Aura* (Aura) — adjacent enemies have **−1 Stamina** on their next turn.

**Evolution — Stage 2 (Plague Matron):** Rank Up changes (1–3 attrs): Purple ★★ Weakened segment grows to 25%, unlocks *Venom Aura*. Stamina stays 2.

**Lore:** A plague-witch weaving fear and rot; the longer you linger, the weaker you get.

**Meshy prompt**
- Visual Theme: **chibi/mini humanoid witch**, tattered hooded robes, toxic-green magic + potion vials, crooked staff. Plague Matron = grander robes, plague-doctor mask, more ominous — still cute-menacing, not scary.
- Read: hooded caster, green glow, clearly a debuffer.
- Animation Notes: idle = stirring magic, robe sway; move = glide-walk; attack = venom bolt cast; attack_heavy (Purple★★) = hex burst; rankup = robe + mask transformation (dramatic); ko = crumples, smoke.
- Sound: bubbling, whispered incantations.

**Animation block (Tier 1):** idle ✓ · move_walk ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓ · **rankup** ✓ (Witch→Matron). Humanoid.

**Validator:** PASS — Wheel = 100%, Purple 40% total in range, Miss 25%, 2 passives + 1 hidden (earned only), evolution 2 ≤4. Humanoid.

---

# 6. Emberborn  *(was Ember Dragon — re-skinned humanoid line, same gameplay · showpiece Rank Up)*

**Data**
- Class: Striker · Rarity: Legendary · Stamina: 3 → 2 → 2
- Attack Type: Dice (D6, improves per stage) · Movement Traits: — (light/fast at stage 1)
- Resistances: Immune Burn (self) · Evolution: 3 stages (Ember Squire → Flame Champion → Infernal Warlord)

**Stage 1 — Ember Squire (Dice D6, Stamina 3, mobile/low damage)**

| Face | Outcome |
| ---- | ------- |
| 1 | White 40 |
| 2 | White 60 |
| 3 | Red (Miss) |
| 4 | Purple ★ |
| 5 | Gold 30 |
| 6 | White 80 |

**Stage 2 — Flame Champion (Dice D6, Stamina 2)**

| Face | Outcome |
| ---- | ------- |
| 1 | White 60 |
| 2 | White 80 |
| 3 | Purple ★ |
| 4 | Gold 40 |
| 5 | White 100 |
| 6 | White 90 |

**Stage 3 — Infernal Warlord (Dice D6, Stamina 2) — unlocks Hidden Passive**

| Face | Outcome |
| ---- | ------- |
| 1 | White 80 |
| 2 | Gold 50 |
| 3 | Purple ★★ (Weakened) |
| 4 | White 100 |
| 5 | Gold 60 |
| 6 | White 120 |

**Passives (1/3 base)**
1. *Kindling Resolve* — On Rank Up: cleanse all debuffs (in addition to the standard Rank Up cleanse) and gain +1 Stamina until end of next turn.

**Hidden Passive (Warlord, earned Rank Up only):** *Burning Aura* (Aura) — at the start of their turn, adjacent enemies become **Weakened** (1 turn).

**Lore:** A fire-sworn warrior — from eager squire to infernal warlord, each kill stokes the flame.

**Meshy prompt**
- Visual Theme: **chibi/mini humanoid fire warrior**, 3 stages. Squire = young, light armor, small flames, big cute eyes. Champion = full flame-plate + greatsword, fiery aura. Warlord = massive infernal armor, horned helm, lava-cracked, smoke — bigger & fiercer but still chibi and cute-menacing, never scary.
- Read: clearly escalates in size/armor/flame per stage.
- Animation Notes: idle = breathing with ember flickers; move = stride; attack = sword slash; attack_heavy (Gold) = flaming overhead slam; **rankup = the hero moment** (glow → rise → armor/flame upgrade → new form revealed, 2–3s, skippable); ko = collapses, embers fade.
- Sound: crackling fire, escalating battle roars per stage.

**Animation block (Tier 1, per stage):** idle ✓ · move_walk ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓ · **rankup** ✓ (×2 transitions, visibly different per stage). Humanoid → Mixamo.

**Validator:** PASS — all D6 valid, stars ≤★★, evolution 3 ≤4, 1 base passive + 1 hidden (earned only). Humanoid.

---

# 7. Rift Mage  *(was Arcane Wisp — re-skinned humanoid, same gameplay)*

**Data**
- Class: Controller · Rarity: Epic · Stamina: 2
- Attack Type: Dice Sum (2d6) · Movement Traits: Phase (blink)
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
1. *Blink* — On Move: may Phase (blink) through 1 enemy at no extra stamina.
2. *Arcane Pull* — All Push/Pull/Swap distances from this figure +1 at sum ≥ 10.

**Hidden Passive:** none.

**Lore:** A robed sorcerer who blinks across the board and rearranges the fight at will.

**Meshy prompt**
- Visual Theme: **chibi/mini humanoid sorcerer**, big hood, glowing eyes, arcane runes + a floating tome, blue-violet robes.
- Read: robed caster, arcane glow, hovering runes.
- Animation Notes: idle = gentle float, runes rotate; move = glide-walk; phase = blink/teleport (dissolve → reform through obstacles); attack = arcane bolt / telekinetic shove (push/pull/swap); attack_heavy (Gold/Purple) = reality-warp swap; ko = winks out.
- Sound: arcane hums, chimes, blink whoosh.

**Animation block (Tier 1):** idle ✓ · move_walk (float) ✓ · **phase** (blink) ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓. Humanoid.

**Production:** ✅ **DONE** — `rift_mage/rift_mage.glb` (textured, 24-joint rig, 8 clips: Idle_6/Walking/Running/mage_spell_cast_1/mage_spell_cast_4/Stand_Dodge/Hit_Reaction/dying_backwards). Phase/blink handled in Godot via VFX + teleport.

**Validator:** PASS — 2d6 valid (higher = generally stronger), stars ≤★★★, 2 passives, 1 trait. Note Swap-into-Goal triggers Surround-KO check before Victory (Part 2A §17). Humanoid.

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
- Visual Theme: **chibi/mini humanoid** trickster/jester, gold coins motif, purple+gold, mischievous (big head, big grin, small body) — cute and playful.
- Read: flashy, theatrical, mid-size.
- Animation Notes: idle = tossing a coin, sly grin; move = jaunty stride; attack = coin-flick / cane strike; attack_heavy (Gold/Purple) = cascade of coins; ko = pratfall, coins scatter.
- Sound: coin jingles, chuckles, whooshes.

**Animation block (Tier 1):** idle ✓ · move_walk ✓ · deploy ✓ · attack ✓ · attack_heavy ✓ · defend ✓ · hit ✓ · ko ✓. Humanoid.

---

# Notes for Meshy production

- **All figures are humanoid/bipedal** → a shared rig/animation approach; humanoid clips can be
  filled from **Mixamo** for free. The Golem proved the pipeline (single textured GLB + 8 clips).
- **Priority order** (sells the prototype fastest): **Emberborn** (Rank Up showpiece) →
  **Stone Golem ✅** & **Ironclad Knight** → **Nightblade** & **Storm Valkyrie** → **Venom Witch**
  (status + 2nd stage) → **Rift Mage** & **Coin Trickster**.
- **One merged GLB per figure** (model + textures + all Tier 1 clips). Evolving figures
  (Emberborn ×3 stages, Venom Witch ×2) need one GLB per stage + a `rankup` transition.
- **Medium poly + LODs** — figures appear on the board (medium distance) and in the combat close-up.

# Asset folder slugs

`ironclad_knight` · `stone_golem` ✅ · `nightblade` · `storm_valkyrie` ·
`venom_witch/{witch,matron}` · `emberborn/{squire,champion,warlord}` · `rift_mage` · `coin_trickster`

# Status & Next

Status: **DRAFT** — awaiting human approval. Once approved:
1. Hand each figure's **Meshy prompt + animation block** to Meshy (humanoid + chibi).
2. These sheets define the **data schema** for the Godot project (Part B): they become `.tres`/JSON
   resources (Figure → stats, attack pool, passives, evolution, animation map).

END OF STARTER ROSTER
