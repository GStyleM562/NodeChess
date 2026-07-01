extends RefCounted
class_name Roster
## MVP starter roster — figures currently produced in Meshy, with explicit
## Meshy-clip -> Tier 1 mappings (verified), stamina, and attack pools (weighted
## segments; every attack type expressed as a wheel). Duplicates allowed in a deck.
## Sheet: docs/Part 2/GDD_v1.0_Part2A_StarterRoster_MVP.md

## Passive catalog: id -> { name, desc }. Figures reference ids in their "passives".
const PASSIVES := {
	"bedrock": {"name": "Bedrock", "desc": "Inmune a empujes, jalones e intercambios."},
	"counter_stone": {"name": "Counter-Stone", "desc": "Al defender y ganar con Azul, empuja al atacante 1 nodo."},
	"hold_the_line": {"name": "Hold the Line", "desc": "Al defender, un empate inmoviliza al atacante 1 turno."},
	"bulwark": {"name": "Bulwark (aura)", "desc": "Tus aliados adyacentes no pueden ser desplazados."},
	"venom_hex": {"name": "Venom Hex", "desc": "Tus victorias Púrpura también aplican Debilitado."},
	"hexstep": {"name": "Hexstep", "desc": "Al defender en empate, retrocede 1 nodo."},
	"arcane_pull": {"name": "Arcane Pull", "desc": "+1 al alcance de tus empujes/jalones/intercambios."},
	"blink": {"name": "Blink", "desc": "Parpadeo: atraviesa a 1 enemigo al saltar (un solo salto; gasta el turno, sin encadenar)."},
	"lunge": {"name": "Lunge", "desc": "Si te moviste 2+ nodos antes de atacar, repites un Fallo."},
	"bloodthirst": {"name": "Bloodthirst", "desc": "Al noquear a un enemigo, te mueves 1 nodo gratis."},
	"aerial": {"name": "Aerial", "desc": "Vuelo: atraviesa figuras al moverse (no da inmunidad a KO por rodear)."},
	"parkour": {"name": "Parkour", "desc": "Puede caminar Y saltar en el mismo turno; el salto termina el turno y no permite atacar."},
	"dive": {"name": "Dive", "desc": "Tras volar 3+ nodos, tu Empuje 1 se vuelve Empuje 2."},
	# --- hidden passives (unlocked on Rank Up) ---
	"venom_aura": {"name": "Venom Aura (oculta)", "desc": "Aura: los enemigos adyacentes tienen −1 stamina."},
	"burning_aura": {"name": "Burning Aura (oculta)", "desc": "Aura: al inicio de tu turno, los enemigos adyacentes quedan Debilitados."},
	"kindling_resolve": {"name": "Kindling Resolve", "desc": "Al subir de rango: limpia tus debuffs (el Rank Up ya lo hace)."},
	"phase": {"name": "Phase", "desc": "Phase: atraviesa figuras al moverse (como Aerial)."},
	"loaded_dice": {"name": "Loaded Dice", "desc": "Una vez por partida: repite una de sus monedas (pendiente de UI)."},
}

