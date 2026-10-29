class_name DevTools
extends Node

var main: Node


func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return
	match evento.physical_keycode:
		KEY_F1:
			GameState.agregar_cash(100000)
			GameState.toast.emit("DEV: +100K CASH", "good")
		KEY_F2:
			GameState.agregar_xp(GameState.xp_requerido())
		KEY_F3:
			GameState.agregar_scrap(100000)
		KEY_F4:
			if main != null:
				main.viajar_a_isla()
