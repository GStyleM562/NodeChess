extends RefCounted
class_name Roster
## MVP starter roster — figures currently produced in Meshy, with explicit
## Meshy-clip -> Tier 1 mappings (verified from each GLB). Duplicates are
## allowed in a deck (few figures for now), per design.
## Sheet: docs/Part 2/GDD_v1.0_Part2A_StarterRoster_MVP.md

const FIGURES := [
	{
		"id": "stone_golem", "name": "Stone Golem",
		"glb": "res://assets/figures/stone_golem/stone_golem.glb",
		"size": 1.30, "complete": true,
		"clips": {
			"idle": "Idle_3", "move_walk": "Walking", "move_run": "Running",
			"attack": "Attack", "attack_heavy": "Axe_Spin_Attack",
			"defend": "Block2", "hit": "Hit_Reaction_1", "ko": "Knock_Down",
		},
	},
	{
		"id": "ironclad_knight", "name": "Ironclad Knight",
		"glb": "res://assets/figures/ironclad_knight/ironclad_knight.glb",
		"size": 1.00, "complete": true,
		"clips": {
			"idle": "Idle_5", "move_walk": "Walking", "move_run": "Running",
			"attack": "Attack", "attack_heavy": "Axe_Spin_Attack",
			"defend": "Shield_Push_Left", "hit": "Hit_Reaction_1", "ko": "Dead",
		},
	},
	{
		"id": "nightblade", "name": "Nightblade",
		"glb": "res://assets/figures/nightblade/nightblade.glb",
		"size": 0.95, "complete": true,
		"clips": {
			"idle": "Idle_10", "move_walk": "Walking", "move_run": "Running",
			"attack": "Double_Combo_Attack", "attack_heavy": "Triple_Combo_Attack",
			"defend": "Block8", "hit": "Hit_Reaction_1", "ko": "Fall_Dead_from_Abdominal_Injury",
		},
	},
	{
		"id": "rift_mage", "name": "Rift Mage",
		"glb": "res://assets/figures/rift_mage/rift_mage.glb",
		"size": 0.95, "complete": true,
		"clips": {
			"idle": "Idle_6", "move_walk": "Walking", "move_run": "Running",
			"attack": "mage_soell_cast_1", "attack_heavy": "mage_soell_cast_4",
			"defend": "Stand_Dodge", "hit": "Hit_Reaction", "ko": "dying_backwards",
		},
	},
	{
		"id": "venom_witch", "name": "Venom Witch",
		"glb": "res://assets/figures/venom_witch/witch/witch.glb",
		"size": 1.00, "complete": true,
		"clips": {
			"idle": "Idle_9", "move_walk": "Walking", "move_run": "Running",
			"attack": "mage_soell_cast_4", "attack_heavy": "mage_soell_cast_6",
			"defend": "Block10", "hit": "Hit_Reaction_to_Waist", "ko": "Dead",
		},
	},
	{
		"id": "storm_valkyrie", "name": "Storm Valkyrie", # anim set incomplete (1 clip)
		"glb": "res://assets/figures/storm_valkyrie/Meshy_AI_model_Animation_Walking_withSkin.glb",
		"size": 1.00, "complete": false,
		"clips": {
			"idle": "Armature|Unreal Take|baselayer",
		},
	},
]
