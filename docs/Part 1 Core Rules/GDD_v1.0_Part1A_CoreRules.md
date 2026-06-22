# GDD_v1.0_Part1A_CoreRules.md

# Game Design Document

## Project Information

| Property            | Value                  |
| ------------------- | ---------------------- |
| Codename            | TBD                    |
| Version             | 1.0                    |
| Document Status     | Rules Locked           |
| Target Platform     | Android                |
| Multiplayer         | Yes                    |
| Genre               | Tactical Board Battler |
| Perspective         | Top Down               |
| Match Duration Goal | 5-15 Minutes           |

---

# 1. Definitions

This section establishes terminology used throughout the entire project.

## Figure

A controllable unit brought by a player into battle.

Each player must bring exactly six figures.

Figures possess:

* Name
* Rank Stages
* Stamina
* Attack Type
* Attack Pool
* Status Resistances
* Passive Abilities
* Movement Traits
* Evolution Data

---

## Attack

Combat action produced by a figure.

An attack contains:

Color

Power

Effect

Stars

Status Application

Special Conditions

---

## Node

Walkable space within a map.

Nodes may contain:

Normal Terrain

Buff Nodes

Entrances

Goals

Obstacles

Teleporters

Special Mechanics

---

## KO

State representing defeat.

KO immediately removes a figure from the board.

No HP system exists.

---

## Stamina

Maximum number of nodes a figure may traverse during movement.

---

## Modifier

Player equipped tactical card.

Can alter battles.

Consumes Energy.

May have cooldowns.

May be one-time use.

---

## Rank Up

Temporary evolution occurring during a match.

Only lasts until the match ends.

---

# 2. Design Philosophy

The game follows four core pillars.

## Decisions

Every mechanic should encourage meaningful choices.

Examples:

Choosing movement path.

Contesting buff nodes.

Saving energy.

Using modifiers.

Protecting goals.

---

## Positioning

Location matters.

Examples:

Blocking entrances.

Creating surround KOs.

Defending goals.

Controlling buff nodes.

---

## Risk

Powerful rewards require exposure.

Examples:

Remaining on buff nodes.

Aggressive pushes.

Early energy spending.

---

## Counterplay

Every strategy should have available responses.

Examples:

Buff nodes can be contested.

Entrances can be blocked.

Ranked figures can still be KOed.

Modifiers consume resources.

---

# 3. Match Flow

A standard match follows the sequence below.

```text

Deck Building

↓

Matchmaking

↓

Map Selection

↓

Game Start

↓

Initial Deployment

↓

Player Turns

↓

Victory Check

↓

Results Screen

```

---

# 4. Turn System

## Core Rule

Each player receives:

One Action Per Turn

A player may never intentionally skip.

A valid action must always occur.

Turns alternate.

Player A

Player B

Player A

Player B

Until victory conditions are met.

---

# 5. Available Actions

There are three primary actions.

## Action 1

Deploy Figure

---

Requirements

Figure exists in Bench.

Entrance available.

---

Execution

Choose Figure.

Choose Entrance.

Deploy Figure.

Move Figure.

Attack if possible.

Turn Ends.

---

## Action 2

Move Figure

---

Requirements

Figure deployed.

Can move.

Has legal path.

---

Execution

Select Figure.

Select Destination.

Move.

Attack if adjacent.

Turn Ends.

---

## Action 3

Attack

---

Requirements

Enemy adjacent.

---

Execution

Select enemy.

Battle starts.

Resolve battle.

Apply effects.

Turn Ends.

---

# 6. Movement System

## Stamina

Figures possess stamina.

Stamina defines movement range.

Examples

Tank

1

Balanced

2

Assassin

3

Fast Units

4+

---

## Partial Movement

Figures do not need to consume all stamina.

Stopping early is permitted.

---

## Movement + Combat

If movement ends adjacent to an enemy.

Combat may immediately begin.

Movement and attacking are considered a single action.

Examples:

Move 1

Move 2

Adjacent

Attack

Turn Ends

---

# 7. Blocking

Figures occupy nodes.

Two figures cannot share a node.

---

## Enemy Blocking

Enemies prevent standard traversal.

---

## Jumping

If enough stamina remains.

A figure may jump an enemy.

Movement immediately ends.

Combat may begin.

Example

Player

Enemy

Destination

Jump

Combat

End Turn

---

## Pass Through

Certain figures may ignore blocking.

Examples:

Ghosts

Flying Units

Phasing Creatures

Pass Through does not grant immunity against Surround KO.

---

# 8. Deployment System

Figures begin inside Main Bench.

Deploying consumes the player's action.

A figure enters through a valid entrance.

After deployment:

Movement allowed.

Combat allowed.

Turn Ends.

---

# 9. Visibility Rules

Information visible to both players:

Energy

Status Effects

Rank Stage

Cooldowns

Buff Node Occupation

KO Timers

Board State

Current Figure Positions

---

Information hidden:

Unused Modifiers

Opponent Deck Composition

Future Rank Paths

Private Strategy

Modifiers become public only after first activation.

---

# 10. Naming Conventions

To maintain consistency.

The following terminology should always be used.

Figure

Node

Goal

Entrance

Rank Up

Modifier

Energy

KO

Buff Node

Debuff

Attack Pool

Attack Type

Status Effect

Cooldown

Bench

KO Bench

Main Bench

Surround KO

---

END OF PART 1A

Next Document:

GDD_v1.0_Part1B_CoreRules.md

Contents:

Combat System

Attack Types

Color Hierarchy

Status Effects

KO Rules

Bench Rules

Rank Up Rules

Victory Conditions
