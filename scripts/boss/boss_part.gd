@tool
class_name BossPart
extends StaticBody3D

signal golpeada(parte: BossPart)
signal destruida(parte: BossPart)

var tipo: String = "placa"
var vida_max: float = 100.0
var vida: float = 100.0
var caja: Vector3 = Vector3(2, 2, 2)
var color_principal: Color = Color("#6B7078")
var vulnerable: bool = false
var roto: bool = false

var _visual: MeshInstance3D
var _material: StandardMaterial3D
var _contorno: ShaderMaterial
var _luz: OmniLight3D
var _colision: CollisionShape3D
var _tween: Tween


static func crear(tipo_: String, tamano: Vector3, vida_: float, color: Color) -> BossPart:
	var p := BossPart.new()
	p.tipo = tipo_
	p.caja = tamano
	p.vida_max = vida_
	p.vida = vida_
	p.color_principal = color
	return p


func _ready() -> void:
	add_to_group("golpeables")
	collision_layer = 8
	collision_mask = 0
	_contorno = Formas.material_contorno(GameColors.AMARILLO, 0.35)
	_material = Formas.material(color_principal, 0.6, 0.5)
	_material.next_pass = _contorno
	if tipo == "nucleo":
		_visual = Formas.malla(self, "sph", caja, Vector3.ZERO, _material)
		_luz = Formas.luz_puntual(self, Vector3.ZERO, GameColors.AMARILLO, 0.0, 28.0)
	else:
		_visual = Formas.malla(self, "box", caja, Vector3.ZERO, _material)
	_colision = CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = caja
	_colision.shape = forma
	add_child(_colision)
	_aplicar_estado()


func puede_ser_golpeado() -> bool:
	return vulnerable and not roto


func distancia_a(punto: Vector3) -> float:
	var local := to_local(punto)
	var mitad := caja * 0.5
	var cercano := Vector3(clampf(local.x, -mitad.x, mitad.x), clampf(local.y, -mitad.y, mitad.y), clampf(local.z, -mitad.z, mitad.z))
	return local.distance_to(cercano)


func proporcion() -> float:
	return vida / vida_max


func establecer_vulnerable(valor: bool) -> void:
	vulnerable = valor
	_aplicar_estado()


func reiniciar(curar: bool = true) -> void:
	roto = false
	if curar:
		vida = vida_max
	visible = true
	if _colision != null:
		_colision.set_deferred("disabled", false)
	_aplicar_estado()


func recibir_golpe(dano: float, critico: bool = false) -> bool:
	if not puede_ser_golpeado():
		return false
	var aplicado := dano
	vida = maxf(vida - aplicado, 0.0)
	_destello()
	Fx.golpe(self, aplicado, critico)
	golpeada.emit(self)
	if vida <= 0.0:
		roto = true
		_colision.set_deferred("disabled", true)
		Fx.romper(self, "Large" if tipo == "placa" else "Huge")
		visible = false
		vulnerable = false
		destruida.emit(self)
		return true
	return false


func _aplicar_estado() -> void:
	if _material == null:
		return
	_contorno.set_shader_parameter("opacidad", 1.0 if puede_ser_golpeado() else 0.0)
	if tipo == "nucleo":
		_material.emission_enabled = true
		_material.emission = GameColors.AMARILLO if vulnerable else GameColors.ROJO
		_material.emission_energy_multiplier = 3.0 if vulnerable else 0.6
		_material.albedo_color = GameColors.AMARILLO if vulnerable else Color("#5A1C1C")
		_luz.light_energy = 3.0 if vulnerable else 0.0
	else:
		_material.emission_enabled = false


func _destello() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_material.emission_enabled = true
	_material.emission = Color.WHITE
	_material.emission_energy_multiplier = 1.5
	_tween = create_tween()
	_tween.tween_property(_material, "emission_energy_multiplier", 3.0 if tipo == "nucleo" else 0.0, 0.15)
	if tipo == "nucleo":
		_tween.tween_callback(_aplicar_estado)
