class_name Hud
extends CanvasLayer

signal viaje_isla_pedido

var jugador: Player
var paneles: Dictionary = {}

var _nivel: Label
var _xp: ProgressBar
var _cash: Label
var _scrap: Label
var _gasta: Label
var _meta_texto: Label
var _meta_barra: ProgressBar
var _punto_mejoras: Panel
var _boton_mejoras: Button
var _contenedor_jefe: PanelContainer
var _jefe_nombre: Label
var _jefe_barra: ProgressBar
var _jefe_objetivo: Label
var _toasts: VBoxContainer
var _aviso: PanelContainer
var _aviso_texto: Label
var _aviso_barra: ProgressBar
var _casillas: Array[Button] = []
var _vida: ProgressBar
var _muerte: ColorRect
var _muerte_texto: Label
var _tutorial: PanelContainer
var _tutorial_titulo: Label
var _tutorial_texto: Label
var _tutorial_paso: Label
var _victoria: Control
var _victoria_texto: Label
var _fps: Label


func _ready() -> void:
	layer = 5
	_construir_perfil()
	_construir_menu()
	_construir_centro()
	_construir_inferior()
	_construir_tutorial()
	_construir_superposiciones()
	_construir_paneles()
	GameState.cash_cambio.connect(func(_v: int) -> void: _refrescar_recursos())
	GameState.scrap_cambio.connect(func(_v: int, _c: int) -> void: _refrescar_recursos())
	GameState.xp_cambio.connect(func(_x: int, _r: int, _n: int) -> void: _refrescar_perfil())
	GameState.nivel_subio.connect(func(_n: int) -> void: _refrescar_perfil())
	GameState.mejora_comprada.connect(func(_i: String, _n: int) -> void: _refrescar_recursos())
	GameState.herramienta_cambio.connect(_refrescar_casillas)
	GameState.toast.connect(mostrar_toast)
	GameState.prompt_cambio.connect(_al_cambiar_prompt)
	GameState.boss_estado.connect(_al_estado_jefe)
	GameState.tutorial_cambio.connect(func(_p: int) -> void: _refrescar_tutorial())
	GameState.jefe_vencido.connect(_mostrar_victoria)
	_refrescar_todo()


func _process(_delta: float) -> void:
	var meta := GameState.siguiente_meta()
	_meta_texto.text = _texto_meta(meta)
	_meta_barra.value = clampf(float(meta["actual"]) / maxf(float(meta["meta"]), 1.0), 0.0, 1.0)
	_punto_mejoras.visible = GameState.hay_mejora_asequible()
	_gasta.visible = GameState.bolsa_llena()
	_fps.text = "%d FPS" % Engine.get_frames_per_second()
	if jugador != null:
		_vida.visible = jugador.salud < GameConfig.VIDA_JUGADOR and not jugador.muerto
		_vida.value = jugador.salud / GameConfig.VIDA_JUGADOR


func _texto_meta(meta: Dictionary) -> String:
	if meta["listo"]:
		return "READY: %s" % meta["texto"]
	return "NEXT: %s  %s/%s" % [meta["texto"], Formulas.abreviar(meta["actual"]), Formulas.abreviar(meta["meta"])]


func _construir_perfil() -> void:
	var caja := PanelContainer.new()
	caja.position = Vector2(16, 14)
	caja.add_theme_stylebox_override("panel", UIKit.estilo(Color(0.17, 0.18, 0.21, 0.88), GameColors.NARANJA, 12, 3, 10))
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	caja.add_child(fila)
	_nivel = UIKit.etiqueta("LV 1", 24, GameColors.AMARILLO)
	fila.add_child(_nivel)
	var col := VBoxContainer.new()
	col.add_child(UIKit.etiqueta("WRECKER", 17))
	_xp = UIKit.barra(GameColors.NARANJA, Vector2(170, 12))
	col.add_child(_xp)
	fila.add_child(col)
	add_child(caja)


