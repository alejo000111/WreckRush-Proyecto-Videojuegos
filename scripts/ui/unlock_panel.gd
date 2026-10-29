class_name UnlockPanel
extends BasePanel

var zona: String = "downtown"
var _texto: Label
var _confirmar: Button


func _init() -> void:
	super._init("UNLOCK ZONE", GameColors.AMARILLO, 560.0)


func construir() -> void:
	_texto = UIKit.etiqueta("", 22, GameColors.BLANCO, HORIZONTAL_ALIGNMENT_CENTER)
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contenido.add_child(_texto)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 14)
	_confirmar = UIKit.boton("UNLOCK", GameColors.AMARILLO.darkened(0.25), Vector2(200, 50), 20)
	_confirmar.pressed.connect(func() -> void:
		if GameState.desbloquear_zona(zona):
			Sfx.reproducir("comprar")
			cerrar()
		else:
			Sfx.reproducir("error"))
	fila.add_child(_confirmar)
	var cancelar := UIKit.boton("NO THANKS", Color("#4A505C"), Vector2(200, 50), 20)
	cancelar.pressed.connect(cerrar)
	fila.add_child(cancelar)
	contenido.add_child(fila)
	GameState.cash_cambio.connect(func(_v: int) -> void: if abierto: refrescar())


func refrescar() -> void:
	var def: Dictionary = GameConfig.ZONAS[zona]
	var costo: int = def["costo"]
	_texto.text = "%s\nobjects pay %s with more HP\n\nCOST  $%s\nYOU HAVE  $%s" % [def["nombre"], def["mult"], Formulas.abreviar(costo), Formulas.abreviar(GameState.cash)]
	_confirmar.disabled = GameState.cash < costo
