# GDD_v1.0_Part2C-A_MapFramework.md

# Part 2C - Map Framework

Version: 1.0

Status: LOCKED



---

# 1. Map Philosophy


Maps are intended to be strategic puzzles.

Maps should encourage:

• Combat

• Positioning

• Area Control

• Risk Management

• Defensive Play

• Offensive Pushes

• Alternative Routes

• Spawn Blocking

• Buff Node Control


Maps should never feel solved.

Different compositions should prefer different routes.



---

# 2. Design Principles


Maps should prioritize:


Symmetry


Fairness


Route Diversity


Chokepoints


Tactical Positions


Combat Opportunities


Buff Node Contests



Maps should not provide inherent advantage to either player.



---

# 3. Map Sizes


Small

Recommended:


18-24 Nodes



Characteristics:


Fast Matches


Aggressive


Less Defensive



Recommended Entrances


2



Recommended Buff Nodes


0-2



---


Medium


Recommended:


25-40 Nodes



Characteristics:


Balanced


Most Competitive



Entrances


2


or


3



Buff Nodes


1-3



---


Large


Recommended:


40-60 Nodes



Characteristics:


Positional


Defensive


Long Matches



Entrances


2-3



Buff Nodes


2-4



---

# 4. Symmetry


Maps should be symmetrical.


Recommended:


Horizontal Symmetry


Vertical Symmetry



Allowed:


Rotational Symmetry



Not Recommended:


Asymmetrical Maps



MVP:


Symmetrical Only.



---

# 5. Node Philosophy


Nodes represent playable spaces.


A Figure occupies exactly:


1 Node.



Maximum Figures per Node:


1



Figures cannot overlap.



---

Nodes define:


Movement


Combat


Objectives


Positioning


Control



---

# 6. Connections


Connections define adjacency.


Two Nodes are adjacent if:


A visible connection exists.


Connection types:


Horizontal


Vertical


Diagonal



All valid.



---

Example


Node A


↘


Node B


Can Move


Can Attack


Can Interact



---

# 7. Goals


Each Player has:


1 Goal.



Properties


Friendly Goal


Enemy Goal



---

Victory Condition


Occupy Enemy Goal.



Immediate Victory.



---

Friendly Goals


Can be occupied.


Allowed.



Enemy cannot enter.


If occupied.



---

If defender leaves.


Goal becomes vulnerable.



---

Goals may become surrounded.


No effect.


Still playable.



---

Recommended Goal Access


2+ connections


Preferred.


Not Mandatory.



---

# 8. Entrances


Entrances deploy Figures.


Properties


Friendly


Enemy



---

Entrances available


2


or


3



Large Maps


May use


3



---

Blocking Rules


Occupied Entrance


Unavailable.


Regardless of ownership.



---

Example


Ally standing


Entrance unusable.



Enemy standing


Entrance blocked.



---

# 9. Triple Entrance Rule


Large Maps may use:


3 Entrances.



Recommended:


Two entrances interconnected.



Occupying one may indirectly pressure another.



Purpose:


Spawn Denial


Map Control


Positioning



---

# 10. Movement


Movement follows connections.


Consumes:


Stamina.



Figure may move.


Until stamina exhausted.



---

If movement ends adjacent to enemy.


Figure may attack.



Allowed.



---

Movement + Attack


Valid.



---

Cannot end turn.


Without action.



---

# 11. Jumping


Blocked Figures.


May be jumped.


Requirements:


Enough remaining stamina.



Jump consumes remaining movement.


Equivalent.


Figure arrives behind blocker.



Can attack.


Allowed.



Turn ends.


After attack.


Or immediately.



---

# 12. Phasing


Some Figures.


Ignore blockers.



Can traverse.


Occupied Nodes.



Still vulnerable.


To Surround KO.



---

# 13. Buff Nodes


Buff Nodes are Nodes.


Special Properties.


Additional Rules.



Movement.


Normal.



Combat.


Normal.



Occupancy.


Normal.



---

Buff Nodes.


Only differ by:


Activation Conditions


Effects


Cooldowns


Ownership


Charges



---

Recommended Placement


Intersections


Three-way paths


Contested zones



Avoid


Spawn Areas


Goals


Dead Ends



---

# 14. Terrain Themes


Terrain is cosmetic.


No gameplay impact.


MVP.


Examples


Forest


Snow


Ruins


Temple


Volcano


Cyber


Night


Beach


Space


Swamp



---

Day/Night


Cosmetic only.



---

# 15. Teleporters


Possible.


Rare.



Recommended:


Very few.


Or none.



MVP


Prefer none.



---

# 16. Dynamic Events


Not Supported.


MVP.



Examples


Storms


Collapsing Bridges


Moving Platforms



Future Expansion.



---

# 17. Secondary Objectives


Not Objectives.


Only recommendations.


Buff Nodes already fulfill.


Map Control purposes.



---

# 18. Map Balance Guidelines


Each Spawn.


Equal opportunities.



Buff Nodes.


Contestable.


By both players.



No Buff Node.


Should guarantee victory.



Multiple paths.


Preferred.



Combat.


Expected.


By Turn 3-5.



---

# 19. AI Map Validator


AI Generated Maps.


Must Validate:



Symmetry


Connections


Reachability


Goal Accessibility


Spawn Fairness


Buff Placement


Node Density



---

Warnings


Dead Ends


Too many Buff Nodes


Impossible Routes


Spawn Advantage


Single Corridor Maps


No Combat Opportunities



AI regenerates.


Until valid.



---

# 20. Approval Checklist


☑ Symmetrical


☑ Reachable Goals


☑ Valid Entrances


☑ Fair Buff Nodes


☑ Combat by Turn 3-5


☑ Multiple Routes


☑ Mobile Friendly


☑ Validator Passed



---

Status:


LOCKED



END OF PART2C-A



Next Document:


GDD_v1.0_Part2C-B_MapPatterns_and_Generation.md


Part2C Completion:


~35%
