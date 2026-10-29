@tool
class_name CityWorld
extends Node3D

signal panel_pedido(nombre: String)
signal viaje_pedido(destino: String)

const SEPARACION := 240.0
const PUNTO_PLAZA := Vector3(0, 3, 55)
const RADIO_PORTAL := 4.0
const ESPERA_PORTAL := 1.5
const RADIO_RESERVA_COLOSO := 46.0

const PUNTOS_ENTRADA := {
	"scrap_yard": Vector3(0, 3, -150),
	"downtown": Vector3(160, 3, -240),
	"industrial": Vector3(160, 3, 0),
}

var puertas: Dictionary = {}
var colosos: Array[Coloso] = []
var destructibles: Array[Destructible] = []

var _portales: Array = []
var _jugador: Node3D
var _espera: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20261013
	_construir_suelos()
	_construir_limites()
	_construir_plaza()
	_construir_scrap_yard()
	_construir_downtown()
	_construir_industrial()
	_construir_bloques_bloqueados()
	_construir_horizonte()
	if Engine.is_editor_hint():
		return
	GameState.zona_desbloqueada.connect(_al_desbloquear)
	for id in puertas:
		if GameState.zona_abierta(id):
			_abrir_puerta(id, false)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_espera = maxf(_espera - delta, 0.0)
	if _jugador == null or not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("player") as Node3D
		return
	if _espera > 0.0 or _jugador.global_position.y > 2.5:
		return
	for portal in _portales:
		var d := Vector2(_jugador.global_position.x - portal["pos"].x, _jugador.global_position.z - portal["pos"].z).length()
		if d <= RADIO_PORTAL:
			_espera = ESPERA_PORTAL
			viaje_pedido.emit(portal["destino"])
			return


func coloso_de(zona: String) -> Coloso:
	for c in colosos:
		if GameConfig.COLOSOS[c.numero - 1]["zona"] == zona:
			return c
	return null


func _construir_suelos() -> void:
	var base := Formas.caja_solida(self, Vector3(900, 2, 900), Vector3(0, -1, 0), Color.BLACK, 1, false)
	base.name = "SueloBase"
	var exterior := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(5200, 5200)
	exterior.mesh = plano
	exterior.material_override = Formas.material(Color("#7A3A26"), 1.0)
	exterior.position = Vector3(0, -0.6, 0)
	add_child(exterior)
	var calles := MeshInstance3D.new()
	var plano_calles := PlaneMesh.new()
	plano_calles.size = Vector2(780, 780)
	calles.mesh = plano_calles
	calles.material_override = Formas.material_suelo(Color("#23262C"), 12.0)
	calles.position = Vector3(0, 0.01, 0)
	add_child(calles)
	_suelo_zona(Vector2(0, 0), Color("#2B2F36"), 1.0)
	for id in GameConfig.ORDEN_ZONAS:
		_suelo_zona(GameConfig.ZONAS[id]["centro"], GameConfig.ZONAS[id]["suelo"], 0.0)


func _suelo_zona(centro: Vector2, color: Color, puntos: float) -> void:
	var m := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(200, 200)
	m.mesh = plano
	m.material_override = Formas.material_suelo(color, 8.0, puntos)
	m.position = Vector3(centro.x, 0.06, centro.y)
	add_child(m)


func _construir_limites() -> void:
	var l := GameConfig.LIMITE_MAPA
	for lado in [-1, 1]:
		Formas.caja_solida(self, Vector3(4, 80, l * 2 + 8), Vector3(lado * (l + 2), 40, 0), Color.BLACK, 1, false)
		Formas.caja_solida(self, Vector3(l * 2 + 8, 80, 4), Vector3(0, 40, lado * (l + 2)), Color.BLACK, 1, false)


