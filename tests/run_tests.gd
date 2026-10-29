extends Node

var _fallos: int = 0
var _total: int = 0


func _verificar(condicion: bool, nombre: String) -> void:
	_total += 1
	if condicion:
		print("  ok   ", nombre)
	else:
		_fallos += 1
		print("  FAIL ", nombre)


func _cerca(a: float, b: float, tol: float = 0.001) -> bool:
	return absf(a - b) <= tol


func _nuevo_estado() -> Node:
	var gs: Node = load("res://scripts/autoload/game_state.gd").new()
	gs.guardado_habilitado = false
	gs.reiniciar()
	return gs


func _ready() -> void:
	_test_formulas()
	_test_curvas()
	_test_config()
	_test_economia()
	_test_guardado()
	_test_seleccion_y_critico()
	_test_ambiente()
	await _test_jefe()
	print("\n%d pruebas, %d fallos" % [_total, _fallos])
	get_tree().quit(1 if _fallos > 0 else 0)


func _test_formulas() -> void:
	print("Formulas")
	_verificar(Formulas.velocidad_caminar(0) == 16.0, "velocidad_caminar(0) = 16")
	_verificar(Formulas.velocidad_caminar(20) == 28.0, "velocidad_caminar(20) = 28")
	_verificar(Formulas.velocidad_caminar(100) == 40.0, "velocidad_caminar(100) = 40 (tope)")
	_verificar(Formulas.radio_iman(10) == 27.0, "radio_iman(10) = 27")
	_verificar(Formulas.dano_golpe(10.0, 1, Formulas.multiplicador_dano(1)) == 12.5, "DAMAGE LV1 => 12.5")
	_verificar(_cerca(Formulas.cooldown_ataque(0.45, 1), 0.4245, 0.0001), "ATTACK SPEED LV1 => 0.4245s")
	_verificar(_cerca(Formulas.probabilidad_critico(1), 0.06), "CRIT LV1 = 6%")
	_verificar(Formulas.probabilidad_critico(500) == 0.75, "CRIT tope 75%")
	_verificar(Formulas.capacidad_bolsa(0) == 500, "bolsa nivel 0 = 500")
	_verificar(Formulas.capacidad_bolsa(1) == 650, "bolsa nivel 1 = 650")
	_verificar(Formulas.xp_para_nivel(1) == 25, "xp nivel 1 = 25")
	_verificar(Formulas.precio_mejora(25, 0) == 25, "precio DAMAGE LV0->1 = 25")
	_verificar(Formulas.precio_mejora(25, 11) < Formulas.precio_mejora(25, 10) * 2, "el precio se frena tras 10 niveles")
	_verificar(Formulas.abreviar(1100) == "1.1K", "abreviar 1100")
	_verificar(Formulas.abreviar(1500) == "1.5K", "abreviar 1500")
	_verificar(Formulas.abreviar(5000) == "5K", "abreviar 5000")
	_verificar(Formulas.abreviar(999) == "999", "abreviar 999")
	_verificar(Formulas.formato_tiempo(125.0) == "2:05", "formato_tiempo")


func _test_curvas() -> void:
	print("Curvas")
	_verificar(_cerca(Curvas.suavizado(5.0, 0.5), 0.918, 0.001), "suavizado(5, 0.5) = 0.918")
	_verificar(_cerca(Curvas.suavizado(5.0, 1.0 / 60.0), 0.08, 0.001), "suavizado por frame a 60 FPS = 8%")
	_verificar(_cerca(Curvas.acercar(0.0, 10.0, 5.0, 0.5), 9.18, 0.01), "acercar numeros")