func _construir_menu() -> void:
	var col := VBoxContainer.new()
	col.position = Vector2(16, 98)
	col.add_theme_constant_override("separation", 8)
	add_child(col)
	_boton_mejoras = _boton_menu(col, "UPGRADES [U]", GameColors.AMARILLO.darkened(0.25), "upgrades")
	_punto_mejoras = UIKit.punto_rojo()
	_punto_mejoras.position = Vector2(-6, -6)
	_boton_mejoras.add_child(_punto_mejoras)
	_boton_menu(col, "TOOLS [T]", GameColors.NARANJA.darkened(0.1), "tools")
	_boton_menu(col, "ISLANDS", GameColors.ROJO.darkened(0.1), "islands")
	_boton_menu(col, "SETTINGS [TAB]", GameColors.CIAN.darkened(0.45), "settings")


func _boton_menu(padre: Control, texto: String, color: Color, panel: String) -> Button:
	var b := UIKit.boton(texto, color, Vector2(190, 44), 17)
	b.pressed.connect(func() -> void: abrir_panel(panel))
	padre.add_child(b)
	return b


func _construir_centro() -> void:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_CENTER_TOP)
	raiz.anchor_left = 0.5
	raiz.anchor_right = 0.5
	raiz.offset_left = -260
	raiz.offset_right = 260
	raiz.offset_top = 12
	raiz.add_theme_constant_override("separation", 6)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	var recursos := HBoxContainer.new()
	recursos.alignment = BoxContainer.ALIGNMENT_CENTER
	recursos.add_theme_constant_override("separation", 12)
	recursos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cash = _pildora(recursos, "$ 0", GameColors.AMARILLO)
	_scrap = _pildora(recursos, "0 / 500", GameColors.NARANJA)
	_gasta = UIKit.etiqueta("SPEND!", 18, GameColors.ROJO)
	recursos.add_child(_gasta)
	raiz.add_child(recursos)
	var meta := PanelContainer.new()
	meta.add_theme_stylebox_override("panel", UIKit.estilo(Color(0.17, 0.18, 0.21, 0.85), GameColors.AMARILLO.darkened(0.3), 10, 2, 6))
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var metacol := VBoxContainer.new()
	_meta_texto = UIKit.etiqueta("", 17, GameColors.AMARILLO, HORIZONTAL_ALIGNMENT_CENTER)
	metacol.add_child(_meta_texto)
	_meta_barra = UIKit.barra(GameColors.AMARILLO, Vector2(0, 10))
	metacol.add_child(_meta_barra)
	meta.add_child(metacol)
	raiz.add_child(meta)
	_contenedor_jefe = PanelContainer.new()
	_contenedor_jefe.visible = false
	_contenedor_jefe.add_theme_stylebox_override("panel", UIKit.estilo(Color(0.2, 0.08, 0.08, 0.9), GameColors.ROJO, 10, 3, 8))
	_contenedor_jefe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var jefecol := VBoxContainer.new()
	_jefe_nombre = UIKit.etiqueta("SCRAP COLOSSUS", 20, GameColors.ROJO, HORIZONTAL_ALIGNMENT_CENTER)
	jefecol.add_child(_jefe_nombre)
	_jefe_barra = UIKit.barra(GameColors.ROJO, Vector2(0, 18))
	jefecol.add_child(_jefe_barra)
	_jefe_objetivo = UIKit.etiqueta("", 16, GameColors.BLANCO, HORIZONTAL_ALIGNMENT_CENTER)
	jefecol.add_child(_jefe_objetivo)
	_contenedor_jefe.add_child(jefecol)
	raiz.add_child(_contenedor_jefe)
	_toasts = VBoxContainer.new()
	_toasts.add_theme_constant_override("separation", 4)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(_toasts)


func _pildora(padre: Control, texto: String, color: Color) -> Label:
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", UIKit.estilo(Color(0.12, 0.13, 0.16, 0.9), color, 18, 3, 8))
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var e := UIKit.etiqueta(texto, 24, color)
	caja.add_child(e)
	padre.add_child(caja)
	return e


