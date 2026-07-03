extends Node
## Autoload. Runs once at app start, before the main scene loads, so player-authored
## figures (Character Creator) are merged into Roster.FIGURES and show up everywhere
## (Dex, Deck Builder, matches).

func _ready() -> void:
	CustomFigures.merge_into_roster()
	Loadout.load()   # restore saved team + modifiers + map (after customs are merged)
	# Android: el botón ATRÁS ya no cierra el juego; cada pantalla decide qué hacer
	# (el menú principal abre la Configuración — ver MainMenu._notification).
	get_tree().quit_on_go_back = false
