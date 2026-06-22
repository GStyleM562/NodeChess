# GDD_v1.0_Part1C_CoreRules.md

# Part 1C - Resources, Board Systems and Priority Rules

---

# 21. Energy System

## Overview

Energy represents the tactical resource used by players to activate Modifiers.

Energy belongs to the player.

Energy does not belong to individual Figures.

Energy persists throughout the match.

Energy is public information.

---

## Initial Energy

At the beginning of a match:

Energy = 0

---

## Energy Gain

At the beginning of each player's turn:

Energy +1

---

## Maximum Energy

Maximum Energy:

10

Energy above 10 is discarded.

---

## Energy Loss

Energy cannot be lost by:

KO

Rank Up

Status Effects

Movement

Combat

Energy is only spent when activating Modifiers.

---

## Future Expansion

Characters may:

Generate Energy

Store Energy

Reduce Modifier Costs

Increase Energy Cap

---

# 22. Modifier System

Modifiers are tactical cards equipped before a match.

Modifiers belong to the player.

Not to Figures.

---

## Equipped Modifiers

Each player may equip:

3 Modifiers

Maximum.

No duplicates by default.

Balance may override.

---

## Modifier Visibility

Modifiers remain hidden.

Only owner sees them.

Modifiers become public after first use.

Remain visible for remainder of match.

---

## Modifier Costs

Each Modifier has:

Energy Cost

Cooldown

Usage Limit

Effect

Target Rules

Activation Conditions

---

## Usage Types

### Unlimited

Can be reused.

Requires Energy.

Requires Cooldown.

---

### Limited Uses

Can only activate X times.

Example:

Uses:

3

---

### One-Time

Only usable once.

After activation:

Inactive.

---

## Activation Timing

Modifiers activate before combat.

Sequence:

Declare Combat

↓

Apply Modifier

↓

Combat

Modifiers cannot interrupt combat.

Modifiers cannot be played during attack animation.

---

# 23. Buff Nodes

Buff Nodes are special Nodes.

Grant temporary advantages.

Control over Buff Nodes is intended to create positioning decisions.

---

# Buff Node Components

Every Buff Node contains:

Name

Category

Charge Requirement

Cooldown

Owner

Effect

Visual State

---

## Charge Requirement

Buff Nodes may require time.

Examples:

Immediate

1 Turn

2 Turns

3 Turns

---

## Charge Rules

Entering Node

Starts Charge.

Leaving Node

Charge resets.

---

Example

Node requires:

2 turns

Player remains:

1 turn

Leaves

Progress returns to:

0

---

## Activation

After Charge Requirement met.

Node activates.

Owner receives Buff.

---

## Cooldown

After use.

Node enters cooldown.

Unavailable.

Cooldown duration configurable.

---

# Buff Node Categories

---

## Offensive

Increase Damage.

Increase Stars.

Reduce Miss.

Increase Gold.

---

Examples

+20 White Damage

+1 Purple Star

-10% Miss

---

## Defensive

Increase Blue chance.

Status Immunity.

Temporary Shield.

---

Examples

+15% Blue

Paralysis Immunity

---

## Utility

Movement bonuses.

Teleportation.

Jump improvements.

---

Examples

+1 Stamina

Ignore Enemy Blocks

---

## Economy

Energy related.

---

Examples

+2 Energy

Modifier Cost Reduction

---

## Objective

Map control.

Rank Up.

Goal Protection.

Temporary Entrances.

---

Examples

Instant Rank

Goal Shield

---

# 24. Entrance System

Entrances allow deployment.

Entrances belong to players.

Entrances may vary by map.

---

## Entrance Count

Maps may contain:

2 Entrances

3 Entrances

More in future.

---

## Occupied Entrances

Only one Figure per Node.

If occupied.

No deployment possible.

Regardless of ownership.

---

Example

Friendly Figure on Entrance

Cannot deploy.

Enemy Figure on Entrance

Cannot deploy.

---

## Shared Entrances

Some maps connect Entrances.

Occupying one.

May block another.

Map specific.

---

# 25. Goal System

Each player owns:

Friendly Goal

Enemy Goal

---

## Victory

Entering Enemy Goal.

Immediate Victory.

---

## Goal Defense

Friendly Goal may be occupied.

Protects against infiltration.

---

## Capacity

Maximum:

1 Figure.

No stacking.

---

# 26. Terrain Types

Maps may include:

---

Normal

No effects.

---

Buff Node

Special Effects.

---

Obstacle

Cannot pass.

---

Teleport

Instant Movement.

---

Hazard

Applies Debuffs.

---

Slow Terrain

Movement Penalty.

---

Rank Zone

Rank Bonuses.

---

Future Terrain allowed.

---

# 27. Board Design Philosophy

Maps should prioritize:

Decision Making

Counterplay

Movement

Control

Risk

---

# Symmetry

Maps should be:

Symmetrical

Semi-Symmetrical

Fairly Balanced

---

No player should have:

Shorter paths.

Safer Goals.

Superior Entrances.

---

# Control Areas

Maps should encourage conflict.

Recommended:

3-Way Junctions

Buff Nodes

Central Objectives

---

# Recommended Layout

Corners:

Entrances

Center:

Conflict

Back:

Goals

---

# 28. Resolution Priority Table

The game resolves effects in the following order.

Priority 1

Passive Abilities

↓

Priority 2

Modifiers

↓

Priority 3

Buff Nodes

↓

Priority 4

Debuffs

↓

Priority 5

Attack Roll

↓

Priority 6

Status Effects

↓

Priority 7

KO

↓

Priority 8

Rank Up

↓

Priority 9

Victory Check

---

# 29. Future Compatibility

All future content must respect:

Core Rules

Priority Table

Energy Rules

Combat Rules

Movement Rules

Map Standards

Visibility Rules

Buff Rules

Status Rules

---

END OF PART 1C

Core Rules v1.0 Status:

LOCKED

Future documents:

GDD_v1.0_Part2_ContentFramework.md

Contents:

Character Templates

Attack Templates

Modifier Templates

Status Templates

Buff Node Templates

Map Templates

Deck Builder Templates

Content Generation Standards
