class_name IslandsPanel
extends BasePanel

signal viajar_pedido

var _cuerpo: VBoxContainer


func _init() -> void:
	super._init("BOSS ISLANDS", GameColors.ROJO, 720.0)


func construir() -> void:
	_cuerpo = VBoxContainer.new()
	_cuerpo.add_theme_constant_override("separation", 8)
	contenido.add_child(_cuerpo)


func refrescar() -> void:
	limpiar(_cuerpo)
	var isla: Dictionary = GameConfig.ISLA_JEFE
	var requisitos := GameState.requisitos_isla()
	var tarjeta := UIKit.tarjeta()
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	tarjeta.add_child(caja)
	var estado := "COMPLETED" if GameState.jefe_victorias > 0 else ("READY TO ENTER" if requisitos["ok"] else "LOCKED")
	var color_estado := GameColors.AMARILLO if estado == "COMPLETED" else (Color("#6BD17B") if requisitos["ok"] else GameColors.ROJO)
	caja.add_child(UIKit.etiqueta("1 · %s" % isla["nombre"], 26))
	caja.add_child(UIKit.etiqueta(estado, 18, color_estado))
	caja.add_child(UIKit.etiqueta("Boss: %s   Recommended level %d" % [isla["jefe"], int(isla["nivel_requerido"])], 17, Color("#B8BDC8")))
	caja.add_child(UIKit.etiqueta("Break its 4 armor plates, then hit the exposed core for %ds." % int(GameConfig.JEFE["ventana_expuesta"]), 16, Color("#B8BDC8")))
	caja.add_child(UIKit.separador(4))
	for r in requisitos["lista"]:
		var fila := UIKit.etiqueta("%s  %s" % ["[OK]" if r["ok"] else "[  ]", r["texto"]], 18, Color("#6BD17B") if r["ok"] else GameColors.ROJO)
		caja.add_child(fila)
	var premio: Dictionary = GameConfig.JEFE["recompensa"]
	caja.add_child(UIKit.separador(4))
	caja.add_child(UIKit.etiqueta("REWARD  $%s   %s SCRAP   %d XP   First win: %s blueprint" % [Formulas.abreviar(premio["cash"]), Formulas.abreviar(premio["scrap"]), int(premio["xp"]), "SCRAP CLEAVER"], 16, GameColors.AMARILLO))
	if GameState.jefe_victorias > 0:
		caja.add_child(UIKit.etiqueta("WINS %d   BEST TIME %s" % [GameState.jefe_victorias, Formulas.formato_tiempo(GameState.mejor_tiempo_jefe)], 16, Color("#B8BDC8")))
	var viaje := UIKit.boton("TRAVEL TO %s" % isla["nombre"] if requisitos["ok"] else "LOCKED", GameColors.ROJO, Vector2(260, 48), 20)
	viaje.disabled = not requisitos["ok"]
	viaje.pressed.connect(func() -> void:
		cerrar()
		viajar_pedido.emit())
	caja.add_child(viaje)
	_cuerpo.add_child(tarjeta)
