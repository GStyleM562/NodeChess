# GDD_v1.0_Part1B_CoreRules.md

# Part 1B - Combat Systems

---

# 11. Combat System

## Overview

Combat occurs whenever a Figure attacks an adjacent enemy Figure.

Combat determines whether a Figure remains on the board, is Knocked Out, applies Status Effects, evolves through Rank Up, or modifies board control.

Combat is instantaneous.

There is no HP system.

A Figure that loses combat is immediately sent to the KO Bench.

---

# 12. Combat Resolution

Combat follows the exact order below.

Step 1

Declare Attack

↓

Step 2

Apply Modifiers

↓

Step 3

Apply Buff Node Effects

↓

Step 4

Apply Passive Abilities

↓

Step 5

Apply Debuffs

↓

Step 6

Execute Attack Roll

↓

Step 7

Determine Winner

↓

Step 8

Apply Status Effects

↓

Step 9

Check KO

↓

Step 10

Check Rank Up

↓

Step 11

Victory Conditions

---

# 13. Attack Types

Each Figure possesses exactly one Attack Type.

Attack Types may change through Rank Up.

There are currently three Attack Types.

---

## 13.1 Wheel

Attack Method:

Probability Wheel

Properties

Custom probabilities

Variable attack count

Easy balance tuning

Highest flexibility

---

Example

Wheel Character

40%

White 80

20%

Purple ★★

15%

Blue

15%

Gold 40

10%

Miss

---

Design Restrictions

Total probability must equal 100%.

Maximum Miss recommended:

25%

Maximum Blue recommended:

35%

---

## 13.2 Dice

Attack Method

Dice Roll

Properties

Consistent probability

Easy to understand

Potential for high variance

---

Example

Face 1

White 60

Face 2

White 90

Face 3

Purple ★

Face 4

Blue

Face 5

Miss

Face 6

Gold 30

---

Design Restrictions

Minimum faces:

4

Maximum faces:

20

Default:

6

---

## 13.3 Coin

Attack Method

Coin Flip

Properties

Very high risk

Very high reward

Simple gameplay

---

Example

50%

Blue

50%

White 100

---

Special Coin

49.5%

Purple★★★

49.5%

Gold40

1%

Miss

---

# 14. Combat Colors

Combat Colors define interactions.

The mechanic remains unchanged.

Visual colors may change in future versions.

Current prototype colors are placeholders.

---

## 14.1 White

Category

Offensive

Properties

Uses Damage

Loses to Purple

Wins against Gold through Damage

Tie

Nothing happens.

Both Figures remain.

---

## 14.2 Purple

Category

Special Attack

Properties

Uses Stars

Stars range

1-3

Greater number wins.

Purple defeats White.

Purple loses against Gold.

Tie

Nothing happens.

---

## 14.3 Gold

Category

Special Offensive

Properties

Uses Damage

Defeats Purple

Can lose against White

Immune to Purple effects

Tie

Nothing happens.

---

## 14.4 Blue

Category

Defensive

Properties

Highest priority

Defeats

White

Purple

Gold

Tie

Nothing happens.

---

## 14.5 Red

Category

Miss

Properties

Automatic loss

Always loses.

No exceptions.

Unless passive abilities specify otherwise.

---

# 15. Status Effects

Status Effects modify Figure behavior.

Effects have duration.

Duration measured in turns.

Effects automatically expire.

Multiple Statuses may coexist.

Future updates may limit stacking.

---

## Paralysis

Figure cannot be controlled.

Duration

Configurable.

---

## Immobilized

Cannot move.

May attack.

May defend.

Duration configurable.

---

## Fear

Cannot attack.

Can move.

Can defend.

---

## Weakened

Reduces Damage.

Reduces Stars.

Examples

-20 damage

-1 star

---

## Future Statuses

Burn

Poison

Freeze

Silence

Confusion

Sleep

Curse

Mark

Shield Break

---

# 16. KO System

No HP exists.

Combat is binary.

Win

Remain Alive

Lose

KO

---

## 16.1 Surround KO

Figures may be eliminated through positioning.

Conditions

No escape nodes

Completely surrounded

Result

Immediate KO

---

Example

Enemy

Enemy

Enemy

Enemy

Target

Enemy

Enemy

Enemy

Enemy

Target is KO'd.

---

Friendly Figures never cause Surround KO.

Only enemies.

---

# 17. KO Bench

Defeated Figures enter KO Bench.

Figures inside cannot act.

Cannot evolve.

Cannot attack.

Cannot receive buffs.

Cannot use abilities.

---

Cooldown

5 turns

---

Cooldown expires

↓

Figure returns to Main Bench

---

Figures retain their current Evolution Stage.

Only during current match.

---

New Match

↓

Reset to Base Form

---

# 18. Rank Up

Rank Up is temporary.

Match-only progression.

---

Requirements

Obtain KO through combat.

Gain one Rank.

---

Rank Up happens immediately.

No waiting period.

---

Rank Up removes Status Effects.

---

Possible Rank Up Changes

Attack Pool

Attack Type

Stamina

Probabilities

Miss Rate

Blue Percentage

Passives

Effects

Status Infliction

Buffs

Debuffs

---

Example

Baby Dragon

↓

Young Dragon

↓

Adult Dragon

---

Adult Dragon achieved during battle

>

Adult Dragon deployed directly

Possible improvements

More Damage

Less Miss

Additional Effects

Extra Stars

Passive Skill

---

# 19. Victory Conditions

Primary Victory

Reach enemy Goal.

Immediate Victory.

---

Secondary Victory

Enemy cannot deploy Figures.

Enemy has no active Figures.

Enemy Entrances blocked.

Immediate Victory.

---

# 20. Combat Visibility

Visible Information

Energy

Statuses

Rank Stage

KO Timers

Buff Nodes

Active Buffs

Debuffs

Figure Positions

---

Hidden Information

Unused Modifiers

Opponent Strategy

Future Evolutions

Modifiers become visible once used.

Remain visible until battle ends.

---

END OF PART 1B

Next Document:

GDD_v1.0_Part1C_CoreRules.md

Contains:

Energy System

Modifiers

Buff Nodes

Goal Mechanics

Entrance Mechanics

Map Standards

Board Design Philosophy

Special Terrain

Rules Priority Table

Technical Definitions