func _construir_inferior() -> void:
	var barra := HBoxContainer.new()
	barra.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	barra.anchor_left = 0.5
	barra.anchor_right = 0.5
	barra.offset_left = -170
	barra.offset_right = 170
	barra.offset_top = -86
	barra.offset_bottom = -16
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	barra.add_theme_constant_override("separation", 8)
	add_child(barra)
	for i in 3:
		var b := UIKit.boton("", Color("#2B2F36"), Vector2(104, 62), 14)
		b.pressed.connect(func() -> void:
			if i < GameConfig.ORDEN_HERRAMIENTAS.size():
				GameState.equipar(GameConfig.ORDEN_HERRAMIENTAS[i]))
		barra.add_child(b)
		_casillas.append(b)
	_aviso = PanelContainer.new()
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.anchor_left = 0.5
	_aviso.anchor_right = 0.5
	_aviso.offset_left = -190
	_aviso.offset_right = 190
	_aviso.offset_top = -156
	_aviso.offset_bottom = -100
	_aviso.visible = false
	_aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aviso.add_theme_stylebox_override("panel", UIKit.estilo(Color(0.12, 0.13, 0.16, 0.92), GameColors.AMARILLO, 12, 3, 8))
	var avisocol := VBoxContainer.new()
	_aviso_texto = UIKit.etiqueta("", 20, GameColors.BLANCO, HORIZONTAL_ALIGNMENT_CENTER)
	avisocol.add_child(_aviso_texto)
	_aviso_barra = UIKit.barra(GameColors.AMARILLO, Vector2(0, 8))
	avisocol.add_child(_aviso_barra)
	_aviso.add_child(avisocol)
	add_child(_aviso)
	var wreck := UIKit.boton("WRECK", GameColors.NARANJA, Vector2(170, 110), 30)
	wreck.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	wreck.anchor_left = 1.0
	wreck.anchor_top = 1.0
	wreck.anchor_right = 1.0
	wreck.anchor_bottom = 1.0
	wreck.offset_left = -196
	wreck.offset_top = -136
	wreck.offset_right = -26
	wreck.offset_bottom = -26
	wreck.button_down.connect(func() -> void: GameState.boton_wreck = true)
	wreck.button_up.connect(func() -> void: GameState.boton_wreck = false)
	add_child(wreck)
	_vida = UIKit.barra(GameColors.ROJO, Vector2(260, 18))
	_vida.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_vida.anchor_top = 1.0
	_vida.anchor_bottom = 1.0
	_vida.offset_left = 20
	_vida.offset_top = -44
	_vida.offset_right = 280
	_vida.offset_bottom = -26
	_vida.max_value = 1.0
	_vida.visible = false
	add_child(_vida)
	_fps = UIKit.etiqueta("", 13, Color("#8A909C"), HORIZONTAL_ALIGNMENT_RIGHT)
	_fps.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_fps.anchor_left = 1.0
	_fps.anchor_right = 1.0
	_fps.offset_left = -90
	_fps.offset_top = 4
	_fps.offset_right = -8
	add_child(_fps)


func _construir_tutorial() -> void:
	_tutorial = PanelContainer.new()
	_tutorial.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tutorial.anchor_left = 1.0
	_tutorial.anchor_right = 1.0
	_tutorial.offset_left = -330
	_tutorial.offset_right = -16
	_tutorial.offset_top = 30
	_tutorial.add_theme_stylebox_override("panel", UIKit.estilo(Color(0.17, 0.18, 0.21, 0.92), GameColors.AMARILLO, 12, 3, 12))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	_tutorial_paso = UIKit.etiqueta("", 14, Color("#8A909C"))
	col.add_child(_tutorial_paso)
	_tutorial_titulo = UIKit.etiqueta("", 22, GameColors.AMARILLO)
	col.add_child(_tutorial_titulo)
	_tutorial_texto = UIKit.etiqueta("", 16)
	_tutorial_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_texto.custom_minimum_size = Vector2(290, 0)
	col.add_child(_tutorial_texto)
	var saltar := UIKit.boton("SKIP", Color("#4A505C"), Vector2(90, 32), 14)
	saltar.pressed.connect(GameState.saltar_tutorial)
	col.add_child(saltar)
	_tutorial.add_child(col)
	add_child(_tutorial)


