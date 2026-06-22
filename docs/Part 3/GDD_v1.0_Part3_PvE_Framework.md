# GDD_v1.0_Part3_PvE_Framework.md

# Part 3 - PvE Framework

Version: 1.0

Status: WORK IN PROGRESS



---

# 1. PvE Philosophy


## Purpose


PvE exists for four primary reasons.


• Teach players the game.

• Allow gameplay without internet requirements.

• Test balance before PvP implementation.

• Provide enjoyable content for players who prefer solo experiences.


PvE should never feel like a lesser version of PvP.

The objective is to create opponents that feel believable and strategically competent.


The primary goal during MVP development is:


> Validate if the game itself is fun.



PvP implementation is considered secondary.



---

# 2. PvE Modes



## 2.1 VS CPU


Status


MVP Supported



Description


Standard match against an AI controlled opponent.



Rules


Uses standard PvP rules.


No special rules.


No advantages.


No cheating.



Player uses their own Deck.



Bot uses its own Deck.



Available Maps


Any standard map.



Rewards


Optional.


May grant:


Experience


Currencies


Chests


Keys


Cosmetics



Victory Conditions


Same as PvP.



Defeat Enemy Goal.


Eliminate enemy roster.


Block enemy deployment.


Standard Rules apply.



---

## 2.2 Tutorial Matches


Status


Supported.



Purpose


Teach game mechanics.



Tutorials may override normal deck rules.



Allowed Restrictions


Forced Figures.


Fixed Modifiers.


Predefined Positions.


Limited Actions.


Disabled Mechanics.



Examples


Tutorial 1


Movement.



Tutorial 2


Combat.



Tutorial 3


Rank Up.



Tutorial 4


Modifiers.



Tutorial 5


Buff Nodes.



Tutorial 6


Surround K.O.



Tutorial 7


Goal Defense.



Tutorial 8


Jumping.



Tutorial 9


Status Effects.



Tutorial 10


Complete Match.



Rewards


One-time rewards.



Optional.



---

## 2.3 Puzzle Battles


Status


Supported.



Purpose


Teach advanced concepts.



Examples



Win in 2 Turns.


Defeat enemy without modifiers.


Rank Up twice.


Protect Goal.


Block Entrances.


Use Buff Nodes.


Force Surround KO.


Win using only 2 Figures.



Puzzle Rules


Can modify:


Initial Positions.


Deck Composition.


Energy.


Modifiers.


Turn Limits.


Status Effects.



Rewards


Optional.



Usually One-time.



---

## 2.4 Boss Battles


Status


Supported.



Purpose


Create memorable encounters.



Bosses may break standard game rules.



Allowed Boss Advantages



Additional Figures.


Additional Modifiers.


Multiple Passives.


Special Abilities.


Unique Attack Systems.


Custom Buff Nodes.


Custom Mechanics.



Examples


Ancient Dragon


Titan


Corrupted King


Living Fortress


Swarm Queen



Boss Restrictions


Only PvE.


Never PvP.



Rewards


Cosmetics.


Characters.


Titles.


Event Chests.



---

# 3. AI Philosophy


Bots should simulate human players.


Bots should not cheat.


Bots should not access hidden information.


Bots should use the same game rules.


Difficulty should come from:


Decision Making.


Risk Assessment.


Planning.


Modifier Usage.


Positioning.


Goal Awareness.



Bot knowledge:


Visible Board State


Yes.


Opponent Modifiers


No.


Future RNG


No.


Secret Information


No.



---

# 4. AI Difficulty Levels


Easy


Medium


Hard


Expert



Experimental


Cheater



Cheater is disabled by default.



PvE MVP focuses on:


Easy


Medium


Hard


Expert



---

# 5. AI Personalities

Bots may have personalities.

A Personality modifies priorities, risk tolerance and decision making.

A Bot has:

Difficulty
+
Personality


Example

Easy + Aggressive

Hard + Turtle

Expert + Buff Controller



## 5.1 Aggressive


Primary Goal

K.O enemy Figures.


Priorities

Combat

Rank Ups

Pressure Goal

Surround K.O


Behavior

Takes moderate risks.


Ignores some defensive opportunities.


Attempts combat frequently.



Recommended Figures

Warriors

Dragons

Glass Cannons



---

## 5.2 Defensive


Primary Goal

Protect Friendly Goal.


Priorities


Defend Goal

Protect Buff Nodes

