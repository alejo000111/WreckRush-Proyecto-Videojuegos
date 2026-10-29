class_name ScrapColossus
extends Node3D

signal victoria(resultado: Dictionary)
signal estado_cambio(estado: int)

enum Estado { INACTIVO, INTRO, ARMADURA, EXPUESTO, DERROTADO, ENFRIAMIENTO }

const ALTURA_ESQUIVE := 2.0
const TIEMPO_CARTEL_VICTORIA := 6.0
const PRIMER_ATAQUE := 2.5

var estado: int = Estado.INACTIVO
var placas: Array[BossPart] = []
var nucleo: BossPart
var jugador: Player
var tiempo_pelea: float = 0.0
var consola: Interactable

var _temporizador: float = 0.0
var _proximo_ataque: float = 0.0
var _contador_ataques: int = 0
var _inactividad: float = 0.0
var _brazos: Array[Node3D] = []
var _tween_ataque: Tween


func _ready() -> void:
	_construir()
	consola = Interactable.crear(self, Vector3(0, 0, 44), "Challenge boss", 10.0, float(GameConfig.JEFE["mantener_consola"]))
	consola.activado.connect(func() -> void: iniciar_pelea())
	Formas.caja_solida(self, Vector3(3.0, 3.0, 2.0), Vector3(0, 1.5, 44), GameColors.GRIS_OSCURO)
	Formas.malla(self, "box", Vector3(3.2, 0.5, 2.2), Vector3(0, 3.2, 44), Formas.material(GameColors.ROJO, 0.5, 0.0, 1.2))
	_emitir_estado()


func _construir() -> void:
	var metal := Formas.material(Color("#5B6068"), 0.55, 0.6)
	var oxido := Formas.material(Color("#7A3B24"), 0.8, 0.3)
	Formas.caja_solida(self, Vector3(19, 2, 19), Vector3(0, 1, 0), Color("#3A3D44"), 8)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var pilar := Formas.caja_solida(self, Vector3(2.4, 18, 2.4), Vector3(sx * 7.5, 11, sz * 7.5), Color("#4A4E56"), 8)
			pilar.name = "Pilar"
	Formas.malla(self, "box", Vector3(18, 8, 18), Vector3(0, 24, 0), oxido)
	Formas.malla(self, "box", Vector3(12, 3, 12), Vector3(0, 29.5, 0), metal)
	Formas.malla(self, "sph", Vector3(7, 7, 7), Vector3(0, 33, 0), metal)
	Formas.malla(self, "box", Vector3(5, 1.2, 0.6), Vector3(0, 33.2, -3.4), Formas.material(GameColors.ROJO, 0.4, 0.0, 2.5))
	for lado in [-1, 1]:
		var brazo := Node3D.new()
		brazo.position = Vector3(lado * 13.0, 26, 0)
		add_child(brazo)
		Formas.malla(brazo, "box", Vector3(4, 13, 4), Vector3(0, -6.5, 0), metal)
		Formas.malla(brazo, "box", Vector3(7, 7, 7), Vector3(0, -15, 0), oxido)
		_brazos.append(brazo)
	var orientaciones := [
		[Vector3(6.5, 6.5, 0), Vector3(1.6, 9, 8)],
		[Vector3(-6.5, 6.5, 0), Vector3(1.6, 9, 8)],
		[Vector3(0, 6.5, 6.5), Vector3(8, 9, 1.6)],
		[Vector3(0, 6.5, -6.5), Vector3(8, 9, 1.6)],
	]
	for i in int(GameConfig.JEFE["cantidad_placas"]):
		var placa := BossPart.crear("placa", orientaciones[i][1], float(GameConfig.JEFE["vida_placa"]), Color("#8A8F99"))
		placa.position = orientaciones[i][0]
		placa.name = "Placa%d" % (i + 1)
		add_child(placa)
		placa.destruida.connect(_al_romper_placa)
		placa.golpeada.connect(_al_golpear)
		placas.append(placa)
	nucleo = BossPart.crear("nucleo", Vector3(5, 5, 5), float(GameConfig.JEFE["vida_nucleo"]), Color("#5A1C1C"))
	nucleo.position = Vector3(0, 7.0, 0)
	nucleo.name = "Nucleo"
	add_child(nucleo)
	nucleo.golpeada.connect(_al_golpear)
	nucleo.destruida.connect(_al_romper_nucleo)


