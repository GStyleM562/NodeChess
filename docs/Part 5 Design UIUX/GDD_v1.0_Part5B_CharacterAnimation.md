# GDD_v1.0_Part5B_CharacterAnimation.md

# Part 5B - Character Animation & Liveliness

Version: 1.0

Status: DRAFT (extends Part 5 §13 Animation Philosophy, §29 Figure Presentation, §31 Motion Design)

---

# 1. Philosophy

Figures are **living characters**, not static board pieces.

The goal is **emotional attachment** (Part 5 §29): the player should feel their figures are
alive, reacting to the board, breathing, fighting, struggling, and celebrating.

A figure that simply slides between nodes feels like a token.
A figure that **breathes while waiting, lunges when attacking, braces when defending, and
panics when cornered** feels like a creature worth collecting.

Core rule of thumb:

> **Any motion beats no motion.** A 1.5s breathing idle loop is cheap and is the single highest
> "feeling-alive per resource" investment. If a character can have only one animation, it should
> be **Idle**; if it can have only two, **Idle + Move**; if three, **Idle + Move + Attack**.

This document maps every meaningful **game event in the GDD** to a character animation, marks
each as MVP-critical or polish, and defines the production pipeline (Meshy → Godot).

---

# 2. Animation Principles

- **Readable at two distances.** Figures are seen on the **isometric board** (medium distance)
  AND in the **combat close-up** (Part 5 §17, the Wheel/disk moment). Animations must read in both.
- **Loop vs One-shot.** *Loops* play continuously (idle, fly-hover, status states). *One-shots*
  fire on an event then return to the current loop (attack, hit, jump, rank up).
- **Snappy, not slow** (Part 5 §31): movement ~0.4s, combat ~2s, rank up ~2.5s. Never block the
  player; combat resolution must never exceed **5 seconds** (Part 5 §17.2).
- **Interrupt priority.** Higher-priority states override lower ones:
  `KO > RankUp > Attack/Hit > Displacement > Status > Buff > Move > Idle`.
- **Skippable.** Long one-shots (Rank Up, Victory) must support a skip (Part 5 §17.4, §18).
- **State, not stat.** Animations communicate game state the player already needs to read
  (Part 5 §33): whose turn, can it attack, is it feared, is it buffed — without opening menus.

---

# 3. Master Animation State List

Mapped to the actual GDD mechanics. **Tier** = recommended production priority (see §5).

## 3.1 Locomotion

| Clip | GDD trigger | Type | Tier | Notes |
| ---- | ----------- | ---- | ---- | ----- |
| `move_walk` | Move action across nodes (Part 1 §6) | Loop while traversing | **0** | Per-node hop or continuous glide along the path. |
| `move_run` | Optional for Agile / high-stamina figures | Loop | 2 | Faster variant; sells the Agile class fantasy. |
| `move_fly` / `hover` | Hover trait / flying units (Part 2A §16) | Loop | 1 | Flying figures should **never** appear grounded. |
| `jump` | Jump over a blocking enemy (Part 1 §7) | One-shot | 1 | Arc over the blocker; ends adjacent, may chain into attack. |
| `phase` | Phase trait — pass through occupied nodes (Part 2A §16) | One-shot/overlay | 2 | Ghostly translucency + pass-through; still Surround-KO vulnerable. |
| `deploy` | Deploy action — enter via Entrance (Part 1 §8) | One-shot | 1 | Spawn-in cue (materialize / drop / portal). Reused on KO-bench return. |

## 3.2 Combat

| Clip | GDD trigger | Type | Tier | Notes |
| ---- | ----------- | ---- | ---- | ----- |
| `attack` | Attack action / combat declared (Part 1 §5, §11) | One-shot | **0** | Windup → strike, synced to the Wheel/Dice/Coin resolution. |
| `attack_heavy` | Gold / Purple (special) outcomes (Part 1 §14) | One-shot | 2 | Bigger, color-tinted strike for special attacks; sells the hit. |
| `defend` | On-Defend trigger; **Blue** defensive win (Part 1 §14.4, Part 2A §13) | One-shot | 1 | Guard / parry. Blue should feel like a satisfying block. |
| `hit` / `brace` | Combat **tie** or survived exchange — "both remain" (Part 1 §14) | One-shot | 1 | Flinch but stays on the board. Distinguishes survival from KO. |
| `ko` | Lose combat → KO Bench (Part 1 §16) | One-shot | **0** | The defeat moment (Part 5 §13: "explosion"). Then figure leaves board. |