func _construir_plaza() -> void:
	var raiz := Node3D.new()
	raiz.name = "SpawnPlaza"
	add_child(raiz)
	var borde := Formas.material(GameColors.AMARILLO, 0.6, 0.0, 0.5)
	for lado in [-1, 1]:
		Formas.malla(raiz, "box", Vector3(200, 0.2, 2), Vector3(0, 0.12, lado * 99), borde, false)
		Formas.malla(raiz, "box", Vector3(2, 0.2, 200), Vector3(lado * 99, 0.12, 0), borde, false)
	var gris := Formas.material(Color("#3A3F48"), 0.7, 0.5)
	Formas.caja_solida(raiz, Vector3(16, 5, 16), Vector3(0, 2.5, 0), Color("#3A3F48"))
	var fuste := StaticBody3D.new()
	var forma_fuste := CollisionShape3D.new()
	var cilindro := CylinderShape3D.new()
	cilindro.radius = 4.5
	cilindro.height = 62
	forma_fuste.shape = cilindro
	forma_fuste.position = Vector3(0, 36, 0)
	fuste.add_child(forma_fuste)
	raiz.add_child(fuste)
	Formas.malla(raiz, "cyl", Vector3(9, 62, 9), Vector3(0, 36, 0), gris)
	Formas.malla(raiz, "box", Vector3(18, 1.2, 18), Vector3(0, 52, 0), Formas.material(GameColors.GRIS_OSCURO, 0.6, 0.5))
	Formas.malla(raiz, "sph", Vector3(9, 9, 9), Vector3(0, 71, 0), Formas.material(GameColors.NARANJA, 0.3, 0.0, 2.5))
	Formas.luz_puntual(raiz, Vector3(0, 71, 0), GameColors.NARANJA, 2.0, 90.0)
	Formas.etiqueta(raiz, "WRECK", Vector3(0, 40, 4.7), 0.16, GameColors.NARANJA)
	Formas.malla(raiz, "cyl", Vector3(10, 0.5, 10), Vector3(0, 0.3, 55), Formas.material(GameColors.GRIS_OSCURO, 0.5, 0.7))
	Formas.malla(raiz, "cyl", Vector3(10.6, 0.3, 10.6), Vector3(0, 0.2, 55), Formas.material(GameColors.NARANJA, 0.4, 0.0, 2.0))
	Formas.etiqueta(raiz, "DESTROY. GET RICH. REBIRTH.", Vector3(0, 12, 82), 0.06, GameColors.BLANCO, PI, true)
	var flecha := Formas.material(GameColors.AMARILLO, 0.5, 0.0, 1.8)
	for i in 20:
		Formas.malla(raiz, "prism", Vector3(5.0, 4.0, 0.15), Vector3(0, 0.2, 30.0 - i * 9.0), flecha, false).rotation.x = -PI * 0.5
	for i in 12:
		var ang := i * TAU / 12.0
		_farola(raiz, Vector3(cos(ang) * 92.0, 0, sin(ang) * 92.0))
	_estacion(raiz, "UPGRADE STATION", Vector3(74, 0, -20), GameColors.AMARILLO, "upgrades", "Open · Upgrade Station", -1)
	_estacion(raiz, "SETTINGS TERMINAL", Vector3(-74, 0, -20), GameColors.CIAN, "settings", "Open · Settings", 1)
	_portal(raiz, "ISLAND 1 · SCRAP YARD", Vector3(61, 0, 30), "scrap_yard")
	_portal(raiz, "ISLAND 2 · DOWNTOWN", Vector3(52, 0, 54), "downtown")
	_portal(raiz, "ISLAND 3 · INDUSTRIAL", Vector3(35, 0, 72), "industrial")
	Formas.etiqueta(raiz, "SCRAP YARD  >>", Vector3(0, 6, -108), 0.07, GameColors.AMARILLO, 0.0, true)


func _farola(padre: Node3D, posicion: Vector3) -> void:
	var farola := Node3D.new()
	farola.position = posicion
	padre.add_child(farola)
	Formas.malla(farola, "cyl", Vector3(0.6, 12, 0.6), Vector3(0, 6, 0), Formas.material(Color("#2A2D33"), 0.5, 0.6))
	Formas.malla(farola, "sph", Vector3(1.8, 1.8, 1.8), Vector3(0, 12.4, 0), Formas.material(Color("#FFD9A0"), 0.3, 0.0, 3.0), false)
	Formas.luz_puntual(farola, Vector3(0, 11.5, 0), Color("#FFB070"), 0.6, 30.0)


