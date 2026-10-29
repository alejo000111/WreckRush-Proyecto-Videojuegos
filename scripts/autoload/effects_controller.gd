class_name EffectsController
extends Node

signal sacudida_camara(intensidad: float)

const PERFILES := {
	"Small": {"chispas": 10, "pedazos": 5, "velocidad": 22.0, "tamano": 1.0, "sacudida": 0.0},
	"Medium": {"chispas": 18, "pedazos": 8, "velocidad": 30.0, "tamano": 1.5, "sacudida": 0.25},
	"Large": {"chispas": 30, "pedazos": 12, "velocidad": 38.0, "tamano": 2.0, "sacudida": 0.55},
	"Huge": {"chispas": 50, "pedazos": 18, "velocidad": 48.0, "tamano": 2.8, "sacudida": 1.0},
}

var _material_chispa: StandardMaterial3D


func _ready() -> void:
	_material_chispa = StandardMaterial3D.new()
	_material_chispa.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_chispa.albedo_color = GameColors.AMARILLO


func _mundo() -> Node:
	var escena := get_tree().current_scene
	return escena if escena != null else get_tree().root


func golpe(objeto: Node3D, dano: float, critico: bool) -> void:
	if not is_instance_valid(objeto):
		return
	var punto := objeto.global_position + Vector3(0, _altura(objeto) * 0.6, 0)
	if GameState.ajustes.get("damage_numbers", true):
		var color := GameColors.NARANJA if critico else GameColors.BLANCO
		var texto := Formulas.abreviar(dano) + ("!" if critico else "")
		numero_flotante(punto, texto, color, 1.5 if critico else 1.0)
	_chispas(punto, 4 if not critico else 9, GameColors.AMARILLO, 16.0, 0.6)
	if critico:
		sacudida_camara.emit(0.35)
		Sfx.reproducir("critico", -3.0)
	else:
		Sfx.reproducir("golpe", -6.0, randf_range(0.9, 1.1))


func romper(objeto: Node3D, tipo: String, pago: int = 0) -> void:
	if not is_instance_valid(objeto):
		return
	var perfil: Dictionary = PERFILES.get(tipo, PERFILES["Small"])
	var base := objeto.global_position + Vector3(0, _altura(objeto) * 0.5, 0)
	var color: Color = objeto.get("color_principal") if objeto.get("color_principal") != null else Color.GRAY
	_chispas(base, int(perfil["chispas"]), GameColors.AMARILLO, float(perfil["velocidad"]), 1.0)
	_chispas(base, int(perfil["chispas"]) / 2, GameColors.NARANJA, float(perfil["velocidad"]) * 0.7, 1.2)
	_humo(base, float(perfil["tamano"]), color)
	for i in int(perfil["pedazos"]):
		var pieza := DebrisPiece.new()
		var lado := randf_range(0.5, 1.4) * float(perfil["tamano"])
		pieza.configurar(color, Vector3(lado, lado, lado) * 0.6, Vector3(randf_range(-1, 1), randf_range(0.6, 1.6), randf_range(-1, 1)).normalized() * float(perfil["velocidad"]) * randf_range(0.5, 1.0))
		_mundo().add_child(pieza)
		pieza.global_position = base + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	if pago > 0:
		numero_flotante(base + Vector3(0, 3, 0), "+%s" % Formulas.abreviar(pago), GameColors.AMARILLO, 1.4 + float(perfil["tamano"]) * 0.2)
	if float(perfil["sacudida"]) > 0.0:
		sacudida_camara.emit(float(perfil["sacudida"]))
	Sfx.reproducir("romper", -2.0 + float(perfil["tamano"]) * 0.5, 1.3 - float(perfil["tamano"]) * 0.15)


func numero_flotante(posicion: Vector3, texto: String, color: Color, escala: float = 1.0) -> void:
	var etiqueta := Label3D.new()
	etiqueta.text = texto
	etiqueta.modulate = color
	etiqueta.outline_modulate = Color(0.05, 0.05, 0.07)
	etiqueta.outline_size = 18
	etiqueta.font_size = 64
	etiqueta.pixel_size = 0.012 * escala
	etiqueta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	etiqueta.no_depth_test = true
	etiqueta.fixed_size = false
	etiqueta.render_priority = 10
	_mundo().add_child(etiqueta)
	etiqueta.global_position = posicion + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8))
	var viaje := etiqueta.create_tween()
	viaje.set_parallel(true)
	viaje.tween_property(etiqueta, "global_position:y", etiqueta.global_position.y + 5.0, 0.8).set_ease(Tween.EASE_OUT)
	viaje.tween_property(etiqueta, "modulate:a", 0.0, 0.8).set_delay(0.3)
	viaje.chain().tween_callback(etiqueta.queue_free)


func _chispas(posicion: Vector3, cantidad: int, color: Color, velocidad: float, vida: float) -> void:
	if cantidad <= 0:
		return
	var particulas := CPUParticles3D.new()
	particulas.amount = cantidad
	particulas.lifetime = vida * 0.6
	particulas.one_shot = true
	particulas.explosiveness = 1.0
	particulas.direction = Vector3.UP
	particulas.spread = 180.0
	particulas.initial_velocity_min = velocidad * 0.4
	particulas.initial_velocity_max = velocidad
	particulas.gravity = Vector3(0, -70, 0)
	particulas.scale_amount_min = 0.5
	particulas.scale_amount_max = 1.2
	var malla := BoxMesh.new()
	malla.size = Vector3(0.28, 0.28, 0.28)
	var material := _material_chispa.duplicate() as StandardMaterial3D
	material.albedo_color = color
	malla.material = material
	particulas.mesh = malla
	_mundo().add_child(particulas)
	particulas.global_position = posicion
	particulas.emitting = true
	particulas.get_tree().create_timer(vida + 0.5).timeout.connect(particulas.queue_free)


func _humo(posicion: Vector3, tamano: float, color: Color) -> void:
	var particulas := CPUParticles3D.new()
	particulas.amount = int(8 * tamano)
	particulas.lifetime = 1.0
	particulas.one_shot = true
	particulas.explosiveness = 0.9
	particulas.direction = Vector3.UP
	particulas.spread = 70.0
	particulas.initial_velocity_min = 3.0
	particulas.initial_velocity_max = 9.0 * tamano
	particulas.gravity = Vector3(0, 3, 0)
	particulas.scale_amount_min = 1.2 * tamano
	particulas.scale_amount_max = 2.6 * tamano
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0.6))
	curva.add_point(Vector2(1, 1.6))
	particulas.scale_amount_curve = curva
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color(0.35, 0.33, 0.32, 0.7))
	gradiente.set_color(1, Color(0.2, 0.2, 0.22, 0.0))
	particulas.color_ramp = gradiente
	var malla := SphereMesh.new()
	malla.radius = 0.5
	malla.height = 1.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color.lerp(Color(0.4, 0.38, 0.36), 0.6)
	malla.material = material
	particulas.mesh = malla
	_mundo().add_child(particulas)
	particulas.global_position = posicion
	particulas.emitting = true
	particulas.get_tree().create_timer(1.6).timeout.connect(particulas.queue_free)


func _altura(objeto: Node3D) -> float:
	var caja: Variant = objeto.get("caja")
	if caja is Vector3:
		return (caja as Vector3).y
	return 2.0