## 3.3 KO by Positioning (Surround KO)

| Clip | GDD trigger | Type | Tier | Notes |
| ---- | ----------- | ---- | ---- | ----- |
| `surround_panic` | Target fully enclosed by **enemies**, no escape node (Part 1 §16.1) | One-shot → `ko` | 2 | Cornered → panic → KO. The emotional payoff of a positioning kill. |
| `threatened` | Adjacent enemies threatening (not yet surrounded) | Subtle loop/overlay | 3 | Alert/guard micro-pose. Nice-to-have tension cue. |
| `surround_menace` | The **surrounding** enemies closing in | Short emote | 3 | Optional: attackers lean in / taunt. Friendlies never trigger Surround KO. |

## 3.4 Progression

| Clip | GDD trigger | Type | Tier | Notes |
| ---- | ----------- | ---- | ---- | ----- |
| `rankup` | Rank Up after KOing an enemy (Part 1 §18, Part 5 §17.4) | One-shot | 1 | Glow → aura → rise → evolution → new attacks shown. 2–3s, skippable. One of the most important moments. |
| `victory` | Match win (Part 5 §18) | One-shot/loop | 2 | Celebration pose; reused as Home centerpiece "winner" idle. |
| `defeat` | Match loss (Part 5 §19) | One-shot | 3 | Slump — but keep messaging positive, not punishing. |

## 3.5 Status & Buff

Status effects (Part 1 §15) should each have a recognizable body language **plus** a VFX overlay.

| Clip | GDD status | Type | Tier | Notes |
| ---- | ---------- | ---- | ---- | ----- |
| `status_paralyzed` | Paralysis — cannot be controlled (Part 1 §15) | Loop | 2 | Stunned / twitching, frozen in place. |
| `status_immobilized` | Immobilized — can't move, can attack/defend | Loop | 2 | Rooted / struggling against restraints. |
| `status_fear` | Fear — can't attack, can move/defend | Loop | 2 | Cowering / trembling. |
| `status_weakened` | Weakened — −damage / −stars | Loop | 2 | Slumped, dimmed, heavy posture. |
| *(future)* | Burn / Poison / Freeze / Sleep / Curse… (Part 1 §15, Part 2A §29) | VFX overlay | 3 | Overlay particles on base idle; dedicated clips later. |
| `idle_buff` / aura overlay | On a Buff Node, charging/active (Part 1 §23, Part 5 §17.5) | Loop/overlay | 2 | **Per your note:** figure may simply keep `idle` with a glowing aura overlay (charging=orange, active=blue) — no bespoke clip required. |

## 3.6 Displacement reactions

| Clip | GDD trigger | Type | Tier | Notes |
| ---- | ----------- | ---- | ---- | ----- |
| `pushed` / `pulled` | Push / Pull displacement (Part 2A §17) | One-shot | 2 | Stagger / slide. Heavy trait = resists (no/!reduced reaction). |
| `swap` | Swap positions (Part 2A §17) | One-shot | 3 | Quick blink-swap; Anchor trait cannot be swapped. |
| `teleport` | Teleport displacement (Part 2A §17) | One-shot | 3 | Vanish → appear. |

## 3.7 Ambient / Meta

| Clip | Context | Type | Tier | Notes |
| ---- | ------- | ---- | ---- | ----- |
| `idle` | Default board state | Loop | **1** | Breathing, blink, weight shift. THE liveliness clip. |
| `idle_home` | Home screen centerpiece (Part 5 §29) | Rich loop | 2 | Larger, more expressive idle + particles for the showcase. |
| `select` | Player taps the figure to act | One-shot/overlay | 3 | Alert pose / small bounce — UX feedback that it's selected. |

