# GDD_v1.0_Part2A_CharacterFramework_C1.md

# Part 2A - Character Framework (Section C1)

---

# 22. Attack Pool Templates

## Overview

Attack Pools define every possible combat outcome a Figure can produce.

Attack Pools are independent from Character Class.

Attack Pools belong to the Figure.

Attack Pools may change through Rank Up.

Attack Pools should communicate the intended gameplay identity of a Figure.

---

# 23. Wheel Template

## Overview

Wheel is the most flexible Attack Type.

Wheel Figures define custom probabilities.

---

## Wheel Segment Structure

Each segment contains:

Color

Power

Stars

Effect

Status

Displacement

Probability

Description

---

## Template

Segment 1

Color:

White

Power:

60

Probability:

25%

Effect:

None

Status:

None

Displacement:

None

Description:

Basic attack.

---

Segment 2

Color:

Purple

Stars:

★★

Probability:

15%

Effect:

Fear

Status:

Fear

Displacement:

None

Description:

Applies Fear.

---

Segment 3

Color:

Blue

Probability:

20%

Effect:

None

Description:

Defensive outcome.

---

Segment 4

Color:

Gold

Power:

40

Probability:

20%

Effect:

Push 1

Status:

None

Displacement:

Push

Description:

Push enemy.

---

Segment 5

Color:

Red

Probability:

20%

Description:

MISS

---

## Validation

Total Probability:

100%

Mandatory.

---

Miss:

Optional

Blue:

Optional

Purple:

Optional

Gold:

Optional

White:

Optional

Only Red is highly recommended.

Can be omitted.

Designer discretion.

---

## Recommendations

Tank

Blue

White

Red

---

Debuffer

Purple

Blue

Red

---

Striker

White

Gold

Red

---

Controller

Purple

Gold

Blue

---

Specialist

No restrictions.

---

# 24. Dice Template

## Overview

Dice Figures use face outcomes.

Most common:

D6

Allowed:

D4

D6

D8

D10

D12

---

## Face Structure

Face Number

Color

Power

Stars

Effect

Status

Displacement

Description

---

## Example

Face 1

White

40

Face 2

Purple

★

Fear

Face 3

Gold

30

Push 1

Face 4

Blue

Face 5

Red

Face 6

White

80

---

## Validation

Faces should encourage:

Risk

Decision making

Character fantasy

---

# 25. Coin Template

## Overview

Coin Figures are high variance.

Simple to understand.

High excitement.

---

## Coin Structure

Heads

Tails

Miss Chance

Description

---

## Example

Heads

White

80

---

Tails

Purple

★★

Fear

---

Miss

1%

---

## Validation

Recommended

Miss

0-5%

Designer override allowed.

---

# 26. Double Coin Template

## Overview

Double Coin Figures toss two coins.

Each coin resolved independently.

Results combined.

---

## Coin Configuration

Coin A

Heads

White 40

Tails

White 20

---

Coin B

Heads

Gold 30

Tails

Blue

---

## Resolution

HH

White 70

---

HT

White 40

Blue

---

TH

White 50

---

TT

Blue

---

Designer chooses.

No restrictions.

---

# 27. Dice Sum Template

## Overview

Figures roll two dice.

Sum determines attack.

Usually

2D6

---

## Attack Table

Result

Attack

---

2

MISS

---

3

White 20

---

4

White 40

---

5

Purple ★

---

6

Gold 30

---

7

White 70

---

8

Purple ★★

---

9

Blue

---

10

Gold 50

---

11

White 100

---

12

Purple ★★★

---

## Validation

Higher values generally stronger.

Not mandatory.

Can support gimmicks.

Can support reverse scaling.

Designer choice.

---

# 28. Attack Properties

Every Attack may contain:

Damage

Stars

Status

Buff

Debuff

Movement

Energy Gain

Energy Loss

Rank Gain

Modifier Interaction

Node Interaction

Goal Interaction

Passive Trigger

Hidden Trigger

Cooldown Trigger

---

# 29. Attack Status Library

Current Supported Statuses

Paralyzed

Immobilized

Fear

Weakened

Burn

Poison

Freeze

Silence

Confusion

Sleep

Curse

Marked

Shield Break

---

Designer expandable.

---

END OF PART 2A-C1

Next Document

GDD_v1.0_Part2A_CharacterFramework_C2.md

Contains:

Evolution Templates

Rank Up Templates

AI Character Validator

AI Generation Standards

Starter Roster Philosophy

Character Prompt Standard

Character Checklist

Character Approval Rules
