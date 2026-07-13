extends SceneTree
## Lanza el 🤖 MODO ROBOT completo desde línea de comandos (PC/CI) y cierra con
## exit code = fallos. NECESITA ventana (las partidas renderizan de verdad):
##   Godot --path game --rendering-driver opengl3 --script res://tools/robot_boot.gd

func _initialize() -> void:
	AutoTester.auto_quit = true
	AutoTester.start(self, false)