# A static var (not const) so custom figures from the Character Creator — and test
# fixtures — can be appended at runtime. Built-in entries below are the MVP roster.
static var FIGURES := [
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
		"passives": ["lunge", "bloodthirst", "parkour"],
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
		"passives": ["arcane_pull", "blink"],
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
		"passives": ["venom_hex", "hexstep"],
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
		# Rank Up (on KO): Venom Witch -> Plague Matron. Stronger plague, unlocks Venom Aura.
		# Future model: res://assets/figures/venom_witch/matron/matron.glb (folder ready).
		"ranks": [
			{
				"name": "Plague Matron", "type": "Ruleta", "stamina": 2,
				"passives": ["venom_hex", "hexstep", "venom_aura"],
				"hidden": ["venom_aura"],
				"attack": [
					{"col": "purple", "name": "Fear Hex", "stars": 1, "fx": "Miedo", "w": 18},
					{"col": "purple", "name": "Plague Cloud", "stars": 2, "fx": "Debilitado", "w": 27},
					{"col": "blue", "name": "Hex Ward", "w": 15}, {"col": "white", "name": "Venom Bolt", "pow": 55, "w": 20},
					{"col": "red", "w": 20},
				],
			},
		],
	},
	{
		"id": "storm_valkyrie", "name": "Storm Valkyrie", "stamina": 4, "type": "Ruleta", # anim incomplete (1 clip)
		"passives": ["aerial", "dive"],
		"glb": "res://assets/figures/storm_valkyrie/Meshy_AI_model_Animation_Walking_withSkin.glb",
		"size": 1.00, "complete": false,
		"clips": {
			"idle": "Armature|Unreal Take|baselayer",
		},
		"attack": [
			{"col": "white", "name": "Spear Thrust", "pow": 50, "w": 30}, {"col": "gold", "name": "Wing Buffet", "pow": 30, "w": 20},
			{"col": "purple", "name": "Gale Cry", "stars": 1, "fx": "Empuje", "disp": "push", "n": 1, "w": 15}, {"col": "blue", "name": "Storm Guard", "w": 10},
			{"col": "red", "w": 25},
		],
	},
	{
		# PLACEHOLDER MODEL (reuses Ironclad's GLB). Real model later in
		# res://assets/figures/emberborn/{squire,champion,warlord}/ (folders ready).
		"id": "emberborn", "name": "Emberborn", "stamina": 3, "type": "Dado (D6)",
		"passives": ["kindling_resolve"], "placeholder": true,
		"glb": "res://assets/figures/ironclad_knight/ironclad_knight.glb",
		"size": 1.00, "complete": true,
		"clips": {
			"idle": "Idle_5", "move_walk": "Walking", "move_run": "Running",
			"attack": "Attack", "attack_heavy": "Axe_Spin_Attack",
			"defend": "Shield_Push_Left", "hit": "Hit_Reaction_1", "ko": "Dead",
		},
		"attack": [
			{"col": "white", "name": "Ember Jab", "pow": 40, "w": 1}, {"col": "white", "name": "Flame Slash", "pow": 60, "w": 1},
			{"col": "red", "w": 1}, {"col": "purple", "name": "Cinder Burst", "stars": 1, "w": 1},
			{"col": "gold", "name": "Blaze Kick", "pow": 30, "w": 1}, {"col": "white", "name": "Fire Slash", "pow": 80, "w": 1},
		],
		"ranks": [
			{
				"name": "Flame Champion", "type": "Dado (D6)", "stamina": 2,
				"passives": ["kindling_resolve"],
				"attack": [
					{"col": "white", "name": "Flame Slash", "pow": 60, "w": 1}, {"col": "white", "name": "Fire Slash", "pow": 80, "w": 1},
					{"col": "purple", "name": "Cinder Burst", "stars": 1, "w": 1}, {"col": "gold", "name": "Inferno Strike", "pow": 40, "w": 1},
					{"col": "white", "name": "Searing Blow", "pow": 100, "w": 1}, {"col": "white", "name": "Blazing Arc", "pow": 90, "w": 1},
				],
			},
			{
				"name": "Infernal Warlord", "type": "Dado (D6)", "stamina": 2,
				"passives": ["kindling_resolve", "burning_aura"], "hidden": ["burning_aura"],
				"attack": [
					{"col": "white", "name": "Fire Slash", "pow": 80, "w": 1}, {"col": "gold", "name": "Hellfire Smash", "pow": 50, "w": 1},
					{"col": "purple", "name": "Molten Curse", "stars": 2, "fx": "Debilitado", "w": 1}, {"col": "white", "name": "Searing Blow", "pow": 100, "w": 1},
					{"col": "gold", "name": "Cataclysm", "pow": 60, "w": 1}, {"col": "white", "name": "Apocalypse Edge", "pow": 120, "w": 1},
				],
			},
		],
	},
	{
		# PLACEHOLDER MODEL (reuses Nightblade's GLB). Real model later in
		# res://assets/figures/coin_trickster/ (folder ready).
		"id": "coin_trickster", "name": "Coin Trickster", "stamina": 3, "type": "Doble Moneda",
		"passives": ["loaded_dice"], "placeholder": true,
		"glb": "res://assets/figures/nightblade/nightblade.glb",
		"size": 0.95, "complete": true,
		"clips": {
			"idle": "Idle_10", "move_walk": "Walking", "move_run": "Running",
			"attack": "Double_Combo_Attack", "attack_heavy": "Triple_Combo_Attack",
			"defend": "Block8", "hit": "Hit_Reaction_1", "ko": "Fall_Dead_from_Abdominal_Injury",
		},
		# Double Coin: two coins (A/B), each with two faces; the combo picks the result.
		"coin_a": [{"col": "white", "name": "Filo", "pow": 60}, {"col": "purple", "name": "Sombra", "stars": 1}],
		"coin_b": [{"col": "gold", "name": "Doblón", "pow": 40}, {"col": "blue", "name": "Guarda"}],
		"attack": [
			{"col": "white", "name": "Jackpot Strike", "pow": 100, "w": 1, "ai": 0, "bi": 0},
			{"col": "blue", "name": "Lucky Guard", "w": 1, "ai": 0, "bi": 1},
			{"col": "gold", "name": "Golden Flick", "pow": 50, "w": 1, "ai": 1, "bi": 0},
			{"col": "purple", "name": "Wild Card", "stars": 2, "w": 1, "ai": 1, "bi": 1},
		],
	},
	# --- New models (Meshy "bunny" set). Minimal placeholder pools; build real
	# characters on these models with the Character Creator. Clip maps auto-detected
	# from each GLB (tools/inspect_glb.gd).
	{
		"id": "heal_bunny", "name": "Heal Bunny", "stamina": 2, "type": "Ruleta", "rarity": "rare",
		"passives": [], "complete": true, "size": 1.0,
		"glb": "res://assets/figures/heal_bunny/Meshy_AI_Meshy_Merged_Animations.glb",
		"clips": {
			"idle": "Idle_6", "move_walk": "Walking", "move_run": "Running",
			"attack": "mage_soell_cast_2", "attack_heavy": "mage_soell_cast_6",
			"defend": "Stand_Dodge", "hit": "Hit_Reaction", "ko": "Knock_Down_1",
		},
		"attack": [
			{"col": "white", "name": "Thump", "pow": 40, "w": 35}, {"col": "blue", "name": "Guard", "w": 25},
			{"col": "purple", "name": "Soothe", "stars": 1, "w": 15}, {"col": "red", "w": 25},
		],
	},
	{
		"id": "mage_bunny", "name": "Mage Bunny", "stamina": 3, "type": "Ruleta", "rarity": "epic",
		"passives": [], "complete": true, "size": 1.0,
		"glb": "res://assets/figures/mage_bunny/Meshy_AI_Meshy_Merged_Animations (1).glb",
		"clips": {
			"idle": "Idle_7", "move_walk": "Walking", "move_run": "Running",
			"attack": "mage_soell_cast_3", "attack_heavy": "mage_soell_cast_4",
			"hit": "Hit_Reaction", "ko": "Knock_Down",
		},
		"attack": [
			{"col": "white", "name": "Spark", "pow": 60, "w": 30}, {"col": "gold", "name": "Arcane", "pow": 40, "w": 20},
			{"col": "purple", "name": "Hex", "stars": 1, "w": 20}, {"col": "red", "w": 30},
		],
	},
	{
		"id": "tank_bunny", "name": "Tank Bunny", "stamina": 1, "type": "Ruleta", "rarity": "rare",
		"passives": [], "complete": true, "size": 1.0,
		"glb": "res://assets/figures/tank_bunny/Meshy_AI_Meshy_Merged_Animations.glb",
		"clips": {
			"idle": "Idle_15", "move_walk": "Walking", "move_run": "Running",
			"attack": "Punch_Combo", "attack_heavy": "Punch_Combo",
			"defend": "Shield_Push_Left", "hit": "Head_Hold_in_Pain", "ko": "Knock_Down",
		},
		"attack": [
			{"col": "blue", "name": "Bulwark", "w": 40}, {"col": "white", "name": "Punch", "pow": 50, "w": 30},
			{"col": "red", "w": 30},
		],
	},
]