func _estacion(padre: Node3D, nombre: String, posicion: Vector3, color: Color, panel: String, indicacion: String, hacia_x: int) -> void:
	var raiz := Node3D.new()
	raiz.position = posicion
	padre.add_child(raiz)
	Formas.caja_solida(raiz, Vector3(3.5, 6, 8), Vector3(0, 3, 0), Color("#3A3F48"))
	var pantalla := Formas.malla(raiz, "box", Vector3(0.3, 3.4, 6), Vector3(hacia_x * 1.8, 3.6, 0), Formas.material(color, 0.3, 0.0, 2.0), false)
	pantalla.name = "Pantalla"
	Formas.malla(raiz, "box", Vector3(4.0, 0.6, 8.4), Vector3(0, 6.2, 0), Formas.material(color, 0.4, 0.2, 0.8))
	Formas.etiqueta(raiz, nombre, Vector3(hacia_x * 2.2, 8.6, 0), 0.05, color, hacia_x * PI * 0.5)
	Formas.luz_puntual(raiz, Vector3(hacia_x * 5.0, 4.0, 0), color, 0.8, 18.0)
	var inter := Interactable.crear(raiz, Vector3(hacia_x * 4.0, 1.5, 0), indicacion, 8.0)
	inter.activado.connect(func() -> void: panel_pedido.emit(panel))


func _portal(padre: Node3D, nombre: String, posicion: Vector3, destino: String) -> void:
	var raiz := Node3D.new()
	raiz.position = posicion
	padre.add_child(raiz)
	var color: Color = GameConfig.ZONAS[destino]["tinte"]
	Formas.malla(raiz, "cyl", Vector3(8, 0.5, 8), Vector3(0, 0.3, 0), Formas.material(GameColors.GRIS_OSCURO, 0.4, 0.7))
	Formas.malla(raiz, "cyl", Vector3(6.4, 0.2, 6.4), Vector3(0, 0.6, 0), Formas.material(color, 0.3, 0.0, 2.2), false)
	Formas.etiqueta(raiz, nombre, Vector3(0, 5.5, 0), 0.04, color, 0.0, true)
	Formas.luz_puntual(raiz, Vector3(0, 2.0, 0), color, 0.8, 14.0)
	_portales.append({"pos": posicion, "destino": destino})


func _construir_scrap_yard() -> void:
	var raiz := Node3D.new()
	raiz.name = "ScrapYard"
	add_child(raiz)
	var centro: Vector2 = GameConfig.ZONAS["scrap_yard"]["centro"]
	var metal := Formas.material(Color("#5B6068"), 0.55, 0.6)
	var amarillo_grua := Formas.material(Color("#B98A1E"), 0.6, 0.3)
	for lado in [-1, 1]:
		Formas.caja_solida(raiz, Vector3(3, 44, 3), Vector3(centro.x + lado * 34, 22, centro.y - 78), Color("#B98A1E"))
	Formas.malla(raiz, "box", Vector3(74, 3.4, 3.4), Vector3(centro.x, 44, centro.y - 78), amarillo_grua)
	Formas.malla(raiz, "box", Vector3(0.5, 16, 0.5), Vector3(centro.x - 10, 35, centro.y - 78), metal)
	Formas.malla(raiz, "box", Vector3(3, 3, 3), Vector3(centro.x - 10, 26, centro.y - 78), Formas.material(GameColors.ROJO, 0.5, 0.2))
	for monte in [Vector3(-80, 0, -80), Vector3(78, 0, -86), Vector3(-76, 0, 70)]:
		var m := Formas.malla(raiz, "cone", Vector3(40, 18, 40), Vector3(centro.x + monte.x, 9, centro.y + monte.z), Formas.material(Color("#3E3A36"), 0.95, 0.2))
		var cuerpo := StaticBody3D.new()
		cuerpo.position = m.position + Vector3(0, -3, 0)
		var forma := CollisionShape3D.new()
		var cil := CylinderShape3D.new()
		cil.radius = 15
		cil.height = 12
		forma.shape = cil
		cuerpo.add_child(forma)
		raiz.add_child(cuerpo)
	for punto in [Vector3(-90, 0, 90), Vector3(90, 0, 90), Vector3(-90, 0, -90), Vector3(90, 0, -90)]:
		_reflector(raiz, Vector3(centro.x + punto.x, 0, centro.y + punto.z))
	_retorno(raiz, Vector3(-60, 0, centro.y + 90))
	Formas.etiqueta(raiz, "ISLAND 1 · SCRAP YARD", Vector3(0, 9, centro.y + 98), 0.06, GameColors.AMARILLO, 0.0, true)
	var exclusiones: Array = [Rect2(-14, centro.y + 60, 28, 90), Rect2(-80, centro.y + 70, 40, 36), Rect2(centro.x - 40, centro.y - 84, 80, 12)]
	_poblar("scrap_yard", raiz, exclusiones, [Vector2(-80, -80), Vector2(78, -86), Vector2(-76, 70)])