func iniciar_pelea() -> bool:
	if estado != Estado.INACTIVO:
		return false
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("player") as Player
	_reiniciar_partes()
	tiempo_pelea = 0.0
	_inactividad = 0.0
	_contador_ataques = 0
	_temporizador = float(GameConfig.JEFE["duracion_intro"])
	_cambiar_estado(Estado.INTRO)
	Sfx.reproducir("jefe", 0.0, 0.8)
	Fx.sacudida_camara.emit(0.8)
	GameState.toast.emit("SCRAP COLOSSUS AWAKENS", "bad")
	return true


func reiniciar(motivo: String = "") -> void:
	_reiniciar_partes()
	_cambiar_estado(Estado.INACTIVO)
	if motivo != "":
		GameState.toast.emit(motivo, "bad")


func en_pelea() -> bool:
	return estado == Estado.ARMADURA or estado == Estado.EXPUESTO or estado == Estado.INTRO


func placas_restantes() -> int:
	var restantes := 0
	for placa in placas:
		if not placa.roto:
			restantes += 1
	return restantes


func actualizar(delta: float) -> void:
	match estado:
		Estado.INTRO:
			_temporizador -= delta
			if _temporizador <= 0.0:
				_entrar_armadura()
		Estado.ARMADURA, Estado.EXPUESTO:
			tiempo_pelea += delta
			_inactividad += delta
			_actualizar_ataques(delta)
			if estado == Estado.EXPUESTO:
				_temporizador -= delta
				if _temporizador <= 0.0 and not nucleo.roto:
					_restaurar_armadura()
			if _inactividad >= float(GameConfig.JEFE["inactividad_reinicio"]):
				reiniciar("COLOSSUS RESET: NO ACTIVITY")
		Estado.DERROTADO:
			_temporizador -= delta
			if _temporizador <= 0.0:
				_temporizador = float(GameConfig.JEFE["espera_entre_peleas"])
				_cambiar_estado(Estado.ENFRIAMIENTO)
		Estado.ENFRIAMIENTO:
			_temporizador -= delta
			if _temporizador <= 0.0:
				reiniciar()
	_emitir_estado()


func _process(delta: float) -> void:
	actualizar(delta)


func _entrar_armadura() -> void:
	for placa in placas:
		placa.reiniciar(true)
		placa.establecer_vulnerable(true)
	nucleo.establecer_vulnerable(false)
	_proximo_ataque = PRIMER_ATAQUE
	_cambiar_estado(Estado.ARMADURA)


func _exponer() -> void:
	_temporizador = float(GameConfig.JEFE["ventana_expuesta"])
	nucleo.establecer_vulnerable(true)
	_cambiar_estado(Estado.EXPUESTO)
	GameState.toast.emit("CORE EXPOSED! HIT IT!", "good")


func _restaurar_armadura() -> void:
	nucleo.establecer_vulnerable(false)
	for placa in placas:
		placa.reiniciar(true)
		placa.establecer_vulnerable(true)
	_cambiar_estado(Estado.ARMADURA)
	GameState.toast.emit("ARMOR RESTORED", "bad")


func _derrotar() -> void:
	_temporizador = TIEMPO_CARTEL_VICTORIA
	_cambiar_estado(Estado.DERROTADO)
	Sfx.reproducir("victoria")
	Fx.sacudida_camara.emit(1.0)
	var resultado := GameState.registrar_victoria_jefe(tiempo_pelea)
	victoria.emit(resultado)


func _reiniciar_partes() -> void:
	for placa in placas:
		placa.reiniciar(true)
		placa.establecer_vulnerable(false)
	nucleo.reiniciar(true)
	nucleo.establecer_vulnerable(false)