Maintain Board Presence


Behavior


Retreats more often.


Keeps Figures near Goal.


Blocks important paths.



Recommended Figures


Tank

Support

Debuffers



---

## 5.3 Goal Rusher


Primary Goal


Occupy Enemy Goal.


Priorities


Fast Units

Movement

Open Routes


Behavior


Ignores some combat.


Values mobility.



Recommended Figures


Agile


Jumpers


Phasing Units



---

## 5.4 Buff Controller


Primary Goal


Control Buff Nodes.


Priorities


Buff Nodes


Energy Gain


Positioning



Behavior


Waits for activations.


Rotates Figures.


Denies Buff Nodes.



---

## 5.5 Rank Up Lover


Primary Goal


Achieve Evolutions.


Priorities


Easy KOs


Weak Targets


Combat Selection



Behavior


Will attack weaker enemies.


Protect evolved units.



---

## 5.6 Turtle


Primary Goal


Survive.


Priorities


Defensive Positioning


Goal Defense


Avoid Risks



Behavior


Slow.


Reactive.


Waits for mistakes.



---

## 5.7 Random


Primary Goal


Unpredictability.


Behavior


Semi-random.


Weighted choices.


Still legal.



Recommended


Easy Difficulty.



---

## 5.8 Expert


Primary Goal


Maximize Win Chance.


Behavior


Calculates probabilities.


Evaluates board state.


Optimizes movement.


Protects evolved figures.


Uses modifiers efficiently.



---

# 6. Difficulty Framework


Difficulty modifies intelligence.


Not statistics.



Bots never receive:


Extra Damage


Extra Figures


Extra Energy


Cheating Information



Bosses are exceptions.



---

## 6.1 Easy


Thinking Depth


0-1 Turns


Risk Assessment


Low


Mistakes


Frequent


Modifier Usage


Poor


Buff Node Interest


Low


Rank Up Interest


Medium



Characteristics


Feels like a beginner player.



---

## 6.2 Medium


Thinking Depth


1 Turn


Risk Assessment


Moderate


Mistakes


Occasional


Modifier Usage


Average


Buff Nodes


Moderate


Rank Up


High



Characteristics


Represents average players.



---

## 6.3 Hard


Thinking Depth


2 Turns


Risk Assessment


High


Mistakes


Rare


Modifier Usage


Good


Goal Awareness


High


Evolution Protection


High



Characteristics


Competitive.



---

## 6.4 Expert


Thinking Depth


3+ Turns


Risk Assessment


Very High


Mistakes


Almost None


Modifier Usage


Excellent


Buff Nodes


Excellent


Goal Defense


Excellent


Combat Evaluation


Excellent



Characteristics


Tournament-like behavior.



---

# 7. AI Decision Framework


Bots evaluate possible actions.


Every turn.


Bot generates legal actions.


Scores them.


Executes best action.



Examples


Move


Attack


Deploy


Modifier


Wait on Buff Node


Rank Up



---

## Decision Priority Example


Expert Bot


1.

Immediate Victory


2.

Prevent Immediate Defeat


3.

Rank Up


4.

Secure Buff Node


5.

KO Opportunity


6.

Protect Goal


7.

Position Better


8.

Deploy Figure


9.

Fallback Movement



---

Easy Bots


May ignore priorities.


Hard Bots


Follow priorities closely.



---

# 8. Combat Evaluation


Bots estimate success.


Factors


Enemy Type


Attack Probabilities


Status Effects


Modifiers


Rank Ups


Board Position


Goal Safety


Potential Surround KO



Example


Attack Chance

72%


Decision


Attack



---

---

# 9. Boss Framework


Bosses exist to provide unique PvE experiences.


Bosses are only available in PvE.


Bosses may violate standard game rules.


Bosses should feel memorable.


Bosses should encourage strategy adaptation.


Bosses should not simply be stronger versions of standard Figures.



---

## 9.1 Allowed Boss Rule Exceptions


Bosses may have:


Additional Figures.


Additional Modifiers.


Additional Passives.


Unique Passives.


Special Buff Nodes.


Custom Objectives.


Multiple Actions.


Special Attack Systems.


Unique Mechanics.



Bosses may not:


Read hidden Modifiers.


Predict RNG.


Ignore combat resolution.


Ignore K.O.


Occupy multiple nodes.


(Reserved for future consideration)



---

## 9.2 Boss Categories



### Elite


