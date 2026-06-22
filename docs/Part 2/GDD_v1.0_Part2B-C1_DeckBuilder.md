# GDD_v1.0_Part2B-C1_DeckBuilder.md

# Part 2B - Deck Builder Framework

Version: 1.0

Status: LOCKED

---

# 1. Deck Philosophy

The Deck Builder is intended to provide player expression.

Two players owning the same Figures should still be able to create different playstyles.

Deck construction should reward:

• Strategy

• Synergy

• Adaptability

• Creativity

• Resource Management

• Meta Understanding

Deck Building occurs outside of battle.

Decks can be edited at any time.

---

# 2. Deck Structure

Every Deck contains:

Figures:

6 Slots

Modifiers:

3 Slots

Total:

9 Components

---

Deck Validation Requirements

Playable Deck:

6/6 Figures

3/3 Modifiers

Status:

VALID

---

Incomplete Deck:

5/6 Figures

2/3 Modifiers

Status:

INVALID

Can be saved.

Cannot queue matchmaking.

---

# 3. Figure Slots

Each Figure occupies:

1 Slot

No restrictions.

Allowed:

6 Tanks

6 Agile

6 Controllers

6 Specialists

Mixed compositions

Designer freedom.

---

Figures maintain:

Configured Evolutions

Hidden Passives

Visual Cosmetics

Locked Variants

Skins

---

# 4. Modifier Slots

Each Modifier occupies:

1 Slot

Maximum:

3

Modifiers support:

Cooldowns

Uses

Single Use

Persistent Effects

Trap Deployment

Revive Effects

Global Effects

---

Duplicate Modifiers

Currently:

Not Allowed

Maximum Copies:

1

---

# 5. Deck Validation

Validation occurs automatically.

Conditions checked:

6 Figures

3 Modifiers

Legal Components

No Duplicate Modifiers

Unlocked Content

Ownership

Collection Availability

---

Validation States

VALID

WARNING

INVALID

---

Warnings

No Tank

No Blue Attacks

No Debuffer

No Revive

No Energy Support

Low Mobility

High Risk Composition

---

Warnings do not prevent play.

---

# 6. Deck Metadata

Decks support metadata.

Properties:

Deck Name

Icon

Banner

Description

Tags

Creation Date

Last Edited

Last Played

Version

Favorite

---

Example

Deck Name

Dragon Control

---

Tag

Ranked

Control

Burn

---

# 7. Saved Decks

Maximum Saved Decks:

20

Expandable later.

---

Saving Rules

Incomplete Decks:

Allowed

Playable:

No

---

Delete Deck:

Allowed

---

Duplicate Deck:

Allowed

---

Rename Deck:

Allowed

---

# 8. Favorite Decks

Decks may be favorited.

Maximum:

Unlimited

---

Favorite Benefits

Pinned

Quick Access

Sorting Priority

Suggested Deck

---

# 9. Deck Sharing

Decks support sharing.

Methods

Code

Import

Export

Clipboard

Future:

QR

Cloud

---

Deck Codes contain:

Figures

Modifiers

Evolution Settings

Cosmetics

Metadata

---

Ownership Validation

Required.

Missing Components:

Marked.

---

# 10. Suggested Improvements

AI may analyze decks.

Examples

Missing Tank

Missing Utility

Low Energy Usage

No Rank Support

High Miss Composition

Weak Goal Defense

---

Suggestions do not modify decks.

Player approval required.

---

# 11. AI Recommendations

Recommendations may include:

Figures

Modifiers

Strategies

Alternative Builds

Meta Suggestions

---

Example

Your Deck lacks:

Blue Outcomes

Control

Revive

Recommended:

Guardian Knight

Energy Shrine

Second Chance

---

# 12. Deck Statistics

Statistics tracked separately.

Modes:

Casual

Ranked

PvE

Custom

---

Statistics

Games Played

Wins

Losses

Win Rate

Average Match Length

Average Energy Used

Average Rank Ups

Average KO

Average Goal Victories

Most Used Figure

Most Used Modifier

---

# 13. Match History

History stored per Deck.

Examples

Last Match

Opponent

Mode

Map

Turns

Result

MVP Figure

Energy Used

Rank Ups

---

# 14. Deck Templates

Players may create templates.

Examples

Aggro

Control

Buff

Debuff

Energy

Rank Up

Defensive

Experimental

---

Templates are organizational only.

---

# 15. Deck Builder UX

Recommended Features

Drag & Drop

Search

Filters

Favorites

Sort By

Preview Figures

Preview Evolutions

Preview Modifiers

Validation Messages

Statistics Button

History Button

Import Button

Export Button

---

# 16. AI Deck Validator

AI Generated Decks cannot violate:

More than 6 Figures

More than 3 Modifiers

Duplicate Modifiers

Unavailable Components

Invalid Evolution Chains

---

Warnings

No Tank

No Blue

No Mobility

No Recovery

High Risk

---

AI must regenerate.

Until valid.

---

# 17. Deck Approval Checklist

☐ 6 Figures

☐ 3 Modifiers

☐ Validation Passed

☐ Statistics Enabled

☐ Metadata Complete

☐ Sharing Supported

☐ Suggestions Functional

☐ History Functional

☐ Favorites Functional

☐ Import/Export Functional

---

Status:

LOCKED

END OF PART 2B-C1

Next Document:

GDD_v1.0_Part2B-C2_Collection.md