func _al_romper_placa(_parte: BossPart) -> void:
	_inactividad = 0.0
	if estado == Estado.ARMADURA and placas_restantes() == 0:
		_exponer()


func _al_romper_nucleo(_parte: BossPart) -> void:
	_inactividad = 0.0
	if estado == Estado.EXPUESTO:
		_derrotar()


func _al_golpear(_parte: BossPart) -> void:
	_inactividad = 0.0


func _actualizar_ataques(delta: float) -> void:
	_proximo_ataque -= delta
	if _proximo_ataque > 0.0:
		return
	if jugador == null or jugador.muerto:
		_proximo_ataque = 1.0
		return
	var plano := Vector2(jugador.global_position.x - global_position.x, jugador.global_position.z - global_position.z)
	if plano.length() > float(GameConfig.ISLA_JEFE["radio_arena"]) + 10.0:
		_proximo_ataque = 1.0
		return
	_contador_ataques += 1
	_proximo_ataque = float(GameConfig.JEFE["ataque_disco"]["intervalo"])
	if _contador_ataques % 3 == 0:
		_lanzar_anillo()
	else:
		_lanzar_disco()


func _lanzar_disco() -> void:
	var datos: Dictionary = GameConfig.JEFE["ataque_disco"]
	var aviso := BossWarning.mostrar(self, jugador.global_position, float(datos["radio"]), float(datos["aviso"]))
	aviso.impacto.connect(_resolver_impacto.bind(aviso, float(datos["dano"])))
	_animar_ataque()


func _lanzar_anillo() -> void:
	var datos: Dictionary = GameConfig.JEFE["ataque_anillo"]
	var aviso := BossWarning.mostrar(self, global_position, float(datos["radio_exterior"]), float(datos["aviso"]), float(datos["radio_interior"]))
	aviso.impacto.connect(_resolver_impacto.bind(aviso, float(datos["dano"])))
	_animar_ataque()


func _resolver_impacto(aviso: BossWarning, dano: float) -> void:
	if jugador == null or jugador.muerto or not en_pelea():
		return
	var en_el_aire := jugador.global_position.y - global_position.y > ALTURA_ESQUIVE
	if aviso.contiene(jugador.global_position) and not en_el_aire:
		jugador.tomar_dano(dano)


func _animar_ataque() -> void:
	if _tween_ataque != null and _tween_ataque.is_valid():
		_tween_ataque.kill()
	_tween_ataque = create_tween()
	_tween_ataque.set_parallel(true)
	for brazo in _brazos:
		brazo.rotation.x = deg_to_rad(-70)
		_tween_ataque.tween_property(brazo, "rotation:x", 0.0, 0.9).set_delay(0.7)


func _cambiar_estado(nuevo: int) -> void:
	estado = nuevo
	consola.habilitado = nuevo == Estado.INACTIVO if consola != null else true
	estado_cambio.emit(nuevo)


func _objetivo_texto() -> String:
	match estado:
		Estado.INACTIVO:
			return "CHALLENGE SCRAP COLOSSUS AT THE ARENA CONSOLE"
		Estado.INTRO:
			return "GET READY..."
		Estado.ARMADURA:
			return "BREAK THE ARMOR PLATES  %d/%d" % [placas.size() - placas_restantes(), placas.size()]
		Estado.EXPUESTO:
			return "HIT THE CORE!  %ds" % int(ceil(_temporizador))
		Estado.DERROTADO:
			return "VICTORY!"
		_:
			return "COLOSSUS REPAIRING  %ds" % int(ceil(_temporizador))
	return ""


func _emitir_estado() -> void:
	var activo := estado != Estado.INACTIVO
	GameState.boss_estado.emit({
		"activo": activo,
		"nombre": "SCRAP COLOSSUS",
		"proporcion": nucleo.proporcion() if nucleo != null else 1.0,
		"objetivo": _objetivo_texto(),
		"estado": estado,
		"tiempo": tiempo_pelea,
	})
