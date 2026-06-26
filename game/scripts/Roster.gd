extends RefCounted
class_name Roster
## MVP starter roster — figures currently produced in Meshy, with explicit
## Meshy-clip -> Tier 1 mappings (verified), stamina, and attack pools (weighted
## segments; every attack type expressed as a wheel). Duplicates allowed in a deck.
## Sheet: docs/Part 2/GDD_v1.0_Part2A_StarterRoster_MVP.md

const FIGURES := [
	{
		"id": "stone_golem", "name": "Stone Golem", "stamina": 1, "type": "Ruleta",
		"passives": ["bedrock", "counter_stone"],
		"glb": "res://assets/figures/stone_golem/stone_golem.glb",
		"size": 1.30, "complete": true,
		"clips": {
			"idle": "Idle_3", "move_walk": "Walking", "move_run": "Running",
			"attack": "Attack", "attack_heavy": "Axe_Spin_Attack",
			"defend": "Block2", "hit": "Hit_Reaction_1", "ko": "Knock_Down",
		},
		"attack": [
			{"col": "blue", "name": "Bedrock Wall", "w": 35}, {"col": "white", "name": "Boulder Fist", "pow": 80, "w": 30},
			{"col": "white", "name": "Rockslide", "pow": 50, "w": 15}, {"col": "gold", "name": "Ground Pound", "pow": 40, "w": 10},
			{"col": "red", "w": 10},
		],
	},
	{
		"id": "ironclad_knight", "name": "Ironclad Knight", "stamina": 2, "type": "Dado (D6)",
		"passives": ["hold_the_line", "bulwark"],
		"glb": "res://assets/figures/ironclad_knight/ironclad_knight.glb",
		"size": 1.00, "complete": true,
		"clips": {
			"idle": "Idle_5", "move_walk": "Walking", "move_run": "Running",
			"attack": "Attack", "attack_heavy": "Axe_Spin_Attack",
			"defend": "Shield_Push_Left", "hit": "Hit_Reaction_1", "ko": "Dead",
		},
		"attack": [
			{"col": "white", "name": "Sword Chop", "pow": 60, "w": 1}, {"col": "white", "name": "Shield Bash", "pow": 80, "w": 1},
			{"col": "blue", "name": "Shield Wall", "w": 1}, {"col": "blue", "name": "Shield Wall", "w": 1},
			{"col": "purple", "name": "Stagger", "stars": 1, "w": 1}, {"col": "gold", "name": "Shoulder Charge", "pow": 40, "w": 1},
		],
	},
	{
		"id": "nightblade", "name": "Nightblade", "stamina": 3, "type": "Moneda",
		"glb": "res://assets/figures/nightblade/nightblade.glb",
		"size": 0.95, "complete": true,
		"clips": {
			"idle": "Idle_10", "move_walk": "Walking", "move_run": "Running",
			"attack": "Double_Combo_Attack", "attack_heavy": "Triple_Combo_Attack",
			"defend": "Block8", "hit": "Hit_Reaction_1", "ko": "Fall_Dead_from_Abdominal_Injury",
		},
		"attack": [
			{"col": "white", "name": "Killing Edge", "pow": 100, "w": 49.5},
			{"col": "purple", "name": "Fear Gas", "stars": 2, "fx": "Miedo", "w": 49.5}, {"col": "red", "w": 1},
		],
	},
	{
		"id": "rift_mage", "name": "Rift Mage", "stamina": 2, "type": "Suma 2d6",
		"passives": ["arcane_pull"],
		"glb": "res://assets/figures/rift_mage/rift_mage.glb",
		"size": 0.95, "complete": true,
		"clips": {
			"idle": "Idle_6", "move_walk": "Walking", "move_run": "Running",
			"attack": "mage_soell_cast_1", "attack_heavy": "mage_soell_cast_4",
			"defend": "Stand_Dodge", "hit": "Hit_Reaction", "ko": "dying_backwards",
		},
		"attack": [
			{"col": "red", "w": 1}, {"col": "white", "name": "Arc Bolt", "pow": 20, "w": 2},
			{"col": "purple", "name": "Force Wave", "stars": 1, "fx": "Empuje", "disp": "push", "n": 1, "w": 3}, {"col": "blue", "name": "Rune Ward", "w": 4},
			{"col": "gold", "name": "Rift Swap", "pow": 30, "fx": "Intercambio", "disp": "swap", "ko": false, "w": 5}, {"col": "white", "name": "Arcane Lance", "pow": 50, "w": 6},
			{"col": "purple", "name": "Gravity Hook", "stars": 2, "fx": "Jalon", "disp": "pull", "n": 1, "w": 5}, {"col": "blue", "name": "Rune Ward", "w": 4},
			{"col": "gold", "name": "Astral Strike", "pow": 40, "w": 3}, {"col": "white", "name": "Mana Burst", "pow": 80, "w": 2},
			{"col": "purple", "name": "Reality Warp", "stars": 3, "fx": "Intercambio", "disp": "swap", "w": 1},
		],
	},
	{
		"id": "venom_witch", "name": "Venom Witch", "stamina": 2, "type": "Ruleta",
		"passives": ["venom_hex"],
		"glb": "res://assets/figures/venom_witch/witch/witch.glb",
		"size": 1.00, "complete": true,
		"clips": {
			"idle": "Idle_9", "move_walk": "Walking", "move_run": "Running",
			"attack": "mage_soell_cast_4", "attack_heavy": "mage_soell_cast_6",
			"defend": "Block10", "hit": "Hit_Reaction_to_Waist", "ko": "Dead",
		},
		"attack": [
			{"col": "purple", "name": "Fear Hex", "stars": 1, "fx": "Miedo", "w": 25}, {"col": "purple", "name": "Plague Cloud", "stars": 2, "fx": "Debilitado", "w": 15},
			{"col": "blue", "name": "Hex Ward", "w": 15}, {"col": "white", "name": "Venom Bolt", "pow": 40, "w": 20},
			{"col": "red", "w": 25},
		],
	},
	{
		"id": "storm_valkyrie", "name": "Storm Valkyrie", "stamina": 4, "type": "Ruleta", # anim incomplete (1 clip)
		"glb": "res://assets/figures/storm_valkyrie/Meshy_AI_model_Animation_Walking_withSkin.glb",
		"size": 1.00, "complete": false,
		"clips": {
			"idle": "Armature|Unreal Take|baselayer",
		},
		"attack": [
			{"col": "white", "name": "Spear Thrust", "pow": 50, "w": 30}, {"col": "gold", "name": "Wing Buffet", "pow": 30, "w": 20},
			{"col": "purple", "name": "Gale Cry", "stars": 1, "w": 15}, {"col": "blue", "name": "Storm Guard", "w": 10},
			{"col": "red", "w": 25},
		],
	},
]