func _construir_superposiciones() -> void:
	_muerte = ColorRect.new()
	_muerte.color = Color(0.3, 0.02, 0.02, 0.55)
	_muerte.set_anchors_preset(Control.PRESET_FULL_RECT)
	_muerte.visible = false
	_muerte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_muerte_texto = UIKit.etiqueta("", 46, GameColors.BLANCO, HORIZONTAL_ALIGNMENT_CENTER)
	_muerte_texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	_muerte_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_muerte.add_child(_muerte_texto)
	add_child(_muerte)
	_victoria = Control.new()
	_victoria.set_anchors_preset(Control.PRESET_FULL_RECT)
	_victoria.visible = false
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.6)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_victoria.add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_victoria.add_child(centro)
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", UIKit.estilo(GameColors.GRIS_OSCURO, GameColors.AMARILLO, 18, 5, 26))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.add_child(UIKit.etiqueta("SCRAP COLOSSUS DEFEATED", 36, GameColors.AMARILLO, HORIZONTAL_ALIGNMENT_CENTER))
	_victoria_texto = UIKit.etiqueta("", 22, GameColors.BLANCO, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_victoria_texto)
	var seguir := UIKit.boton("CONTINUE", GameColors.NARANJA, Vector2(240, 52), 22)
	seguir.pressed.connect(func() -> void:
		_victoria.visible = false
		GameState.cerrar_panel())
	col.add_child(seguir)
	tarjeta.add_child(col)
	centro.add_child(tarjeta)
	add_child(_victoria)


func _construir_paneles() -> void:
	paneles["upgrades"] = UpgradesPanel.new()
	paneles["tools"] = ToolsPanel.new()
	paneles["settings"] = SettingsPanel.new()
	paneles["unlock_downtown"] = UnlockPanel.new()
	var islas := IslandsPanel.new()
	islas.viajar_pedido.connect(func() -> void: viaje_isla_pedido.emit())
	paneles["islands"] = islas
	for panel in paneles.values():
		add_child(panel)


func abrir_panel(nombre: String) -> void:
	if not paneles.has(nombre):
		return
	for otro in paneles.values():
		if otro != paneles[nombre] and otro.abierto:
			otro.cerrar()
	paneles[nombre].abrir()
	if nombre == "upgrades" and GameState.tutorial_paso == 3:
		GameState.toast.emit("BUY DAMAGE", "good")


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("open_upgrades"):
		_alternar("upgrades")
	elif evento.is_action_pressed("open_tools"):
		_alternar("tools")
	elif evento.is_action_pressed("open_settings"):
		_alternar("settings")


func _alternar(nombre: String) -> void:
	if paneles[nombre].abierto:
		paneles[nombre].cerrar()
	else:
		abrir_panel(nombre)


func mostrar_toast(texto: String, tipo: String = "neutral") -> void:
	var color := GameColors.BLANCO
	var borde := Color("#8A909C")
	if tipo == "good":
		color = Color("#9CF0A8")
		borde = Color("#4C8A5A")
	elif tipo == "bad":
		color = Color("#FF9A9A")
		borde = GameColors.ROJO
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", UIKit.estilo(Color(0.1, 0.11, 0.14, 0.92), borde, 10, 2, 6))
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(UIKit.etiqueta(texto, 20, color, HORIZONTAL_ALIGNMENT_CENTER))
	_toasts.add_child(caja)
	while _toasts.get_child_count() > 4:
		_toasts.get_child(0).queue_free()
		_toasts.remove_child(_toasts.get_child(0))
	var t := caja.create_tween()
	t.tween_interval(2.0)
	t.tween_property(caja, "modulate:a", 0.0, 0.5)
	t.tween_callback(caja.queue_free)