---

# 4. Requested Scenarios — Detailed

## 4.1 Idle ("alive")

The default loop. Keep it **subtle**: breathing, occasional blink, small weight shift, maybe a
rare 1-off flourish every ~10s. On the **Home centerpiece** it can be richer (Part 5 §29).
This is the cheapest, highest-impact animation — strongly recommended even in MVP.

## 4.2 Movement, Jump, Fly, Phase

- **Walk/Glide** along the node path; stop early if partial movement (Part 1 §6).
- **Jump** arcs over a blocking enemy and can chain into `attack` (Part 1 §7).
- **Fly/Hover** for Hover-trait/flying figures — they should idle-hover, never plant on the ground.
- **Phase** = translucency + pass-through; reminder: phasing does **not** grant Surround-KO immunity.

## 4.3 Attacking

Windup → strike, **time-synced to the attack resolution UI** (Wheel spin / Dice roll / Coin flip).
The Wheel is the **hero** presentation (Pokémon-Duel-style disk) — invest there first.
Special colors get `attack_heavy` (Gold/Purple) with color-tinted VFX. Whole sequence ≤ 5s.

## 4.4 Receiving an attack / Defending

Combat is **binary** (Part 1 §11) — there's no HP — so "receiving" resolves three ways:

- **Lose** → `ko` (leaves the board).
- **Tie / mutual survive** ("both remain", Part 1 §14) → `hit` / `brace` flinch, stays on board.
- **Blue defensive win** (Part 1 §14.4) → `defend` (guard/parry). Blue should feel *great* to land —
  it's the highest-priority color and the defensive payoff.

## 4.5 Surround KO — encircled & encirclers

- **Encircled figure:** `surround_panic` (cornered → panic) → `ko`. This is the emotional reward of
  a positioning kill; make it read clearly even at board distance.
- **Encirclers (the closing-in enemies):** optional `surround_menace` lean-in/taunt (Tier 3).
- Rule reminder: only **enemies** cause Surround KO; friendly figures never do (Part 1 §16.1).

## 4.6 Being "boxed in" but not yet KO'd

When enemies are adjacent and threatening (but an escape node still exists), an optional subtle
`threatened` alert pose adds tension without implying a KO. Pure polish (Tier 3).

## 4.7 Buffed / on a Buff Node

Per your suggestion: the figure can **stay in `idle`** with a **glowing aura overlay** rather than a
bespoke "buffed" clip. Tie the aura color to the node state (charging = orange, active = blue,
cooldown = red — Part 5 §17.5). A dedicated `idle_buff` (e.g. crackling energy, raised stance) is a
nice Tier-2 upgrade but not required.

## 4.8 Status effects

Each MVP status gets a body-language loop so the player reads it without opening menus (Part 5 §33):
Paralyzed = stunned, Immobilized = rooted/struggling, Fear = cowering, Weakened = slumped.
Future statuses (Burn/Poison/Freeze…) can start as **VFX overlays** on the base idle.

## 4.9 Rank Up / Evolution

The signature moment (Part 5 §17.4): glow → aura → character rises → evolution → new attacks shown →
board returns. 2–3s, **skippable**. If a figure has multiple evolution stages (Part 2A §18), the
transform should visibly differ per stage.

## 4.10 Victory / Defeat

Victory = celebratory pose (reusable as the Home "winner" idle). Defeat = subtle slump, but the
Defeat screen stays encouraging (Part 5 §19).

---

# 5. Resource Tiers

Pick a tier per figure (or per rarity/importance). Higher tiers include all lower ones.

