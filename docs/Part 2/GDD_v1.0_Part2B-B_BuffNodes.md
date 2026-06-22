# GDD_v1.0_Part2B-B_BuffNodes.md

# Part 2B - Buff Nodes Framework

Version: 1.0

Status: LOCKED

---

# 1. Buff Node Philosophy

Buff Nodes are strategic objectives placed throughout the battlefield.

Buff Nodes encourage movement.

Buff Nodes encourage combat.

Buff Nodes encourage area control.

Buff Nodes are intended to make the center and branching paths desirable.

Buff Nodes should not replace combat.

Buff Nodes should supplement combat.

---

# 2. Buff Node Structure

Each Buff Node contains:

Name

Category

Description

Owner

Activation Requirement

Charge Time

Duration

Cooldown

Uses

Target

Effect

Visual State

Sound Effect

Animation

Flavor Text

---

# 3. Node Categories

## Offensive

Examples:

+20 White Damage

+15 Gold Damage

+1 Purple Star

Miss Reduction

---

## Defensive

Examples:

Fear Immunity

Blue Increase

Debuff Resistance

Status Cleanse

---

## Utility

Examples:

Gain Energy

Movement +1

Jump

Phase

---

## Control

Examples:

Fear Aura

Push Distance

Swap Protection

Enemy Stamina Reduction

---

## Consumable

One-time effects.

Examples:

Recover Energy

Instant Buff

Temporary Shield

---

## Negative Nodes

Examples:

Stamina -1

Miss +10%

White Damage -20

Fear Duration +1

---

## Global Nodes

Affect every Figure.

Limited to:

Maximum 1 per map.

Should have long cooldowns.

Examples:

All Figures

+10 White

All Figures

Recover 1 Energy

---

# 4. Ownership

Nodes may change ownership.

Ownership belongs to:

Current Activator.

---

If enemy captures:

Ownership changes.

Cooldown remains.

---

Node ownership is dynamic.

---

# 5. Activation Requirements

Each Node defines its activation condition.

Examples:

Stay 1 Turn

Stay 2 Turns

Stay 3 Turns

Immediate

Combat KO

Energy Cost

Special Requirement

---

# 6. Partial Activation

Progress is NOT retained.

Example:

Requirement:

2 Turns

Stay:

1 Turn

Leave Node

Progress resets.

Back to:

0

---

# 7. Activation Effects

Upon successful activation.

Node grants:

Buff

Debuff

Energy

Status

Passive

Temporary Trait

Global Effect

Designer configurable.

---

# 8. Activation Strength

Half Activation

Obtained immediately.

Example:

+20 White

↓

+10 White

---

Full Activation

Requires complete charge.

+20 White

---

Designer configurable.

Not mandatory.

---

# 9. Buff Duration

Buffs remain active:

While Occupying Node

Fixed Turns

Until KO

Until Rank Up

Match Long

Designer configurable.

---

Leaving Node removes effects.

Unless otherwise specified.

---

# 10. Cooldowns

Nodes may enter cooldown.

Cooldown examples:

0 Turns

1 Turn

3 Turns

5 Turns

Match Long

Infinite

---

During cooldown:

Inactive

Cannot activate.

---

# 11. Uses

Nodes may possess:

Infinite Uses

Limited Uses

Single Use

---

Examples

Ancient Weapon

Uses

1

Cooldown

Infinite

---

Meditation Shrine

Infinite

Cooldown

2

---

# 12. Neutral Nodes

Default ownership.

None.

---

Available to:

Everyone.

---

Most maps should use Neutral Nodes.

---

# 13. Shared Nodes

May benefit multiple players.

Examples:

Global Node

Shared Healing

Shared Energy

---

Use sparingly.

---

# 14. Locked Nodes

Unavailable.

Until conditions met.

Examples:

KO Enemy

Turn 5

Capture Objective

Modifier Activation

Designer configurable.

---

# 15. Negative Nodes

Risk vs Reward.

Examples:

Volcano

White +30

Miss +10

---

Swamp

Stamina -1

---

Dark Crystal

Purple +1

Fear Duration +1

---

# 16. Energy Nodes

Generate Energy.

Examples:

Meditation Shrine

Stay

1 Turn

Gain

1 Energy

Cooldown

2

---

Maximum Energy

Still

10

---

# 17. Global Nodes

Rare.

Maximum

1 per map.

---

Examples

War Banner

Stay

2 Turns

Everyone

+10 White

Cooldown

5

---

Global Nodes should be visually distinct.

---

# 18. Terrain Integration

Nodes should preferably appear:

Near intersections.

Near contested areas.

Near alternative routes.

---

Recommended:

Paths with 3 connections.

---

Avoid:

Dead Ends

Spawn Zones

Goal Zones

---

# 19. Node Templates

Template

Name:

Category:

Activation:

Cooldown:

Uses:

Target:

Duration:

Owner:

Effect:

Visual:

Animation:

Sound:

Flavor Text:

---

Example

Name:

Ancient Shrine

Category:

Utility

Activation:

Stay 1 Turn

Cooldown:

2

Uses:

Infinite

Target:

Self

Duration:

Occupying

Effect:

+1 Energy

Visual:

Floating Runes

Animation:

Light Pulse

Sound:

Bell

Flavor:

Knowledge rewards patience.

---

# 20. AI Node Validator

AI Generated Nodes cannot violate:

Infinite Energy

Infinite Revival

Permanent Fear

Infinite Globals

Negative Cooldowns

Unlimited Strong Globals

---

Warnings

Too many Globals

Too many Consumables

Cooldown too low

Activation too easy

---

AI must regenerate.

Until valid.

---

# 21. AI Node Generation Standards

Recommended:

Maps contain:

2-4 Nodes

---

Global Nodes:

Maximum 1

---

Consumables:

Maximum 2

---

Negative Nodes:

Maximum 2

---

Charge Nodes:

Recommended

1-2

---

# 22. Node Prompt Standard

Template

Name:

Category:

Theme:

Activation:

Cooldown:

Uses:

Effect:

Duration:

Target:

Visual Theme:

Animation:

Sound:

Flavor Text:

---

# 23. Node Approval Checklist

☐ Activation balanced

☐ Cooldown balanced

☐ Uses valid

☐ Effect understandable

☐ Positioning encourages combat

☐ Validator passed

☐ Not stronger than Modifiers

☐ Map synergy exists

---

Status:

LOCKED

END OF PART 2B-B

Next Document:

GDD_v1.0_Part2B-C_DeckBuilder.md
