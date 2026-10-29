extends Node

signal cash_cambio(valor: int)
signal scrap_cambio(valor: int, capacidad: int)
signal xp_cambio(xp: int, requerido: int, nivel: int)
signal nivel_subio(nivel: int)
signal mejora_comprada(id: String, nivel: int)
signal zona_desbloqueada(id: String)
signal herramienta_cambio()
signal objeto_roto(def: Dictionary, zona: String)
signal toast(texto: String, tipo: String)
signal ajustes_cambio()
signal prompt_cambio(texto: String, progreso: float)
signal boss_estado(datos: Dictionary)
signal tutorial_cambio(paso: int)
signal panel_cambio()
signal jefe_vencido(resultado: Dictionary)

const VERSION_GUARDADO := 1

var cash: int = 0
var scrap: int = 0
var xp: int = 0
var nivel: int = 1
var mejoras: Dictionary = {}
var herramientas: Array = ["scrap_hammer"]
var herramienta_equipada: String = "scrap_hammer"
var zonas: Array = ["scrap_yard"]
var objetos_rotos: int = 0
var golpes: int = 0
var dano_total: float = 0.0
var cash_total: int = 0
var tiempo_juego: float = 0.0
var jefe_victorias: int = 0
var mejor_tiempo_jefe: float = 0.0
var planos: Array = []
var tutorial_paso: int = 0
var tutorial_completo: bool = false
var ajustes: Dictionary = {"camera_shake": true, "damage_numbers": true, "sfx": true}

var paneles_abiertos: int = 0
var boton_wreck: bool = false
var ruta_guardado: String = "user://wreckrush_save.json"
var guardado_habilitado: bool = true
var _tiempo_autoguardado: float = 0.0


func _ready() -> void:
	reiniciar()
	if guardado_habilitado:
		cargar()


func _process(delta: float) -> void:
	tiempo_juego += delta
	_tiempo_autoguardado += delta
	if _tiempo_autoguardado >= GameConfig.AUTOGUARDADO_SEGUNDOS:
		_tiempo_autoguardado = 0.0
		guardar()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		guardar()


func reiniciar() -> void:
	cash = 0
	scrap = 0
	xp = 0
	nivel = 1
	mejoras = {}
	for id in GameConfig.ORDEN_MEJORAS:
		mejoras[id] = 0
	herramientas = ["scrap_hammer"]
	herramienta_equipada = "scrap_hammer"
	zonas = ["scrap_yard"]
	objetos_rotos = 0
	golpes = 0
	dano_total = 0.0
	cash_total = 0
	tiempo_juego = 0.0
	jefe_victorias = 0
	mejor_tiempo_jefe = 0.0
	planos = []
	tutorial_paso = 0
	tutorial_completo = false
	paneles_abiertos = 0
	boton_wreck = false


func nivel_mejora(id: String) -> int:
	return int(mejoras.get(id, 0))


func multiplicador_dano() -> float:
	return Formulas.multiplicador_dano(nivel_mejora("damage"))


func herramienta() -> Dictionary:
	return GameConfig.HERRAMIENTAS[herramienta_equipada]


func dano_base_golpe() -> float:
	return Formulas.dano_golpe(float(herramienta()["dano"]), 1, multiplicador_dano())


func probabilidad_critico() -> float:
	return Formulas.probabilidad_critico(nivel_mejora("critical_chance"))


func cooldown_ataque() -> float:
	return Formulas.cooldown_ataque(float(herramienta()["cooldown"]), nivel_mejora("attack_speed"))


func alcance_ataque() -> float:
	return float(herramienta()["alcance"])


func radio_iman() -> float:
	return Formulas.radio_iman(nivel_mejora("magnet_range"))


func velocidad_caminar() -> float:
	return Formulas.velocidad_caminar(nivel_mejora("move_speed"))


func capacidad_bolsa() -> int:
	return Formulas.capacidad_bolsa(nivel_mejora("scrap_capacity"))


func bolsa_llena() -> bool:
	return scrap >= capacidad_bolsa()


func xp_requerido() -> int:
	return Formulas.xp_para_nivel(nivel)