| Tier | Clips | Goal |
| ---- | ----- | ---- |
| **Tier 0 — Minimum playable** | `move_walk`, `attack`, `ko` (+ a **static** idle pose) | Board is readable; nothing looks broken. **This is your "if it's too much resource" floor** — and per your note, if there's no idle loop, figures must at least animate when they **move/fly**. |
| **Tier 1 — MVP "feels alive"** *(recommended target)* | + `idle` (breathing loop), `move_fly`, `jump`, `deploy`, `defend`, `hit`, `rankup` | The game feels premium and alive enough to answer "is it fun?". |
| **Tier 2 — Polish** | + `attack_heavy`, status loops (fear/paralyzed/immobilized/weakened), `idle_buff`/aura, `surround_panic`, `pushed`/`pulled`, `move_run`, `victory`, `idle_home` | Full readability and game-feel. |
| **Tier 3 — Premium / per-skin** | + `surround_menace`, `threatened`, `swap`, `teleport`, `defeat`, `select`, skin-specific flair | Showpiece characters and cosmetics. |

**Recommendation:** target **Tier 1** for the prototype roster. A minimal `idle` breathing loop is
cheap and is what actually makes figures feel "alive" — I'd keep it even when trimming. Only drop to
Tier 0 (static idle pose + engine-side micro-bob/scale in Godot) if a specific character's animation
budget is truly exhausted, and in that case keep `move`/`fly` animated as you said.

---

# 6. Per-Class Movement Flavor (optional)

Animation style can reinforce the class fantasy (Part 2A §3) without changing rules:

| Class | Feel |
| ----- | ---- |
| Tank | Heavy, slow, grounded, deliberate. Shrugs off `pushed`. |
| Agile | Light, quick, bouncy; uses `move_run`. |
| Striker | Aggressive lunges; pronounced `attack_heavy`. |
| Debuffer | Creepy, skittering, unsettling idle. |
| Controller | Floaty / arcane; gestures for swap/push. |
| Buffer | Supportive, open posture; aura-friendly. |
| Specialist | Unique — no rules. |

---

# 7. Production Pipeline (Meshy → Godot)

1. **Model:** Meshy generates the mesh + PBR textures → export **GLB**. Medium poly (figures show in
   both board and combat close-up; use LODs if needed).
2. **Rig & animate:**
   - **Creatures / non-humanoid:** Meshy animation, or hand-keyed clips.
   - **Humanoid:** Mixamo's library covers idle/walk/run/jump/hit/ko cheaply; retarget in Godot.
3. **Export:** one GLB can hold **multiple animation clips** (glTF). Godot imports each as an
   `Animation` into an `AnimationLibrary`.
4. **Godot setup:**
   - Per figure: `AnimationPlayer` + an **`AnimationTree`** state machine driven by gameplay events
     emitted from the **rules engine** (kept separate from rendering).
   - **Share** an `AnimationLibrary` across figures with matching skeletons (Godot 4 animation
     retargeting) to save memory/work.
   - Keep bone counts modest for 60 FPS on mobile (Part 5 §15).
5. **Clip naming convention** (so the engine maps generically):
   `idle, idle_buff, idle_home, move_walk, move_run, move_fly, jump, phase, deploy, attack,
   attack_heavy, defend, hit, ko, surround_panic, rankup, victory, defeat, status_fear,
   status_paralyzed, status_immobilized, status_weakened, pushed, pulled, swap, teleport, select`.

---

# 8. Per-Figure Animation Checklist (attach to each Character Sheet)

For every figure, record:

```
Figure: <name>
Tier target: <0 | 1 | 2 | 3>
Idle: <yes loop | static pose | none>
Move: <walk | run | fly/hover>
Attack: <base | + heavy for Gold/Purple>
Defend / Hit: <yes | no>
KO: <yes>
Rank Up: <per stage? yes/no>
Status idles: <which>
Buff: <idle + aura | idle_buff>
Special (jump/phase/displacement): <list>
Skin-specific flair: <list | none>
Meshy/Mixamo source notes: <...>
```

---

# 9. Status & Next

Status: **DRAFT** — ready to feed Meshy production and the Godot `AnimationTree` setup.

Open questions for human decision:
- Default tier for the **starter roster** (recommend Tier 1).
- Whether `attack` is generic or split per attack color from the start.
- How elaborate the `idle_home` centerpiece should be.

END OF PART 5B
