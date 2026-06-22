# GDD_v1.0_Part2B-A_Modifiers.md

# Part 2B - Modifiers Framework

Version: 1.0

Status: LOCKED

---

# 1. Modifier Philosophy

Modifiers are intended to increase player expression.

Modifiers should not replace positioning.

Modifiers should not replace combat.

Modifiers should not replace strategic planning.

Modifiers exist to provide tactical decisions.


Modifiers should allow:

• Emergency defenses

• Offensive pushes

• Recovery plays

• Combo setups

• Counterplay

• Resource management


Modifiers are selected before entering a match.

Modifiers belong to the Player.

Modifiers do not belong to individual Figures.


---

# 2. Modifier Slots


Each Deck contains:


6 Figures


3 Modifiers


Decks cannot enter matchmaking unless:


6/6 Figures


3/3 Modifiers


are selected.


---

# 3. Modifier Information


Each Modifier contains:


Name


Category


Description


Energy Cost


Cooldown


Uses


Target


Activation Window


Duration


Visibility


Rarity


Icon


Animation


Sound Effect


Flavor Text


---

# 4. Modifier Categories


## Attack


Increase offensive capabilities.


Examples


+20 White Damage


+10 Gold Damage


+1 Purple Star


Reduce Miss Chance


---

## Defense


Protect allies.


Examples


Temporary Blue


Status Immunity


Shield


---

## Utility


Movement support.


Examples


Extra Stamina


Ignore Blocking


Jump


Phase


---

## Control


Manipulate enemies.


Examples


Fear


Immobilize


Push


Pull


Swap


---

## Economy


Energy manipulation.


Examples


Gain Energy


Reduce Costs


---

## Rank


Interact with Evolutions.


Examples


Immediate Rank Up


Bonus Rank EXP


---

## Revive


Recover KO Figures.


Examples


Recover Figure from KO Bench


---

## Trap


Deploy board effects.


Examples


Fear Trap


Poison Trap


Slow Trap


---

## Special


Unique mechanics.


Designer freedom.


---

# 5. Energy Costs


Modifiers consume Energy.


Energy belongs to Player.


Energy Maximum:


10


---

Recommended Costs


Cheap


1-3


Moderate


4-6


Expensive


7-8


Legendary


9-10


---

Examples


Reroll Miss


Cost 3


---

Revive


Cost 9


---

Immediate Rank Up


Cost 10


---

# 6. Cooldowns


Modifiers may have cooldowns.


Examples


Cooldown


0


Reusable immediately.


---

Cooldown


2 Turns


---

Cooldown


5 Turns


---

Cooldown


Match Long


Single Use


---

# 7. Uses


Modifiers support:


Unlimited


Limited


Single Use


---

Examples


Unlimited


Cooldown 2


Cost 3


---

Uses


3


Cooldown 1


Cost 4


---

Uses


1


Cost 10


---

After Uses reach 0


Modifier becomes inactive.


---

# 8. Visibility Rules


Modifiers remain hidden.


Only owner sees them.


Opponent sees:


Nothing.


---

Upon first activation.


Modifier becomes public.


Opponent can inspect.


Modifier remains visible.


For remainder of match.


---

# 9. Targets


Modifiers may target:


Self


Ally


Enemy


All Allies


All Enemies


Board


Node


Goal


Bench


KO Bench


Global


---

Examples


Target


Self


Gain +20 White


---

Target


Enemy


Fear


---

Target


Board


Deploy Trap


---

# 10. Activation Windows


Modifiers specify when they may activate.


---

Deploy Phase


---

Movement Phase


---

Combat Declaration


---

Before Combat


---

After Combat


---

Turn End


---

Enemy Turn


---

Passive Trigger


---

Goal Defense


---

KO Event


---

Rank Up Event


---

# 11. Modifier Resolution Order


Modifiers resolve according to Priority.


Priority


Modifier


↓

Passive


↓

Buff Node


↓

Status


↓

Combat


↓

Rank Up


↓

Victory Check


---

# 12. Persistent Modifiers


Persistent Modifiers remain active.


Duration defined individually.


Examples


Duration


1 Turn


---

Duration


3 Turns


---

Duration


Until KO


---

Duration


Match


---

Example


War Aura


Cost


6


Duration


3 Turns


Effect


All Allies


+20 White Damage


---

# 13. Trap Modifiers


Traps create temporary board hazards.


Placed onto Nodes.


---

Trap Components


Owner


Duration


Charges


Effect


Visibility


Cooldown


---

Examples


Fear Trap


Duration


3 Turns


Effect


Fear 2 Turns


---

Poison Trap


Duration


2 Turns


---

Energy Trap


Steal Node


Gain 1 Energy


---

Trap Visibility


Hidden


Until Triggered


---

After Trigger


Visible


To everyone.


---

# 14. Revive Modifiers


Revive Modifiers recover Figures.


Recovered Figure leaves KO Bench.


Returns to Normal Bench.


Does not deploy automatically.


Player must spend actions.


To deploy.


---

Examples


Second Chance


Cost


9


Uses


1


Cooldown


None


Effect


Recover Figure


From KO Bench


To Bench


---

# 15. Modifier Rarity


Common


Rare


Epic


Legendary


Mythic


---

Rarity affects:


Acquisition


Visuals


Animation


Portrait Border


---

Rarity does NOT guarantee power.


---

# 16. AI Modifier Validator


AI Generated Modifiers cannot violate:


Energy


Cooldown


Uses


Duration


Target


Priority


---

AI Warnings


Cost too low


Cooldown too short


Infinite Revival


Permanent Fear


Permanent Immunity


---

AI must regenerate.


Until valid.


---

# 17. Modifier Generation Prompt


Template


Name:


Category:


Energy Cost:


Cooldown:


Uses:


Target:


Activation Window:


Duration:


Effect:


Visual Theme:


Animation:


Sound:


Flavor Text:


---

Example


Name:


Second Chance


Category:


Revive


Energy:


9


Uses:


1


Target:


KO Bench


Duration:


Instant


Effect:


Recover Figure


To Bench


Visual:


Golden Wings


Animation:


Light Burst


Sound:


Phoenix Cry


---

END OF PART 2B-A


Status:


LOCKED


Next Document:


GDD_v1.0_Part2B-B_BuffNodes.md