func agregar_cash(cantidad: int) -> void:
	if cantidad <= 0:
		return
	cash += cantidad
	cash_total += cantidad
	cash_cambio.emit(cash)


func gastar_cash(cantidad: int) -> bool:
	if cantidad < 0 or cash < cantidad:
		return false
	cash -= cantidad
	cash_cambio.emit(cash)
	return true


func agregar_scrap(cantidad: int) -> int:
	var libre := maxi(capacidad_bolsa() - scrap, 0)
	var aceptado := mini(cantidad, libre)
	if aceptado > 0:
		scrap += aceptado
		scrap_cambio.emit(scrap, capacidad_bolsa())
	return aceptado


func gastar_scrap(cantidad: int) -> bool:
	if cantidad < 0 or scrap < cantidad:
		return false
	scrap -= cantidad
	scrap_cambio.emit(scrap, capacidad_bolsa())
	return true


func agregar_xp(cantidad: int) -> void:
	if cantidad <= 0:
		return
	xp += cantidad
	while xp >= xp_requerido():
		xp -= xp_requerido()
		nivel += 1
		nivel_subio.emit(nivel)
		toast.emit("LEVEL UP! LV %d" % nivel, "good")
	xp_cambio.emit(xp, xp_requerido(), nivel)


func registrar_golpe(dano: float) -> void:
	golpes += 1
	dano_total += dano


func registrar_objeto_roto(def: Dictionary, zona: String) -> int:
	var pago := GameConfig.cash_de(def)
	agregar_cash(pago)
	agregar_xp(GameConfig.xp_de(def, zona))
	objetos_rotos += 1
	objeto_roto.emit(def, zona)
	return pago


func precio_mejora(id: String) -> int:
	var def: Dictionary = GameConfig.MEJORAS[id]
	return Formulas.precio_mejora(float(def["base"]), nivel_mejora(id), bool(def["exponencial"]))


func estado_mejora(id: String) -> Dictionary:
	var def: Dictionary = GameConfig.MEJORAS[id]
	if nivel_mejora(id) >= int(def["max"]):
		return {"ok": false, "razon": "MAXED"}
	var precio := precio_mejora(id)
	var tiene := cash if def["moneda"] == "cash" else scrap
	if tiene < precio:
		return {"ok": false, "razon": "NOT ENOUGH %s" % String(def["moneda"]).to_upper(), "precio": precio}
	if id != "scrap_capacity" and def["moneda"] == "scrap" and precio > capacidad_bolsa():
		return {"ok": false, "razon": "BAG TOO SMALL", "precio": precio}
	return {"ok": true, "razon": "", "precio": precio}


func comprar_mejora(id: String) -> Dictionary:
	var estado := estado_mejora(id)
	if not estado["ok"]:
		toast.emit(String(estado["razon"]), "bad")
		return estado
	var def: Dictionary = GameConfig.MEJORAS[id]
	var precio: int = estado["precio"]
	if def["moneda"] == "cash":
		gastar_cash(precio)
	else:
		gastar_scrap(precio)
	mejoras[id] = nivel_mejora(id) + 1
	mejora_comprada.emit(id, mejoras[id])
	if id == "scrap_capacity":
		scrap_cambio.emit(scrap, capacidad_bolsa())
	return estado


func comprar_mejora_maximo(id: String) -> int:
	var compradas := 0
	while estado_mejora(id)["ok"] and compradas < 500:
		comprar_mejora(id)
		compradas += 1
	return compradas


func hay_mejora_asequible() -> bool:
	for id in GameConfig.ORDEN_MEJORAS:
		if estado_mejora(id)["ok"]:
			return true
	return false


func zona_abierta(id: String) -> bool:
	return zonas.has(id)


func desbloquear_zona(id: String) -> bool:
	if zona_abierta(id):
		return true
	var costo: int = GameConfig.ZONAS[id]["costo"]
	if not gastar_cash(costo):
		toast.emit("NOT ENOUGH CASH", "bad")
		return false
	zonas.append(id)
	zona_desbloqueada.emit(id)
	toast.emit("%s UNLOCKED!" % GameConfig.ZONAS[id]["nombre"], "good")
	return true


func posee_herramienta(id: String) -> bool:
	return herramientas.has(id)


