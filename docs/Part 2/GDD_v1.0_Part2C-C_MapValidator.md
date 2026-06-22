# GDD_v1.0_Part2C-C_MapValidator.md

# Part 2C - AI Map Validator

Version: 1.0

Status: LOCKED



---

# 1. Philosophy


The Map Validator exists to ensure maps are:

• Fair

• Competitive

• Playable

• Understandable

• Strategically interesting

• Compatible with mobile devices


The validator should automatically reject maps that violate core gameplay principles.



---

# 2. Validation Categories


Maps are validated in six categories.


• Structure

• Accessibility

• Balance

• Buff Nodes

• Combat Flow

• User Experience



Each category may produce:


PASS


WARNING


INVALID



---

# 3. Structural Validation


Checks map construction.



Requirements:


Minimum Nodes

18


Maximum Nodes

60


Allowed Connections

Horizontal

Vertical

Diagonal


Disconnected Components

Not Allowed


Floating Nodes

Not Allowed


Duplicate Connections

Not Allowed



---

Invalid Examples


Node without connections


Isolated island


Broken graph


Disconnected half map



Result


INVALID



---

# 4. Symmetry Validation


MVP Requirement:


Maps must be symmetrical.



Allowed:


Horizontal


Vertical


Rotational



Not Allowed


Asymmetrical Maps



Failure


INVALID



---

# 5. Goal Validation


Requirements:


Exactly 2 Goals


One Friendly


One Enemy



Goals must be reachable.


Goals may be surrounded.


Goals may be occupied.


Goals do not require minimum entrances.



Checks


Goal Reachability


Path Existence


Spawn Access



Failure


INVALID



---

# 6. Spawn Validation


Allowed


2 Entrances


3 Entrances



Large Maps


May have 3 Entrances.



Checks


All Entrances Reachable


Equal Distance


No Immediate Advantage



Warnings


Distance difference >2 nodes



Invalid


Spawn inaccessible



---

# 7. Buff Node Validation


Buff Nodes are optional.



Recommended


0-4



Checks


Reachable


Contested


Symmetrical


Activation Possible



Warnings


Too many Buff Nodes


Buff adjacent to Goal


Buff adjacent to Spawn



Invalid


Unreachable Buff


Broken Cooldown Logic



---

# 8. Combat Validation


Maps should encourage interaction.



Expected Combat


Aggro

Turn 2-3


Control

Turn 3-5


Fortress

Turn 4-6


Large

Turn 4-6



Warnings


Combat Estimated Turn 8+


Single Corridor


No Alternate Routes



Invalid


Combat Impossible



---

# 9. Path Diversity


Checks


At least 2 routes


Preferred 3


Excellent 4+



Warnings


Only one route


Excessive dead ends


Too many choke points



Invalid


No alternate path



---

# 10. Mobility Validation


Checks



Stamina 1 Figures


Playable



Stamina 2 Figures


Playable



Stamina 3+ Figures


Useful



Jump Mechanics


Supported



Phasing


Supported



Invalid


Movement impossible



---

# 11. Goal Pressure Validation


Checks


Can Goal Be Defended


Can Goal Be Attacked


Can Goal Be Bypassed


Can Spawn Blocking Exist



Warnings


Impossible Defense


Permanent Lockout



Invalid


Goal Unreachable



---

# 12. Mobile Validation


Required.


Checks


Readable Layout


Node Density


Touch Precision


Zoom Support


UI Space



Warnings


Crowded Areas


Tiny Nodes



Invalid


Impossible Interaction



---

# 13. AI Generation Validation


AI Generated Maps must pass:


Structure


Symmetry


Accessibility


Combat


Buff Nodes


UX



If INVALID:


Regenerate



If WARNING:


Human Approval



If PASS:


Approved



---

# 14. Human Review


Recommended Questions


Does this map feel fair?


Does this map create decisions?


Does this map promote combat?


Does this map support multiple decks?


Can a beginner understand it?


Would I enjoy playing it repeatedly?



---

# 15. Validation Score


Optional.


Score


100


Perfect


90


Competitive


80


Playable


70


Needs Review


Below 70


Rejected



---

# 16. Approval Checklist


□ Symmetrical


□ Reachable Goals


□ Reachable Entrances


□ Buff Nodes Balanced


□ Combat by Intended Turn


□ Multiple Routes


□ Spawn Fairness


□ Mobile Friendly


□ Validator Passed


□ Human Approved



---

Status:


LOCKED


END OF PART2C-C_MapValidator



END OF PART2



Part 2 Status:


LOCKED


Completion:


100%



Core Gameplay Completion:


≈ 98-99%



Remaining Major Sections:


Part 3A Economy

Part 3B Matchmaking

Part 3C Monetization

Part 3D PvE

Part 3E UI/UX

Part 4 Content Production Pipeline

Part 5 Live Service Framework

