class_name ScrapOrb
extends Node3D

const GRAVEDAD := 120.0
const VELOCIDAD_IMAN := 95.0
const RADIO_RECOGIDA := 2.2
const ALTURA_REPOSO := 0.9

static var _malla: SphereMesh
static var _material: StandardMaterial3D

var valor: int = 1
var vida: float = GameConfig.DURACION_ORBE
var velocidad: Vector3 = Vector3.ZERO

var _atraido: bool = false
var _jugador: Node3D
var _fase: float = randf() * TAU
var _visual: MeshInstance3D


func _ready() -> void:
	if _malla == null:
		_malla = SphereMesh.new()
		_malla.radius = 0.6
		_malla.height = 1.2
		_malla.radial_segments = 12
		_malla.rings = 6
		_material = Formas.material(GameColors.AMARILLO, 0.3, 0.4, 1.6)
		_malla.material = _material
	_visual = MeshInstance3D.new()
	_visual.mesh = _malla
	_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_visual)


func lanzar() -> void:
	velocidad = Vector3(randf_range(-14, 14), randf_range(30, 55), randf_range(-14, 14))


func _process(delta: float) -> void:
	vida -= delta
	if vida <= 0.0:
		queue_free()
		return
	_fase += delta * 4.0
	if vida < 6.0:
		_visual.visible = int(vida * 6.0) % 2 == 0
	if _jugador == null or not is_instance_valid(_jugador):
		_jugador = get_tree().get_first_node_in_group("player") as Node3D
	if _jugador != null and not GameState.bolsa_llena():
		var destino := _jugador.global_position + Vector3(0, 2.0, 0)
		var distancia := global_position.distance_to(destino)
		if distancia <= GameState.radio_iman():
			_atraido = true
		if _atraido:
			velocidad = (destino - global_position).normalized() * minf(VELOCIDAD_IMAN, 20.0 + (GameState.radio_iman() - distancia + 20.0) * 4.0)
			global_position += velocidad * delta
			if distancia <= RADIO_RECOGIDA:
				_recoger()
			return
	elif GameState.bolsa_llena():
		_atraido = false
	_caer(delta)


func _caer(delta: float) -> void:
	if global_position.y > ALTURA_REPOSO or velocidad.y > 0.0:
		velocidad.y -= GRAVEDAD * delta
		global_position += velocidad * delta
		if global_position.y <= ALTURA_REPOSO:
			global_position.y = ALTURA_REPOSO
			velocidad = Vector3.ZERO
	else:
		_visual.position.y = sin(_fase) * 0.2


func _recoger() -> void:
	var aceptado := GameState.agregar_scrap(valor)
	if aceptado <= 0:
		_atraido = false
		return
	Sfx.reproducir("orbe", -12.0, randf_range(0.95, 1.4))
	queue_free()
