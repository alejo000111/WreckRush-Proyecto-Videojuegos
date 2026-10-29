class_name UpgradesPanel
extends BasePanel

var _filtro: String = "all"
var _lista: VBoxContainer
var _pestanas: Dictionary = {}


func _init() -> void:
	super._init("UPGRADES", GameColors.AMARILLO, 780.0)


func construir() -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	for id in ["all", "cash", "scrap"]:
		var b := UIKit.boton(id.to_upper(), GameColors.GRIS_OSCURO.lightened(0.15), Vector2(110, 38), 16)
		b.pressed.connect(func() -> void:
			_filtro = id
			refrescar())
		fila.add_child(b)
		_pestanas[id] = b
	contenido.add_child(fila)
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 8)
	contenido.add_child(_lista)
	GameState.cash_cambio.connect(func(_v: int) -> void: if abierto: refrescar())
	GameState.scrap_cambio.connect(func(_v: int, _c: int) -> void: if abierto: refrescar())


func refrescar() -> void:
	limpiar(_lista)
	for id in _pestanas:
		var activo: bool = id == _filtro
		_pestanas[id].add_theme_stylebox_override("normal", UIKit.estilo(GameColors.AMARILLO if activo else Color("#3C414B"), Color("#22252B"), 10, 3))
	for id in GameConfig.ORDEN_MEJORAS:
		var def: Dictionary = GameConfig.MEJORAS[id]
		if _filtro != "all" and def["moneda"] != _filtro:
			continue
		_lista.add_child(_tarjeta(id, def))


func _valor_texto(id: String, nivel: int) -> String:
	match id:
		"damage":
			return "x%.2f" % Formulas.multiplicador_dano(nivel)
		"attack_speed":
			return "%.3fs" % Formulas.cooldown_ataque(0.45, nivel)
		"critical_chance":
			return "%d%%" % int(round(Formulas.probabilidad_critico(nivel) * 100.0))
		"magnet_range":
			return "%.1f studs" % Formulas.radio_iman(nivel)
		"move_speed":
			return "%.1f" % Formulas.velocidad_caminar(nivel)
		"scrap_capacity":
			return Formulas.abreviar(Formulas.capacidad_bolsa(nivel))
	return str(nivel)


func _tarjeta(id: String, def: Dictionary) -> Control:
	var nivel := GameState.nivel_mejora(id)
	var estado := GameState.estado_mejora(id)
	var moneda_color := GameColors.AMARILLO if def["moneda"] == "cash" else GameColors.NARANJA
	var tarjeta := UIKit.tarjeta()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	tarjeta.add_child(fila)
	var icono := PanelContainer.new()
	icono.custom_minimum_size = Vector2(64, 64)
	icono.add_theme_stylebox_override("panel", UIKit.estilo(moneda_color.darkened(0.55), moneda_color, 12, 3))
	icono.add_child(UIKit.etiqueta(def["icono"], 18, moneda_color, HORIZONTAL_ALIGNMENT_CENTER))
	fila.add_child(icono)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UIKit.etiqueta("%s   LV %d/%d" % [def["nombre"], nivel, int(def["max"])], 20))
	var siguiente := _valor_texto(id, nivel + 1) if nivel < int(def["max"]) else "MAX"
	info.add_child(UIKit.etiqueta("%s  >  %s" % [_valor_texto(id, nivel), siguiente], 16, Color("#B8BDC8")))
	fila.add_child(info)
	var botones := VBoxContainer.new()
	var comprar: Button
	if nivel >= int(def["max"]):
		comprar = UIKit.boton("MAXED", Color("#5A5F6A"), Vector2(170, 40), 16)
		comprar.disabled = true
	else:
		var etiqueta_precio := "%s %s" % [Formulas.abreviar(GameState.precio_mejora(id)), "CASH" if def["moneda"] == "cash" else "SCRAP"]
		comprar = UIKit.boton("BUY  " + etiqueta_precio, moneda_color.darkened(0.15), Vector2(170, 40), 16)
		comprar.disabled = not estado["ok"]
		if not estado["ok"] and estado["razon"] == "BAG TOO SMALL":
			comprar.text = "BAG TOO SMALL"
		comprar.pressed.connect(func() -> void: _comprar(id, false))
	botones.add_child(comprar)
	var maximo := UIKit.boton("MAX", Color("#4A505C"), Vector2(170, 30), 14)
	maximo.disabled = not estado["ok"]
	maximo.pressed.connect(func() -> void: _comprar(id, true))
	botones.add_child(maximo)
	fila.add_child(botones)
	return tarjeta


func _comprar(id: String, todo: bool) -> void:
	var comprados := 0
	if todo:
		comprados = GameState.comprar_mejora_maximo(id)
	elif GameState.comprar_mejora(id)["ok"]:
		comprados = 1
	if comprados > 0:
		Sfx.reproducir("comprar")
	else:
		Sfx.reproducir("error")
	refrescar()