func _construir_downtown() -> void:
	var raiz := _zona_con_muros("downtown", "Downtown")
	var centro: Vector2 = GameConfig.ZONAS["downtown"]["centro"]
	for f in [Vector3(-60, 0, -88), Vector3(-20, 0, -90), Vector3(20, 0, -88), Vector3(62, 0, -90)]:
		var alto := _rng.randf_range(30.0, 46.0)
		var torre := Formas.caja_solida(raiz, Vector3(24, alto, 10), Vector3(centro.x + f.x, alto * 0.5, centro.y + f.z), Color("#3E4656"))
		Formas.malla(torre, "box", Vector3(20, alto * 0.8, 0.4), Vector3(0, 0, 5.1), Formas.material(Color("#9FC4D8"), 0.2, 0.0, 0.9), false)
	for p in [Vector3(-45, 0, 20), Vector3(-45, 0, -40), Vector3(0, 0, 60), Vector3(0, 0, -50)]:
		_farola(raiz, Vector3(centro.x + p.x, 0, centro.y + p.z))
	_retorno(raiz, Vector3(centro.x + 70, 0, centro.y + 80))
	var exclusiones: Array = [Rect2(centro.x - 100, centro.y - 22, 50, 44), Rect2(centro.x + 50, centro.y + 60, 40, 40)]
	_poblar("downtown", raiz, exclusiones, [])


func _construir_industrial() -> void:
	var raiz := _zona_con_muros("industrial", "Industrial")
	var centro: Vector2 = GameConfig.ZONAS["industrial"]["centro"]
	var acero := Formas.material(Color("#6A7078"), 0.5, 0.7)
	for x in [-60.0, -40.0]:
		Formas.caja_solida(raiz, Vector3(7, 46, 7), Vector3(centro.x + x, 23, centro.y - 85), Color("#6A7078"))
		Formas.malla(raiz, "box", Vector3(7.6, 2.4, 7.6), Vector3(centro.x + x, 46.8, centro.y - 85), Formas.material(GameColors.ROJO, 0.6, 0.2))
	var tanque := StaticBody3D.new()
	tanque.position = Vector3(centro.x - 70, 11, centro.y + 55)
	var forma := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 12.0
	cil.height = 22.0
	forma.shape = cil
	tanque.add_child(forma)
	raiz.add_child(tanque)
	Formas.malla(tanque, "cyl", Vector3(24, 22, 24), Vector3.ZERO, acero)
	Formas.malla(tanque, "sph", Vector3(24, 24, 24), Vector3(0, 11, 0), acero)
	for x in [-10.0, 20.0, 50.0]:
		Formas.malla(raiz, "cyl", Vector3(2.4, 90, 2.4), Vector3(centro.x + x, 8, centro.y - 95), acero).rotation.z = PI * 0.5
	for p in [Vector3(-45, 0, 20), Vector3(-45, 0, -40), Vector3(0, 0, 60)]:
		_farola(raiz, Vector3(centro.x + p.x, 0, centro.y + p.z))
	_retorno(raiz, Vector3(centro.x + 70, 0, centro.y + 80))
	var exclusiones: Array = [Rect2(centro.x - 100, centro.y - 22, 50, 44), Rect2(centro.x + 50, centro.y + 60, 40, 40), Rect2(centro.x - 84, centro.y + 41, 28, 28)]
	_poblar("industrial", raiz, exclusiones, [Vector2(-60, -85), Vector2(-40, -85)])


