# GDD_v1.0_Part2A_CharacterFramework_C2.md

# Part 2A - Character Framework (Section C2)

---

# 30. Evolution Templates

## Overview

Evolution represents temporary progression acquired during a match.

Evolutions are optional.

A Figure may possess between 1 and 4 stages.

Evolution persists only during the current match.

Figures revert to their Base Stage at the start of a new match.

---

## Evolution Structure

Stage 1

↓

Stage 2

↓

Stage 3

↓

Stage 4

Recommended:

3 Stages

Maximum:

4 Stages

Minimum:

1 Stage

---

## Evolution Requirements

Evolution is obtained through Rank Up.

Rank Up requires:

KO an enemy Figure through combat.

---

## Evolution Restrictions

Figures cannot evolve inside KO Bench.

Figures retain evolution stage while in KO Bench.

Evolution stage resets after match completion.

---

## Evolution Components

Each Evolution Stage may modify:

Attack Pool

Attack Type

Stamina

Passives

Hidden Passives

Resistances

Movement Traits

Probabilities

Miss Rate

Blue Rate

Purple Effects

Status Effects

Displacement Effects

Visual Effects

Animation Effects

Sound Effects

---

## Evolution Philosophy

Evolutions should not always increase power.

Evolutions may improve strengths.

Evolutions may introduce weaknesses.

Examples:

Baby Dragon

High Mobility

Low Damage

↓

Young Dragon

Balanced

↓

Adult Dragon

High Damage

Lower Mobility

↓

Ancient Dragon

Extreme Damage

Minimal Mobility

---

Each Evolution Stage is encouraged to modify only a small number of properties.

Recommended:

1-3 changes per Rank Up.

---

# 31. Rank Up Templates

## Rank Up Bonuses

Rank Up may grant:

Damage Increase

Probability Redistribution

Miss Reduction

Blue Increase

Gold Increase

Purple Improvement

Passive Unlock

Resistance Unlock

Movement Trait Unlock

Attack Type Change

Status Cleansing

Hidden Passive Unlock

---

## Rank Up Cleansing

Rank Up immediately removes:

Paralyzed

Immobilized

Fear

Weakened

Burn

Poison

Freeze

Confusion

Designer expandable.

---

## Hidden Passive Unlock

Hidden Passives only activate if Evolution was earned during the match.

Example:

Stage 3 selected directly

↓

No Hidden Passive

Stage 3 reached through Rank Up

↓

Hidden Passive available

---

# 32. AI Character Validator

## Purpose

Prevent automatically generated Figures from violating game standards.

Human Designers may intentionally ignore validator warnings.

AI Generated Figures may not.

---

## Validation States

VALID

WARNING

INVALID

---

## INVALID Conditions

More than 3 Passives

More than 4 Evolution Stages

Negative Stamina

Impossible Probabilities

Probability Total ≠ 100%

Invalid Attack Type

Stars > ★★★

Movement Traits > Recommended Limit

---

## WARNING Conditions

Tank with High Mobility

Agile with Excessive Blue

Debuffer with Excessive White Damage

Specialist with Multiple Extreme Strengths

Excessive Hidden Passives

Evolution modifies too many attributes

---

## Human Override

Allowed.

Designer decision.

---

## AI Override

Not allowed.

AI must regenerate Figure.

---

# 33. AI Character Generation Standards

## Purpose

Provide automatic generation rules.

Used when creating Figures without human intervention.

---

## Internal Budget

Invisible.

Not shown to players.

Used only by generation systems.

---

## Recommendations

Tank

Low Mobility

High Blue

Moderate Damage

---

Agile

High Mobility

Low Blue

Moderate Damage

---

Debuffer

Purple

Statuses

Control

---

Buffer

Support

Energy

Aura

---

Striker

White

Gold

KO Potential

---

Controller

Movement

Swap

Push

Pull

Goal Denial

---

Specialist

Experimental

No restrictions

Within validator limits.

---

# 34. Starter Roster Philosophy

## Purpose

Initial MVP roster should expose all gameplay styles.

---

Recommended MVP

2 Tanks

2 Agile

2 Debuffers

2 Buffers

2 Controllers

2 Strikers

2 Specialists

---

Recommended Total

12-16 Figures

---

Goals

Learn mechanics

Encourage experimentation

Show Attack Types

Promote Rank Up

Promote Positioning

Promote Modifier usage

---

# 35. Character Prompt Standard

## Purpose

Standardized format for requesting new Figures.

Allows human or AI creation.

---

Template

Name:

Class:

Theme:

Rarity:

Stamina:

Attack Type:

Desired Playstyle:

Evolution:

Hidden Passive:

Status Effects:

Movement Traits:

Special Mechanics:

Visual Theme:

Animation Notes:

Sound Notes:

---

Example

Name:

Scorpion Assassin

Class:

Debuffer

Theme:

Venom

Stamina:

3

Attack Type:

Coin

Evolution:

Yes

Hidden Passive:

Venom Aura

Movement Traits:

Jump

Special Mechanics:

Fear

---

# 36. Character Approval Checklist

Before approval, verify:

☐ Stamina valid

☐ Probabilities valid

☐ Evolution stages valid

☐ Passives ≤ 3

☐ Hidden Passive rules respected

☐ Validator passes

☐ Attack Pool coherent

☐ Class fantasy maintained

☐ Rank Up meaningful

☐ Figure introduces strategic value

---

# 37. Character Framework Status

Status:

LOCKED

Character Framework v1.0 complete.

Future sections:

Part 2B

Modifiers

Buff Nodes

Status Framework

Deck Builder

Content Expansion Systems

---

END OF PART 2A-C2
