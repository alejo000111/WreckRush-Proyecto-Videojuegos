extends Node3D

@onready var ciudad: CityWorld = $Ciudad
@onready var isla: BossIsland = $RustAtoll
@onready var ambiente: AmbienceController = $Ambiente
@onready var jugador: Player = $Jugador
@onready var camara: CameraController = $Camara

var hud: Hud

var _muerte_restante: float = 0.0


func _ready() -> void:
	InputSetup.registrar()
	camara.objetivo = jugador
	camara.yaw = 0.0
	camara.saltar_a(jugador.global_position)
	jugador.camara = camara
	ambiente.jugador = jugador
	isla.colosal.jugador = jugador
	var martillo := HammerController.new()
	martillo.name = "Martillo"
	martillo.jugador = jugador
	add_child(martillo)
	var interaccion := InteractionController.new()
	interaccion.name = "Interaccion"
	interaccion.jugador = jugador
	add_child(interaccion)
	var tutorial := Onboarding.new()
	tutorial.name = "Tutorial"
	tutorial.jugador = jugador
	add_child(tutorial)
	hud = Hud.new()
	hud.name = "Hud"
	hud.jugador = jugador
	add_child(hud)
	ciudad.panel_pedido.connect(hud.abrir_panel)
	ciudad.viaje_pedido.connect(viajar_a)
	hud.viaje_isla_pedido.connect(viajar_a_isla)
	isla.volver_pedido.connect(func() -> void: viajar_a("plaza"))
	jugador.murio.connect(_al_morir)
	for senal in [GameState.mejora_comprada, GameState.zona_desbloqueada]:
		senal.connect(func(_a: Variant = null, _b: Variant = null) -> void: GameState.guardar())
	GameState.herramienta_cambio.connect(GameState.guardar)
	if OS.is_debug_build():
		var dev := DevTools.new()
		dev.main = self
		add_child(dev)


func _process(delta: float) -> void:
	if _muerte_restante > 0.0:
		_muerte_restante -= delta
		hud.mostrar_muerte(_muerte_restante)
		if _muerte_restante <= 0.0:
			hud.ocultar_muerte()
			jugador.revivir(isla.punto_aparicion)


func viajar_a(destino: String) -> void:
	match destino:
		"scrap_yard":
			jugador.teletransportar(CityWorld.PUNTO_SCRAP_YARD)
		"downtown":
			if GameState.zona_abierta("downtown"):
				jugador.teletransportar(CityWorld.PUNTO_DOWNTOWN)
			else:
				hud.abrir_panel("unlock_downtown")
		_:
			if isla.colosal.en_pelea():
				isla.colosal.reiniciar()
			jugador.teletransportar(CityWorld.PUNTO_PLAZA + Vector3(0, 0, -20))
	Sfx.reproducir("comprar", -8.0)


func viajar_a_isla() -> void:
	jugador.teletransportar(isla.punto_aparicion)
	GameState.toast.emit("RUST ATOLL", "good")
	Sfx.reproducir("comprar", -8.0)


func _al_morir() -> void:
	_muerte_restante = GameConfig.REAPARICION_ISLA_JEFE
	isla.colosal.reiniciar()
	Sfx.reproducir("error")