func _zona_con_muros(id: String, nombre: String) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = nombre
	add_child(raiz)
	var centro: Vector2 = GameConfig.ZONAS[id]["centro"]
	var muro := Color("#2F333C")
	var altura := 16.0
	Formas.caja_solida(raiz, Vector3(200, altura, 3), Vector3(centro.x, altura * 0.5, centro.y - 100), muro)
	Formas.caja_solida(raiz, Vector3(200, altura, 3), Vector3(centro.x, altura * 0.5, centro.y + 100), muro)
	Formas.caja_solida(raiz, Vector3(3, altura, 200), Vector3(centro.x + 100, altura * 0.5, centro.y), muro)
	Formas.caja_solida(raiz, Vector3(3, altura, 76), Vector3(centro.x - 100, altura * 0.5, centro.y - 62), muro)
	Formas.caja_solida(raiz, Vector3(3, altura, 76), Vector3(centro.x - 100, altura * 0.5, centro.y + 62), muro)
	for lado in [-1, 1]:
		Formas.caja_solida(raiz, Vector3(5, 26, 5), Vector3(centro.x - 100, 13, centro.y + lado * 26), Color("#4A4F59"))
	Formas.malla(raiz, "box", Vector3(5, 5, 56), Vector3(centro.x - 100, 27, centro.y), Formas.material(Color("#4A4F59"), 0.5, 0.6))
	var color: Color = GameConfig.ZONAS[id]["tinte"]
	var titulo := "ISLAND %d · %s" % [int(GameConfig.ZONAS[id]["isla"]), GameConfig.ZONAS[id]["nombre"]]
	Formas.etiqueta(raiz, titulo, Vector3(centro.x - 102.8, 27, centro.y), 0.05, color, -PI * 0.5)
	var puerta := Formas.caja_solida(raiz, Vector3(3, 24, 48), Vector3(centro.x - 100, 12, centro.y), Color("#6B7078"))
	Formas.malla(puerta, "box", Vector3(0.4, 22, 4), Vector3(-1.8, 0, 0), Formas.material(GameColors.ROJO, 0.4, 0.0, 1.4), false)
	puertas[id] = puerta
	var inter := Interactable.crear(raiz, Vector3(centro.x - 106, 1.5, centro.y), "", 14.0)
	inter.texto_dinamico = func() -> String:
		if GameState.zona_abierta(id):
			return "%s OPEN" % GameConfig.ZONAS[id]["nombre"]
		return "Unlock ISLAND %d · %s Scrap" % [int(GameConfig.ZONAS[id]["isla"]), Formulas.abreviar(GameConfig.ZONAS[id]["costo"])]
	inter.activado.connect(func() -> void:
		if not GameState.zona_abierta(id):
			panel_pedido.emit("unlock_" + id))
	return raiz


func _reflector(padre: Node3D, posicion: Vector3) -> void:
	var r := Node3D.new()
	r.position = posicion
	padre.add_child(r)
	Formas.malla(r, "cyl", Vector3(0.7, 18, 0.7), Vector3(0, 9, 0), Formas.material(Color("#2A2D33"), 0.5, 0.6))
	Formas.malla(r, "box", Vector3(3, 1.6, 1), Vector3(0, 18.5, 0), Formas.material(Color("#FFE2B0"), 0.3, 0.0, 3.0), false)
	Formas.luz_puntual(r, Vector3(0, 17, 0), Color("#FFC890"), 0.7, 45.0)


func _retorno(padre: Node3D, posicion: Vector3) -> void:
	var raiz := Node3D.new()
	raiz.position = posicion
	padre.add_child(raiz)
	Formas.malla(raiz, "cyl", Vector3(7, 0.5, 7), Vector3(0, 0.3, 0), Formas.material(GameColors.GRIS_OSCURO, 0.4, 0.7))
	Formas.malla(raiz, "cyl", Vector3(5.6, 0.2, 5.6), Vector3(0, 0.6, 0), Formas.material(GameColors.NARANJA, 0.3, 0.0, 2.2), false)
	Formas.etiqueta(raiz, "RETURN TO PLAZA", Vector3(0, 4.5, 0), 0.04, GameColors.NARANJA, 0.0, true)
	_portales.append({"pos": posicion, "destino": "plaza"})


func _poblar(zona: String, padre: Node3D, exclusiones: Array, montes: Array) -> void:
	var centro: Vector2 = GameConfig.ZONAS[zona]["centro"]
	var numero: int = GameConfig.ZONAS[zona]["isla"]
	var coloso := Coloso.crear(numero)
	coloso.position = Vector3(centro.x + GameConfig.POSICION_COLOSO.x, 0, centro.y + GameConfig.POSICION_COLOSO.y)
	padre.add_child(coloso)
	colosos.append(coloso)
	var centro_coloso := centro + GameConfig.POSICION_COLOSO
	var colocados: Array = []
	var margen := 18.0
	for def in GameConfig.OBJETOS[zona]:
		var radio_def: float = maxf(def["caja"].x, def["caja"].z) * 0.5
		for n in int(def["cantidad"]):
			for intento in 400:
				var x := _rng.randf_range(-100.0 + margen + radio_def, 100.0 - margen - radio_def)
				var z := _rng.randf_range(-100.0 + margen + radio_def, 100.0 - margen - radio_def)
				var punto := Vector2(centro.x + x, centro.y + z)
				if _choca(punto, radio_def, colocados, exclusiones, centro, montes, centro_coloso):
					continue
				var objeto := Destructible.crear(def, zona)
				objeto.position = Vector3(punto.x, 0, punto.y)
				objeto.rotation.y = _rng.randf_range(0.0, TAU)
				padre.add_child(objeto)
				destructibles.append(objeto)
				colocados.append({"pos": punto, "radio": radio_def})
				break