func comprar_herramienta(id: String) -> bool:
	if posee_herramienta(id):
		return true
	var precio: int = GameConfig.HERRAMIENTAS[id]["precio"]
	if not gastar_cash(precio):
		toast.emit("NOT ENOUGH CASH", "bad")
		return false
	herramientas.append(id)
	herramienta_cambio.emit()
	toast.emit("%s BOUGHT" % GameConfig.HERRAMIENTAS[id]["nombre"], "good")
	return true


func equipar(id: String) -> bool:
	if not posee_herramienta(id):
		return false
	herramienta_equipada = id
	herramienta_cambio.emit()
	return true


func requisitos_isla() -> Dictionary:
	var isla: Dictionary = GameConfig.ISLA_JEFE
	var herramienta_req: String = isla["herramienta_requerida"]
	var lista: Array = [
		{"texto": "LEVEL %d" % int(isla["nivel_requerido"]), "ok": nivel >= int(isla["nivel_requerido"])},
		{"texto": GameConfig.HERRAMIENTAS[herramienta_req]["nombre"], "ok": posee_herramienta(herramienta_req)},
		{"texto": GameConfig.ZONAS[isla["zona_requerida"]]["nombre"], "ok": zona_abierta(isla["zona_requerida"])},
	]
	var todos := true
	for requisito in lista:
		todos = todos and requisito["ok"]
	return {"ok": todos, "lista": lista}


func registrar_victoria_jefe(tiempo: float) -> Dictionary:
	var premio: Dictionary = GameConfig.JEFE["recompensa"]
	var primera := jefe_victorias == 0
	jefe_victorias += 1
	if mejor_tiempo_jefe <= 0.0 or tiempo < mejor_tiempo_jefe:
		mejor_tiempo_jefe = tiempo
	agregar_cash(int(premio["cash"]))
	var scrap_recibido := agregar_scrap(int(premio["scrap"]))
	agregar_xp(int(premio["xp"]))
	var plano := ""
	if primera:
		plano = GameConfig.JEFE["plano_primera_victoria"]
		if not planos.has(plano):
			planos.append(plano)
	var resultado := {
		"cash": int(premio["cash"]),
		"scrap": scrap_recibido,
		"scrap_perdido": int(premio["scrap"]) - scrap_recibido,
		"xp": int(premio["xp"]),
		"plano": plano,
		"tiempo": tiempo,
		"mejor_tiempo": mejor_tiempo_jefe,
		"victorias": jefe_victorias,
		"tiempo_total": tiempo_juego,
	}
	jefe_vencido.emit(resultado)
	guardar()
	return resultado


func siguiente_meta() -> Dictionary:
	if not zona_abierta("downtown"):
		return {"texto": "DOWNTOWN", "actual": cash, "meta": int(GameConfig.ZONAS["downtown"]["costo"]), "listo": false}
	if not posee_herramienta("power_hammer"):
		return {"texto": "POWER HAMMER", "actual": cash, "meta": int(GameConfig.HERRAMIENTAS["power_hammer"]["precio"]), "listo": false}
	var nivel_req: int = GameConfig.ISLA_JEFE["nivel_requerido"]
	if nivel < nivel_req:
		return {"texto": "LEVEL %d" % nivel_req, "actual": nivel, "meta": nivel_req, "listo": false}
	if jefe_victorias == 0:
		return {"texto": "RUST ATOLL BOSS", "actual": 1, "meta": 1, "listo": true}
	return {"texto": "ALL DONE", "actual": 1, "meta": 1, "listo": true}


func avanzar_tutorial() -> void:
	if tutorial_completo:
		return
	tutorial_paso += 1
	if tutorial_paso >= GameConfig.TUTORIAL.size():
		tutorial_completo = true
	tutorial_cambio.emit(tutorial_paso)


func saltar_tutorial() -> void:
	tutorial_completo = true
	tutorial_paso = GameConfig.TUTORIAL.size()
	tutorial_cambio.emit(tutorial_paso)


func abrir_panel() -> void:
	paneles_abiertos += 1
	panel_cambio.emit()


func cerrar_panel() -> void:
	paneles_abiertos = maxi(paneles_abiertos - 1, 0)
	panel_cambio.emit()