func _refrescar_todo() -> void:
	_refrescar_recursos()
	_refrescar_perfil()
	_refrescar_casillas()
	_refrescar_tutorial()


func _refrescar_recursos() -> void:
	_cash.text = "$ %s" % Formulas.abreviar(GameState.cash)
	_scrap.text = "%s / %s" % [Formulas.abreviar(GameState.scrap), Formulas.abreviar(GameState.capacidad_bolsa())]


func _refrescar_perfil() -> void:
	_nivel.text = "LV %d" % GameState.nivel
	_xp.value = float(GameState.xp) / float(GameState.xp_requerido())


func _refrescar_casillas() -> void:
	for i in _casillas.size():
		var b := _casillas[i]
		if i >= GameConfig.ORDEN_HERRAMIENTAS.size():
			b.text = "%d\n--" % (i + 1)
			b.disabled = true
			continue
		var id: String = GameConfig.ORDEN_HERRAMIENTAS[i]
		var def: Dictionary = GameConfig.HERRAMIENTAS[id]
		var tiene := GameState.posee_herramienta(id)
		b.disabled = not tiene
		b.text = "%d\n%s" % [i + 1, String(def["nombre"]).split(" ")[0] if tiene else "LOCKED"]
		var activo := GameState.herramienta_equipada == id
		b.add_theme_stylebox_override("normal", UIKit.estilo(Color("#2B2F36"), GameColors.AMARILLO if activo else Color("#22252B"), 10, 4 if activo else 2))
		b.add_theme_stylebox_override("disabled", UIKit.estilo(Color("#23262C"), Color("#1C1E23"), 10, 2))


func _al_cambiar_prompt(texto: String, progreso: float) -> void:
	_aviso.visible = texto != ""
	_aviso_texto.text = "[E]  " + texto
	_aviso_barra.visible = progreso > 0.0
	_aviso_barra.value = progreso


func _al_estado_jefe(datos: Dictionary) -> void:
	_contenedor_jefe.visible = datos["activo"] and jugador != null and jugador.global_position.z > 1000.0
	if not _contenedor_jefe.visible:
		return
	_jefe_barra.value = datos["proporcion"]
	_jefe_objetivo.text = datos["objetivo"]


func _refrescar_tutorial() -> void:
	_tutorial.visible = not GameState.tutorial_completo
	if GameState.tutorial_completo:
		return
	var paso := mini(GameState.tutorial_paso, GameConfig.TUTORIAL.size() - 1)
	var datos: Dictionary = GameConfig.TUTORIAL[paso]
	_tutorial_paso.text = "STEP %d / %d" % [paso + 1, GameConfig.TUTORIAL.size()]
	_tutorial_titulo.text = datos["titulo"]
	_tutorial_texto.text = datos["texto"]


func mostrar_muerte(restante: float) -> void:
	_muerte.visible = true
	_muerte_texto.text = "YOU WERE CRUSHED\nRESPAWN IN %d" % int(ceil(restante))


func ocultar_muerte() -> void:
	_muerte.visible = false


func _mostrar_victoria(resultado: Dictionary) -> void:
	await get_tree().create_timer(1.2).timeout
	var lineas := "+$%s   +%s SCRAP   +%d XP" % [Formulas.abreviar(resultado["cash"]), Formulas.abreviar(resultado["scrap"]), int(resultado["xp"])]
	if int(resultado["scrap_perdido"]) > 0:
		lineas += "\n(bag full: %s SCRAP lost)" % Formulas.abreviar(resultado["scrap_perdido"])
	if resultado["plano"] != "":
		lineas += "\nNEW BLUEPRINT: %s" % String(resultado["plano"]).replace("_", " ")
	lineas += "\n\nFIGHT TIME %s   BEST %s\nTOTAL PLAY TIME %s" % [Formulas.formato_tiempo(resultado["tiempo"]), Formulas.formato_tiempo(resultado["mejor_tiempo"]), Formulas.formato_tiempo(resultado["tiempo_total"])]
	_victoria_texto.text = lineas
	_victoria.visible = true
	GameState.abrir_panel()