func _test_config() -> void:
	print("Config")
	_verificar(GameConfig.total_objetos("scrap_yard") == 29, "Scrap Yard tiene 29 objetos")
	_verificar(GameConfig.total_objetos("downtown") == 24, "Downtown tiene 24 objetos")
	var barril: Dictionary = GameConfig.OBJETOS["scrap_yard"][0]
	_verificar(GameConfig.cash_de(barril) == 18 and GameConfig.scrap_de(barril) == 4, "SCRAP BARREL paga doble (18 / 4)")
	var coche: Dictionary = GameConfig.OBJETOS["scrap_yard"][4]
	_verificar(GameConfig.cash_de(coche) == 90, "RUSTY CAR sin cambio (90)")
	_verificar(GameConfig.JEFE["aviso_minimo"] <= GameConfig.JEFE["ataque_disco"]["aviso"], "aviso disco >= 1 s")
	_verificar(GameConfig.JEFE["aviso_minimo"] <= GameConfig.JEFE["ataque_anillo"]["aviso"], "aviso anillo >= 1 s")
	_verificar(GameConfig.JEFE["ventana_expuesta"] == 16.0, "nucleo expuesto 16 s")


func _test_economia() -> void:
	print("Economia")
	var gs := _nuevo_estado()
	var barril: Dictionary = GameConfig.OBJETOS["scrap_yard"][0]
	gs.registrar_objeto_roto(barril, "scrap_yard")
	gs.registrar_objeto_roto(GameConfig.OBJETOS["scrap_yard"][1], "scrap_yard")
	_verificar(gs.cash == 46, "barril + caja = 46 Cash")
	_verificar(gs.estado_mejora("damage")["ok"], "DAMAGE LV1 asequible con 46 Cash")
	gs.comprar_mejora("damage")
	_verificar(gs.cash == 21 and gs.dano_base_golpe() == 12.5, "comprar DAMAGE cobra 25 y sube a 12.5")
	_verificar(not gs.estado_mejora("critical_chance")["ok"], "CRIT sin Scrap no se puede comprar")
	_verificar(gs.agregar_scrap(10000) == 500, "la bolsa limita el Scrap a 500")
	_verificar(gs.bolsa_llena(), "bolsa llena")
	_verificar(not gs.desbloquear_zona("downtown"), "Downtown bloqueada sin Cash")
	gs.agregar_cash(1500)
	_verificar(gs.desbloquear_zona("downtown") and gs.zona_abierta("downtown"), "Downtown se desbloquea con 1.5K")
	gs.agregar_xp(25)
	_verificar(gs.nivel == 2, "25 XP suben a nivel 2")
	_verificar(not gs.requisitos_isla()["ok"], "isla bloqueada al inicio")
	gs.nivel = 5
	gs.agregar_cash(5000)
	gs.comprar_herramienta("power_hammer")
	_verificar(gs.requisitos_isla()["ok"], "isla abierta con nivel 5 + Power Hammer + Scrap Yard")
	var res: Dictionary = gs.registrar_victoria_jefe(95.0)
	_verificar(res["plano"] == "SCRAP_CLEAVER" and gs.jefe_victorias == 1, "primera victoria da plano")
	var res2: Dictionary = gs.registrar_victoria_jefe(80.0)
	_verificar(res2["plano"] == "" and gs.mejor_tiempo_jefe == 80.0, "segunda victoria: sin plano, mejor tiempo")
	gs.free()


func _test_guardado() -> void:
	print("Guardado")
	var gs := _nuevo_estado()
	gs.agregar_cash(777)
	gs.mejoras["damage"] = 3
	gs.zonas.append("downtown")
	gs.planos.append("SCRAP_CLEAVER")
	gs.ajustes["sfx"] = false
	var datos: Dictionary = JSON.parse_string(JSON.stringify(gs.a_diccionario()))
	var otro := _nuevo_estado()
	otro.desde_diccionario(datos)
	_verificar(otro.cash == 777 and otro.nivel_mejora("damage") == 3, "ida y vuelta por JSON")
	_verificar(otro.zona_abierta("downtown") and otro.planos.has("SCRAP_CLEAVER"), "zonas y planos persisten")
	_verificar(otro.ajustes["sfx"] == false, "ajustes persisten")
	otro.desde_diccionario({"mejoras": {"damage": 9999}, "herramientas": ["fantasma"]})
	_verificar(otro.nivel_mejora("damage") == 250 and otro.posee_herramienta("scrap_hammer"), "guardado corrupto se sanea")
	gs.free()
	otro.free()