Slightly stronger enemy.


Mostly standard rules.


Recommended.


MVP.



Examples


Elite Dragon


Elite Knight


Elite Titan



---


### Raid Boss


Special encounter.


Unique mechanics.


Examples


Dragon King


Ancient Machine


Void Entity


Living Fortress



---


### Puzzle Boss


Designed around mechanics.


Examples


Can only be defeated by:


Surround K.O.


Rank Up.


Goal Rush.


Buff Node Control.



---


### Event Boss


Limited availability.


Seasonal.


Temporary rewards.



---

## 9.3 Boss Objectives


Boss battles may use custom objectives.


Examples:


Survive 10 turns.


Protect ally.


Destroy summons.


Rank Up twice.


Capture Buff Nodes.


Prevent Goal Occupation.


Reach enemy Goal.


Defeat specific Figure.



---

## 9.4 Boss AI


Bosses have:


Difficulty


Personality


Boss Script



Boss Script examples:


Phase Changes.


New Passives.


Modifier Injection.


Map Alteration.


Summons.



---

# 10. PvE Rewards


PvE rewards should encourage engagement.


PvE rewards should never become mandatory for PvP success.


PvE rewards should support collection progression.



---

## 10.1 Possible Rewards


Experience.


Currencies.


Chests.


Keys.


Cosmetics.


Titles.


Portraits.


Borders.


Characters.


Skins.


Event Tokens.



---

## 10.2 Reward Sources


VS CPU


Bosses


Challenges


Tutorials


Puzzles


Daily Missions


Weekly Missions



---

## 10.3 One-Time Rewards


Tutorial completion.


Puzzle completion.


Campaign completion.


Boss first clear.



---

## 10.4 Repeatable Rewards


CPU Wins.


Challenge Rotation.


Daily Tasks.


Weekly Tasks.



---

# 11. AI Bot Generator


Purpose:


Generate AI opponents automatically.



Bot Generation Parameters:


Difficulty


Personality


Theme


Deck Type


Evolution Preference


Modifier Usage


Aggressiveness


Goal Defense


Buff Interest



---

Example Prompt



Create Bot:


Difficulty:

Hard


Personality:

Rank Up Lover


Theme:

Dragons


Playstyle:

Aggressive


Modifier Usage:

High


Evolution Focus:

Yes




Result:


Complete playable bot.



---

## 11.1 AI Generated Deck Rules


Must follow Deck Builder rules.


6 Figures.


3 Modifiers.


Legal Evolutions.


Passives.


Cooldown Validation.


Energy Validation.


Map Compatibility.



---

## 11.2 AI Generated Modifier Usage


Easy


Suboptimal.



Medium


Average.



Hard


Optimized.



Expert


Near Human Competitive.



---

# 12. PvE Validator


Purpose:


Ensure generated bots are enjoyable.


Checks:


Deck legality.


Evolution legality.


Modifier legality.


Difficulty consistency.


Behavior consistency.


Map compatibility.


Energy compatibility.



---

## Validation Results


PASS


WARNING


INVALID



---

Examples



Easy Bot


Calculates 3 turns ahead.


INVALID.



Expert Bot


Uses random movement.


WARNING.



Boss


Occupies 3 nodes.


WARNING.


Future feature.



---

# 13. Approval Checklist


□ Bot respects game rules.


□ Bot difficulty feels correct.


□ Personality is noticeable.


□ Boss is unique.


□ Rewards are fair.


□ Tutorial teaches concepts.


□ Puzzle is solvable.


□ CPU battle is enjoyable.


□ Bot uses modifiers correctly.


□ Bot understands goals.


□ Validator passed.


□ Human approved.



---

Status


WORK IN PROGRESS



Completion


~90%



Remaining Questions


Campaign System


Daily Rotation


Weekly Rotation


Achievement Framework


Challenge Generation


Boss Scripting Depth



Campaigns

Status:
Supported

MVP:
Minimal

Notes:
Few encounters.
Used mainly for onboarding and future expansion.

Daily Missions

Status:
Supported

MVP:
Disabled

Future:
Enabled post-launch.

Achievements

Status:
Not Supported

MVP:
Disabled

Future:
Possible reconsideration.

Challenge Rotation

Status:
Not Supported

MVP:
Disabled.

Boss Phases

Status:
Not Supported

MVP:
Single Phase Bosses only.

Future:
Possible multi-phase encounters.