func hay_panel_abierto() -> bool:
	return paneles_abiertos > 0


func cambiar_ajuste(clave: String, valor: bool) -> void:
	ajustes[clave] = valor
	ajustes_cambio.emit()


func a_diccionario() -> Dictionary:
	return {
		"version": VERSION_GUARDADO,
		"cash": cash,
		"scrap": scrap,
		"xp": xp,
		"nivel": nivel,
		"mejoras": mejoras,
		"herramientas": herramientas,
		"herramienta_equipada": herramienta_equipada,
		"zonas": zonas,
		"objetos_rotos": objetos_rotos,
		"golpes": golpes,
		"dano_total": dano_total,
		"cash_total": cash_total,
		"tiempo_juego": tiempo_juego,
		"jefe_victorias": jefe_victorias,
		"mejor_tiempo_jefe": mejor_tiempo_jefe,
		"planos": planos,
		"tutorial_paso": tutorial_paso,
		"tutorial_completo": tutorial_completo,
		"ajustes": ajustes,
	}


func desde_diccionario(datos: Dictionary) -> void:
	reiniciar()
	cash = int(datos.get("cash", 0))
	scrap = int(datos.get("scrap", 0))
	xp = int(datos.get("xp", 0))
	nivel = maxi(int(datos.get("nivel", 1)), 1)
	var guardadas: Dictionary = datos.get("mejoras", {})
	for id in GameConfig.ORDEN_MEJORAS:
		mejoras[id] = clampi(int(guardadas.get(id, 0)), 0, int(GameConfig.MEJORAS[id]["max"]))
	herramientas = []
	for id in datos.get("herramientas", ["scrap_hammer"]):
		if GameConfig.HERRAMIENTAS.has(id):
			herramientas.append(String(id))
	if not herramientas.has("scrap_hammer"):
		herramientas.append("scrap_hammer")
	herramienta_equipada = String(datos.get("herramienta_equipada", "scrap_hammer"))
	if not herramientas.has(herramienta_equipada):
		herramienta_equipada = "scrap_hammer"
	zonas = []
	for id in datos.get("zonas", ["scrap_yard"]):
		if GameConfig.ZONAS.has(id):
			zonas.append(String(id))
	if not zonas.has("scrap_yard"):
		zonas.append("scrap_yard")
	objetos_rotos = int(datos.get("objetos_rotos", 0))
	golpes = int(datos.get("golpes", 0))
	dano_total = float(datos.get("dano_total", 0.0))
	cash_total = int(datos.get("cash_total", 0))
	tiempo_juego = float(datos.get("tiempo_juego", 0.0))
	jefe_victorias = int(datos.get("jefe_victorias", 0))
	mejor_tiempo_jefe = float(datos.get("mejor_tiempo_jefe", 0.0))
	planos = []
	for plano in datos.get("planos", []):
		planos.append(String(plano))
	tutorial_paso = int(datos.get("tutorial_paso", 0))
	tutorial_completo = bool(datos.get("tutorial_completo", false))
	var ajustes_guardados: Dictionary = datos.get("ajustes", {})
	for clave in ajustes.keys():
		ajustes[clave] = bool(ajustes_guardados.get(clave, ajustes[clave]))


func guardar() -> bool:
	if not guardado_habilitado:
		return false
	var archivo := FileAccess.open(ruta_guardado, FileAccess.WRITE)
	if archivo == null:
		push_warning("No se pudo guardar: %s" % error_string(FileAccess.get_open_error()))
		return false
	archivo.store_string(JSON.stringify(a_diccionario()))
	return true


func cargar() -> bool:
	if not FileAccess.file_exists(ruta_guardado):
		return false
	var archivo := FileAccess.open(ruta_guardado, FileAccess.READ)
	if archivo == null:
		return false
	var datos: Variant = JSON.parse_string(archivo.get_as_text())
	if typeof(datos) != TYPE_DICTIONARY:
		push_warning("Guardado corrupto, se ignora")
		return false
	desde_diccionario(datos)
	return true


func borrar_guardado() -> void:
	if FileAccess.file_exists(ruta_guardado):
		DirAccess.remove_absolute(ruta_guardado)