func _test_seleccion_y_critico() -> void:
	print("Combate")
	var lista := [{"id": 1, "distancia": 9.0}, {"id": 2, "distancia": 2.0}, {"id": 3, "distancia": 5.0}]
	var elegidos := HammerController.seleccionar(lista, 1)
	_verificar(elegidos.size() == 1 and elegidos[0]["id"] == 2, "elige el objetivo mas cercano")
	_verificar(HammerController.seleccionar(lista).size() == 3, "maximo de objetivos por golpe")
	var normal := HammerController.tirar_dano(10.0, 0.05, 0.5)
	var critico := HammerController.tirar_dano(10.0, 0.05, 0.01)
	_verificar(normal["dano"] == 10.0 and not normal["critico"], "golpe normal")
	_verificar(critico["dano"] == 25.0 and critico["critico"], "critico x2.5")


func _test_ambiente() -> void:
	print("Ambiente")
	_verificar(AmbienceController.distrito_en(Vector3(0, 0, 0)) == "plaza", "centro = plaza")
	_verificar(AmbienceController.distrito_en(Vector3(0, 0, -240)) == "scrap_yard", "(0,-240) = scrap yard")
	_verificar(AmbienceController.distrito_en(Vector3(240, 0, -240)) == "downtown", "(240,-240) = downtown")
	_verificar(AmbienceController.distrito_en(Vector3(0, 0, 4800)) == "isla_jefe", "z=4800 = isla jefe")
	_verificar(Formulas.elevacion_sol(GameConfig.HORA_ISLA_JEFE) > Formulas.elevacion_sol(GameConfig.HORA_CIUDAD), "sol mas alto en isla de jefe")


func _test_jefe() -> void:
	print("Jefe")
	var gs: Node = get_node("/root/GameState")
	gs.guardado_habilitado = false
	gs.reiniciar()
	var jefe := ScrapColossus.new()
	add_child(jefe)
	await get_tree().process_frame
	_verificar(jefe.estado == ScrapColossus.Estado.INACTIVO, "empieza inactivo")
	_verificar(jefe.nucleo.distancia_a(jefe.nucleo.global_position + Vector3(0, 0, 20)) > 11.0, "alcance medido desde la superficie")
	jefe.nucleo.recibir_golpe(100.0)
	_verificar(jefe.nucleo.vida == jefe.nucleo.vida_max, "nucleo protegido sin pelea")
	_verificar(jefe.iniciar_pelea() and jefe.estado == ScrapColossus.Estado.INTRO, "inicia la intro")
	jefe.actualizar(GameConfig.JEFE["duracion_intro"] + 0.1)
	_verificar(jefe.estado == ScrapColossus.Estado.ARMADURA, "pasa a ARMADURA")
	jefe.nucleo.recibir_golpe(100.0)
	_verificar(jefe.nucleo.vida == jefe.nucleo.vida_max, "nucleo inmune con placas")
	jefe.placas[0].recibir_golpe(100000.0)
	_verificar(_cerca(jefe.placas[0].vida, 800.0 * 0.85), "tope de dano por golpe (15%)")
	for placa in jefe.placas:
		while not placa.roto:
			placa.recibir_golpe(100000.0)
	_verificar(jefe.estado == ScrapColossus.Estado.EXPUESTO, "4 placas rotas => nucleo expuesto")
	jefe.actualizar(GameConfig.JEFE["ventana_expuesta"] + 0.1)
	_verificar(jefe.estado == ScrapColossus.Estado.ARMADURA and jefe.placas_restantes() == 4, "a los 16 s vuelven las placas")
	for placa in jefe.placas:
		while not placa.roto:
			placa.recibir_golpe(100000.0)
	while not jefe.nucleo.roto:
		jefe.nucleo.recibir_golpe(100000.0)
	_verificar(jefe.estado == ScrapColossus.Estado.DERROTADO and gs.jefe_victorias == 1, "nucleo roto => victoria registrada")
	jefe.reiniciar()
	jefe.iniciar_pelea()
	jefe.actualizar(GameConfig.JEFE["duracion_intro"] + 0.1)
	jefe.actualizar(GameConfig.JEFE["inactividad_reinicio"] + 0.1)
	_verificar(jefe.estado == ScrapColossus.Estado.INACTIVO, "60 s sin actividad reinicia la pelea")
	jefe.queue_free()
