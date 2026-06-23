extends RefCounted
class_name Roster
## MVP starter roster — figures currently produced in Meshy, with explicit
## Meshy-clip -> Tier 1 mappings (verified), stamina, and attack pools (weighted
## segments; every attack type expressed as a wheel). Duplicates allowed in a deck.
## Sheet: docs/Part 2/GDD_v1.0_Part2A_StarterRoster_MVP.md

const FIGURES := [
	{
		"id": "stone_golem", "name": "Stone Golem", "stamina": 1,
		"glb": "res://assets/figures/stone_golem/stone_golem.glb",
		"size": 1.30, "complete": true,
		"clips": {
			"idle": "Idle_3", "move_walk": "Walking", "move_run": "Running",
			"attack": "Attack", "attack_heavy": "Axe_Spin_Attack",
			"defend": "Block2", "hit": "Hit_Reaction_1", "ko": "Knock_Down",
		},
		"attack": [
			{"col": "blue", "w": 35}, {"col": "white", "pow": 80, "w": 30},
			{"col": "white", "pow": 50, "w": 15}, {"col": "gold", "pow": 40, "w": 10},
			{"col": "red", "w": 10},
		],
	},
	{
		"id": "ironclad_knight", "name": "Ironclad Knight", "stamina": 2,
		"glb": "res://assets/figures/ironclad_knight/ironclad_knight.glb",
		"size": 1.00, "complete": true,
		"clips": {
			"idle": "Idle_5", "move_walk": "Walking", "move_run": "Running",
			"attack": "Attack", "attack_heavy": "Axe_Spin_Attack",
			"defend": "Shield_Push_Left", "hit": "Hit_Reaction_1", "ko": "Dead",
		},
		"attack": [
			{"col": "white", "pow": 60, "w": 1}, {"col": "white", "pow": 80, "w": 1},
			{"col": "blue", "w": 1}, {"col": "blue", "w": 1},
			{"col": "purple", "stars": 1, "w": 1}, {"col": "gold", "pow": 40, "w": 1},
		],
	},
	{
		"id": "nightblade", "name": "Nightblade", "stamina": 3,
		"glb": "res://assets/figures/nightblade/nightblade.glb",
		"size": 0.95, "complete": true,
		"clips": {
			"idle": "Idle_10", "move_walk": "Walking", "move_run": "Running",
			"attack": "Double_Combo_Attack", "attack_heavy": "Triple_Combo_Attack",
			"defend": "Block8", "hit": "Hit_Reaction_1", "ko": "Fall_Dead_from_Abdominal_Injury",
		},
		"attack": [
			{"col": "white", "pow": 100, "w": 49.5},
			{"col": "purple", "stars": 2, "fx": "Miedo", "w": 49.5}, {"col": "red", "w": 1},
		],
	},
	{
		"id": "rift_mage", "name": "Rift Mage", "stamina": 2,
		"glb": "res://assets/figures/rift_mage/rift_mage.glb",
		"size": 0.95, "complete": true,
		"clips": {
			"idle": "Idle_6", "move_walk": "Walking", "move_run": "Running",
			"attack": "mage_soell_cast_1", "attack_heavy": "mage_soell_cast_4",
			"defend": "Stand_Dodge", "hit": "Hit_Reaction", "ko": "dying_backwards",
		},
		"attack": [
			{"col": "red", "w": 1}, {"col": "white", "pow": 20, "w": 2},
			{"col": "purple", "stars": 1, "w": 3}, {"col": "blue", "w": 4},
			{"col": "gold", "pow": 30, "w": 5}, {"col": "white", "pow": 50, "w": 6},
			{"col": "purple", "stars": 2, "w": 5}, {"col": "blue", "w": 4},
			{"col": "gold", "pow": 40, "w": 3}, {"col": "white", "pow": 80, "w": 2},
			{"col": "purple", "stars": 3, "w": 1},
		],
	},
	{
		"id": "venom_witch", "name": "Venom Witch", "stamina": 2,
		"glb": "res://assets/figures/venom_witch/witch/witch.glb",
		"size": 1.00, "complete": true,
		"clips": {
			"idle": "Idle_9", "move_walk": "Walking", "move_run": "Running",
			"attack": "mage_soell_cast_4", "attack_heavy": "mage_soell_cast_6",
			"defend": "Block10", "hit": "Hit_Reaction_to_Waist", "ko": "Dead",
		},
		"attack": [
			{"col": "purple", "stars": 1, "fx": "Miedo", "w": 25}, {"col": "purple", "stars": 2, "fx": "Debilitado", "w": 15},
			{"col": "blue", "w": 15}, {"col": "white", "pow": 40, "w": 20},
			{"col": "red", "w": 25},
		],
	},
	{
		"id": "storm_valkyrie", "name": "Storm Valkyrie", "stamina": 4, # anim incomplete (1 clip)
		"glb": "res://assets/figures/storm_valkyrie/Meshy_AI_model_Animation_Walking_withSkin.glb",
		"size": 1.00, "complete": false,
		"clips": {
			"idle": "Armature|Unreal Take|baselayer",
		},
		"attack": [
			{"col": "white", "pow": 50, "w": 30}, {"col": "gold", "pow": 30, "w": 20},
			{"col": "purple", "stars": 1, "w": 15}, {"col": "blue", "w": 10},
			{"col": "red", "w": 25},
		],
	},
]