func _choca(punto: Vector2, radio: float, colocados: Array, exclusiones: Array, centro: Vector2, montes: Array, centro_coloso: Vector2) -> bool:
	for caja in exclusiones:
		if Rect2(caja).grow(radio).has_point(punto):
			return true
	for monte in montes:
		if punto.distance_to(centro + monte) < 22.0 + radio:
			return true
	if punto.distance_to(centro_coloso) < RADIO_RESERVA_COLOSO + radio:
		return true
	for otro in colocados:
		if punto.distance_to(otro["pos"]) < radio + float(otro["radio"]) + 5.0:
			return true
	return false


func _construir_bloques_bloqueados() -> void:
	var bloqueos := [
		{"nombre": "VIP YARD", "celda": Vector2(-1, -1), "sub": "COMING SOON"},
		{"nombre": "CHAOS CORE", "celda": Vector2(-1, 0), "sub": "COMING SOON"},
		{"nombre": "FUTURE DISTRICT", "celda": Vector2(-1, 1), "sub": "COMING SOON"},
		{"nombre": "HALL OF WRECKERS", "celda": Vector2(0, 1), "sub": "COMING SOON"},
		{"nombre": "MILITARY BASE", "celda": Vector2(1, 1), "sub": "COMING SOON"},
	]
	for b in bloqueos:
		var celda: Vector2 = b["celda"]
		var pos := Vector3(celda.x * SEPARACION, 0, celda.y * SEPARACION)
		var bloque := Formas.caja_solida(self, Vector3(200, 14, 200), pos + Vector3(0, 7, 0), Color("#262930"))
		bloque.name = String(b["nombre"]).to_pascal_case()
		Formas.malla(bloque, "box", Vector3(204, 1, 204), Vector3(0, 7.2, 0), Formas.material(Color("#33363E"), 0.5, 0.5), false)
		Formas.etiqueta(bloque, b["nombre"], Vector3(0, 12.0, 0), 0.22, GameColors.BLANCO, 0.0, true)
		Formas.etiqueta(bloque, b["sub"], Vector3(0, 3.0, 0), 0.12, GameColors.ROJO, 0.0, true)


func _construir_horizonte() -> void:
	var raiz := Node3D.new()
	raiz.name = "Skyline"
	add_child(raiz)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 70:
		var ang := i * TAU / 70.0 + rng.randf_range(-0.03, 0.03)
		var distancia := rng.randf_range(430.0, 560.0)
		var ancho := rng.randf_range(24.0, 60.0)
		var alto := rng.randf_range(50.0, 190.0)
		var color := Color("#2E323B").lerp(Color("#4B3A4E"), rng.randf())
		var torre := Formas.malla(raiz, "box", Vector3(ancho, alto, ancho), Vector3(cos(ang) * distancia, alto * 0.5, sin(ang) * distancia), Formas.material(color, 0.8, 0.2), false)
		torre.rotation.y = -ang
		var franja := Formas.material(Color("#FFC890") if rng.randf() < 0.7 else Color("#FF7A1A"), 0.4, 0.0, 1.4)
		Formas.malla(torre, "box", Vector3(ancho * 0.92, alto * 0.06, ancho * 1.02), Vector3(0, rng.randf_range(-0.2, 0.3) * alto, 0), franja, false)


func _al_desbloquear(id: String) -> void:
	_abrir_puerta(id, true)


func _abrir_puerta(id: String, animado: bool) -> void:
	if not puertas.has(id):
		return
	var puerta: StaticBody3D = puertas[id]
	var colision := puerta.get_child(0) as CollisionShape3D
	colision.set_deferred("disabled", true)
	var destino_y := puerta.position.y + 26.0
	if animado:
		var t := create_tween()
		t.tween_property(puerta, "position:y", destino_y, 1.2).set_trans(Tween.TRANS_QUAD)
		Sfx.reproducir("comprar")
	else:
		puerta.position.y = destino_y
