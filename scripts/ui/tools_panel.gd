class_name ToolsPanel
extends BasePanel

var _lista: VBoxContainer


func _init() -> void:
	super._init("TOOLS", GameColors.NARANJA, 740.0)


func construir() -> void:
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 8)
	contenido.add_child(_lista)
	GameState.herramienta_cambio.connect(func() -> void: if abierto: refrescar())
	GameState.cash_cambio.connect(func(_v: int) -> void: if abierto: refrescar())


func refrescar() -> void:
	limpiar(_lista)
	for id in GameConfig.ORDEN_HERRAMIENTAS:
		_lista.add_child(_tarjeta(id))
	_lista.add_child(UIKit.etiqueta("More tools (Jackhammer, TNT Launcher...) arrive in later cuts.", 15, Color("#8A909C")))


func _tarjeta(id: String) -> Control:
	var def: Dictionary = GameConfig.HERRAMIENTAS[id]
	var tarjeta := UIKit.tarjeta()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	tarjeta.add_child(fila)
	var icono := PanelContainer.new()
	icono.custom_minimum_size = Vector2(64, 64)
	icono.add_theme_stylebox_override("panel", UIKit.estilo(def["color"], Color("#22252B"), 12, 3))
	fila.add_child(icono)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UIKit.etiqueta("%s   %s" % [def["nombre"], def["tipo"]], 20))
	info.add_child(UIKit.etiqueta("HIT %s   REACH %s   COOLDOWN %.2fs" % [Formulas.abreviar(def["dano"]), str(int(def["alcance"])), def["cooldown"]], 16, Color("#B8BDC8")))
	fila.add_child(info)
	var boton: Button
	if GameState.herramienta_equipada == id:
		boton = UIKit.boton("EQUIPPED", Color("#4C8A5A"), Vector2(170, 44), 16)
		boton.disabled = true
	elif GameState.posee_herramienta(id):
		boton = UIKit.boton("EQUIP", GameColors.NARANJA, Vector2(170, 44), 16)
		boton.pressed.connect(func() -> void:
			GameState.equipar(id)
			Sfx.reproducir("comprar"))
	else:
		boton = UIKit.boton("BUY  $%s" % Formulas.abreviar(def["precio"]), GameColors.AMARILLO.darkened(0.2), Vector2(170, 44), 16)
		boton.disabled = GameState.cash < int(def["precio"])
		boton.pressed.connect(func() -> void:
			if GameState.comprar_herramienta(id):
				GameState.equipar(id)
				Sfx.reproducir("comprar")
			else:
				Sfx.reproducir("error"))
	fila.add_child(boton)
	return tarjeta
