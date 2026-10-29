@tool
class_name BossIsland
extends Node3D

signal volver_pedido

var colosal: ScrapColossus
var punto_aparicion: Vector3 = Vector3.ZERO


func _ready() -> void:
	var datos: Dictionary = GameConfig.ISLA_JEFE
	position = datos["posicion"]
	var radio: float = datos["radio_isla"]
	var radio_arena: float = datos["radio_arena"]
	punto_aparicion = global_position + Vector3(0, 3, 112)
	_construir_terreno(radio)
	_construir_arena(radio_arena)
	_construir_camino()
	_construir_tablero()
	_decorar()
	colosal = ScrapColossus.new()
	colosal.name = "ScrapColossus"
	add_child(colosal)
	var retorno := Interactable.crear(self, Vector3(20, 1.5, 112), "Return to city", 8.0, 0.6)
	retorno.activado.connect(func() -> void: volver_pedido.emit())
	Formas.caja_solida(self, Vector3(3, 3, 2), Vector3(20, 1.5, 112), GameColors.GRIS_OSCURO)
	Formas.malla(self, "box", Vector3(3.2, 0.5, 2.2), Vector3(20, 3.2, 112), Formas.material(GameColors.NARANJA, 0.5, 0.0, 1.4))
	Formas.etiqueta(self, "CITY PORTAL", Vector3(20, 5.4, 112), 0.025, GameColors.NARANJA, 0.0, true)


func _construir_terreno(radio: float) -> void:
	var suelo := StaticBody3D.new()
	suelo.position = Vector3(0, -1, 0)
	var colision := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = radio
	cil.height = 2.0
	colision.shape = cil
	suelo.add_child(colision)
	add_child(suelo)
	var cara := MeshInstance3D.new()
	var plano := CylinderMesh.new()
	plano.top_radius = radio
	plano.bottom_radius = radio
	plano.height = 0.2
	plano.radial_segments = 48
	cara.mesh = plano
	cara.material_override = Formas.material_suelo(Color("#4B3F36"), 8.0)
	cara.position = Vector3(0, -0.1, 0)
	add_child(cara)
	Formas.malla(self, "cone", Vector3(radio * 2.0, 90, radio * 2.0), Vector3(0, -46, 0), Formas.material(Color("#3A302B"), 1.0)).rotation.x = PI
	var mar := MeshInstance3D.new()
	var plano_mar := PlaneMesh.new()
	plano_mar.size = Vector2(3000, 3000)
	mar.mesh = plano_mar
	mar.material_override = Formas.material(Color("#C98A6A"), 1.0, 0.0, 0.35)
	mar.position = Vector3(0, -85, 0)
	add_child(mar)
	var segmentos := 28
	for i in segmentos:
		var ang := i * TAU / segmentos
		var roca := Formas.caja_solida(self, Vector3(radio * TAU / segmentos + 1.0, 7, 4), Vector3(cos(ang) * (radio - 2.0), 3.5, sin(ang) * (radio - 2.0)), Color("#3E3732"))
		roca.rotation.y = -ang + PI * 0.5


func _construir_arena(radio_arena: float) -> void:
	var anillo := Formas.malla(self, "cyl", Vector3(radio_arena * 2.0 + 2.0, 0.1, radio_arena * 2.0 + 2.0), Vector3(0, 0.04, 0), Formas.material(GameColors.NARANJA, 0.5, 0.0, 1.6), false)
	anillo.name = "AnilloArena"
	Formas.malla(self, "cyl", Vector3(radio_arena * 2.0 - 1.0, 0.1, radio_arena * 2.0 - 1.0), Vector3(0, 0.07, 0), Formas.material(Color("#33302F"), 0.9, 0.2), false)


func _construir_camino() -> void:
	var baldosa := Formas.material(Color("#2B2F36"), 0.6, 0.4)
	var luz := Formas.material(GameColors.AMARILLO, 0.4, 0.0, 1.6)
	for i in 9:
		var z := 100.0 - i * 6.0
		Formas.malla(self, "box", Vector3(9, 0.2, 5), Vector3(0, 0.12, z), baldosa, false)
		for lado in [-1, 1]:
			Formas.malla(self, "cyl", Vector3(0.7, 1.4, 0.7), Vector3(lado * 6.0, 0.7, z), luz, false)
	Formas.malla(self, "cyl", Vector3(14, 0.4, 14), Vector3(0, 0.2, 112), Formas.material(GameColors.GRIS_OSCURO, 0.5, 0.6))


func _construir_tablero() -> void:
	var isla: Dictionary = GameConfig.ISLA_JEFE
	var marco := Formas.caja_solida(self, Vector3(22, 14, 1.4), Vector3(-26, 9, 100), Color("#3A3F48"))
	marco.rotation.y = 0.35
	var texto := "%s\nBOSS: %s\nRECOMMENDED LEVEL %d\n\nBreak the 4 armor plates,\nthen hit the exposed core.\nJUMP to dodge orange attacks." % [isla["nombre"], isla["jefe"], int(isla["nivel_requerido"])]
	var e := Formas.etiqueta(marco, texto, Vector3(0, 0, 0.8), 0.022, GameColors.BLANCO)
	e.name = "Texto"
	for lado in [-1, 1]:
		Formas.malla(marco, "box", Vector3(1, 6, 1), Vector3(lado * 9, -9, 0), Formas.material(Color("#2A2D33"), 0.5, 0.6), false)


func _decorar() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4800
	var defs: Array = GameConfig.OBJETOS["scrap_yard"]
	for i in 14:
		var ang := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(80.0, 140.0)
		var pos := Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		if pos.z > 90.0 and absf(pos.x) < 32.0:
			continue
		Formas.decoracion(self, defs[rng.randi() % defs.size()], pos, rng.randf_range(0.0, TAU))
