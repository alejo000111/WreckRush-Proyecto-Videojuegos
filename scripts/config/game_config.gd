@tool
class_name GameConfig
extends RefCounted

const VERSION := "1.0.0"
const NOMBRE_VERSION := "CORTE 1"
const PAGO_OBJETOS_PEQUENOS := 2.0
const MAX_OBJETIVOS_POR_GOLPE := 12
const MULTIPLICADOR_CRITICO := 2.5
const VIDA_JUGADOR := 100.0
const AUTOGUARDADO_SEGUNDOS := 120.0
const DURACION_ORBE := 45.0
const MAX_ORBES_POR_OBJETO := 6
const LIMITE_MAPA := 382.0
const ALTURA_CAIDA := -40.0
const REAPARICION_ISLA_JEFE := 45.0

const XP_POR_TAMANO := {"Small": 3, "Medium": 8, "Large": 20, "Huge": 50}

const HORA_CIUDAD := 17.6
const HORA_ISLA_JEFE := 16.3

const ZONAS := {
	"plaza": {"nombre": "SPAWN PLAZA", "centro": Vector2(0, 0), "costo": 0, "xp": 1.0, "tinte": Color("#FFB070")},
	"scrap_yard": {"nombre": "SCRAP YARD", "centro": Vector2(0, -240), "costo": 0, "xp": 1.0, "tinte": Color("#FFA45C"), "suelo": Color("#4A4036"), "mult": "x1"},
	"downtown": {"nombre": "DOWNTOWN", "centro": Vector2(240, -240), "costo": 1500, "xp": 1.5, "tinte": Color("#E8A0B8"), "suelo": Color("#3A3F4C"), "mult": "x3"},
}

const ORDEN_ZONAS := ["scrap_yard", "downtown"]

const OBJETOS := {
	"scrap_yard": [
		{"id": "scrap_barrel", "nombre": "SCRAP BARREL", "tamano": "Small", "vida": 30, "cash": 9, "scrap": 2, "respawn": 5, "cantidad": 6,
			"caja": Vector3(2.6, 3.2, 2.6), "partes": [["cyl", Vector3(2.4, 3.0, 2.4), Vector3(0, 1.5, 0), Color("#8C4A1E")], ["cyl", Vector3(2.5, 0.3, 2.5), Vector3(0, 2.2, 0), Color("#5A5F66")]]},
		{"id": "wooden_crate", "nombre": "WOODEN CRATE", "tamano": "Small", "vida": 45, "cash": 14, "scrap": 3, "respawn": 5, "cantidad": 6,
			"caja": Vector3(3.2, 3.2, 3.2), "partes": [["box", Vector3(3.0, 3.0, 3.0), Vector3(0, 1.5, 0), Color("#8A6232")]]},
		{"id": "tire_stack", "nombre": "TIRE STACK", "tamano": "Small", "vida": 70, "cash": 21, "scrap": 4, "respawn": 6, "cantidad": 4,
			"caja": Vector3(3.4, 3.2, 3.4), "partes": [["cyl", Vector3(3.2, 1.0, 3.2), Vector3(0, 0.5, 0), Color("#1C1D20")], ["cyl", Vector3(3.0, 1.0, 3.0), Vector3(0, 1.5, 0), Color("#25262A")], ["cyl", Vector3(3.2, 1.0, 3.2), Vector3(0, 2.5, 0), Color("#1C1D20")]]},
		{"id": "road_sign", "nombre": "ROAD SIGN", "tamano": "Small", "vida": 35, "cash": 11, "scrap": 2, "respawn": 5, "cantidad": 4,
			"caja": Vector3(2.8, 5.6, 0.8), "partes": [["cyl", Vector3(0.3, 5.0, 0.3), Vector3(0, 2.5, 0), Color("#6E7078")], ["box", Vector3(2.6, 1.8, 0.2), Vector3(0, 4.6, 0), Color("#B84A2E")]]},
		{"id": "rusty_car", "nombre": "RUSTY CAR", "tamano": "Medium", "vida": 300, "cash": 90, "scrap": 18, "respawn": 12, "cantidad": 4,
			"caja": Vector3(9.0, 4.2, 4.4), "partes": [["box", Vector3(9.0, 2.0, 4.2), Vector3(0, 1.4, 0), Color("#7A3B24")], ["box", Vector3(4.6, 1.6, 3.8), Vector3(-0.4, 3.2, 0), Color("#5E4A3F")]]},
		{"id": "forklift", "nombre": "FORKLIFT", "tamano": "Medium", "vida": 550, "cash": 165, "scrap": 33, "respawn": 15, "cantidad": 2,
			"caja": Vector3(6.0, 8.0, 3.4), "partes": [["box", Vector3(4.6, 2.6, 3.0), Vector3(0, 1.8, 0), Color("#A8741F")], ["box", Vector3(0.6, 7.6, 2.6), Vector3(2.6, 3.8, 0), Color("#4C4F55")], ["box", Vector3(3.0, 0.4, 2.8), Vector3(3.8, 0.7, 0), Color("#4C4F55")]]},
		{"id": "rusty_container", "nombre": "RUSTY CONTAINER", "tamano": "Large", "vida": 1200, "cash": 360, "scrap": 72, "respawn": 22, "cantidad": 2,
			"caja": Vector3(14.0, 6.4, 5.4), "partes": [["box", Vector3(14.0, 6.2, 5.2), Vector3(0, 3.1, 0), Color("#3F6B73")]]},
		{"id": "junk_tower", "nombre": "JUNK TOWER", "tamano": "Huge", "vida": 3000, "cash": 900, "scrap": 180, "respawn": 35, "cantidad": 1,
			"caja": Vector3(10.0, 20.0, 10.0), "partes": [["box", Vector3(10.0, 6.0, 10.0), Vector3(0, 3.0, 0), Color("#6B5A4A")], ["box", Vector3(8.0, 6.0, 8.0), Vector3(0.6, 9.0, -0.4), Color("#7A4A32")], ["box", Vector3(6.0, 5.0, 6.0), Vector3(-0.4, 14.5, 0.4), Color("#4F5760")], ["cyl", Vector3(3.0, 3.0, 3.0), Vector3(0, 18.5, 0), Color("#8C4A1E")]]},
	],
	"downtown": [
		{"id": "parking_meter", "nombre": "PARKING METER", "tamano": "Small", "vida": 180, "cash": 54, "scrap": 11, "respawn": 5, "cantidad": 6,
			"caja": Vector3(1.4, 5.0, 1.4), "partes": [["cyl", Vector3(0.4, 4.0, 0.4), Vector3(0, 2.0, 0), Color("#6E7078")], ["box", Vector3(1.2, 1.4, 0.8), Vector3(0, 4.4, 0), Color("#3C6E8F")]]},
		{"id": "street_lamp", "nombre": "STREET LAMP", "tamano": "Small", "vida": 240, "cash": 72, "scrap": 14, "respawn": 6, "cantidad": 5,
			"caja": Vector3(1.6, 11.0, 1.6), "partes": [["cyl", Vector3(0.5, 10.0, 0.5), Vector3(0, 5.0, 0), Color("#4C4F55")], ["box", Vector3(2.6, 0.5, 1.0), Vector3(1.0, 10.2, 0), Color("#5C6068")]]},
		{"id": "news_kiosk", "nombre": "NEWS KIOSK", "tamano": "Medium", "vida": 900, "cash": 270, "scrap": 54, "respawn": 10, "cantidad": 3,
			"caja": Vector3(5.0, 6.0, 4.0), "partes": [["box", Vector3(4.8, 4.0, 3.8), Vector3(0, 2.0, 0), Color("#2E7D6B")], ["box", Vector3(5.4, 0.6, 4.4), Vector3(0, 4.3, 0), Color("#C45A3C")]]},
		{"id": "taxi_cab", "nombre": "TAXI CAB", "tamano": "Medium", "vida": 1800, "cash": 540, "scrap": 108, "respawn": 12, "cantidad": 4,
			"caja": Vector3(9.0, 4.4, 4.4), "partes": [["box", Vector3(9.0, 2.0, 4.2), Vector3(0, 1.4, 0), Color("#C98C1A")], ["box", Vector3(4.4, 1.6, 3.8), Vector3(-0.4, 3.2, 0), Color("#B07A18")]]},
		{"id": "city_van", "nombre": "CITY VAN", "tamano": "Medium", "vida": 3000, "cash": 900, "scrap": 180, "respawn": 15, "cantidad": 2,
			"caja": Vector3(10.0, 5.4, 4.6), "partes": [["box", Vector3(10.0, 4.4, 4.4), Vector3(0, 2.6, 0), Color("#5D7A99")]]},
		{"id": "shop_front", "nombre": "SHOP FRONT", "tamano": "Large", "vida": 7200, "cash": 2160, "scrap": 432, "respawn": 22, "cantidad": 3,
			"caja": Vector3(14.0, 10.0, 6.0), "partes": [["box", Vector3(14.0, 9.0, 5.6), Vector3(0, 4.5, 0), Color("#8C5B6E")], ["box", Vector3(10.0, 3.6, 0.4), Vector3(0, 2.4, 2.9), Color("#9FC4D8")]]},
		{"id": "office_facade", "nombre": "OFFICE FACADE", "tamano": "Huge", "vida": 18000, "cash": 5400, "scrap": 1080, "respawn": 35, "cantidad": 1,
			"caja": Vector3(16.0, 34.0, 8.0), "partes": [["box", Vector3(16.0, 34.0, 7.6), Vector3(0, 17.0, 0), Color("#4E5F77")], ["box", Vector3(14.0, 30.0, 0.4), Vector3(0, 17.0, 3.9), Color("#8DB4D6")]]},
	],
}

const MEJORAS := {
	"damage": {"nombre": "DAMAGE", "moneda": "cash", "base": 25, "max": 250, "exponencial": false, "icono": "DMG"},
	"attack_speed": {"nombre": "ATTACK SPEED", "moneda": "cash", "base": 60, "max": 25, "exponencial": false, "icono": "SPD"},
	"critical_chance": {"nombre": "CRITICAL CHANCE", "moneda": "scrap", "base": 20, "max": 25, "exponencial": false, "icono": "CRT"},
	"magnet_range": {"nombre": "MAGNET RANGE", "moneda": "scrap", "base": 15, "max": 30, "exponencial": false, "icono": "MAG"},
	"move_speed": {"nombre": "MOVE SPEED", "moneda": "scrap", "base": 25, "max": 20, "exponencial": false, "icono": "RUN"},
	"scrap_capacity": {"nombre": "SCRAP CAPACITY", "moneda": "cash", "base": 50, "max": 80, "exponencial": true, "icono": "BAG"},
}

const ORDEN_MEJORAS := ["damage", "attack_speed", "critical_chance", "magnet_range", "move_speed", "scrap_capacity"]

const HERRAMIENTAS := {
	"scrap_hammer": {"nombre": "SCRAP HAMMER", "tipo": "MELEE", "dano": 10.0, "cooldown": 0.45, "alcance": 11.0, "precio": 0, "color": Color("#B7BCC4")},
	"power_hammer": {"nombre": "POWER HAMMER", "tipo": "MELEE", "dano": 50.0, "cooldown": 0.45, "alcance": 12.0, "precio": 5000, "color": Color("#FF7A1A")},
}

const ORDEN_HERRAMIENTAS := ["scrap_hammer", "power_hammer"]

const ISLA_JEFE := {
	"id": "rust_atoll",
	"nombre": "RUST ATOLL",
	"jefe": "SCRAP COLOSSUS",
	"posicion": Vector3(0, 0, 4800),
	"nivel_requerido": 5,
	"herramienta_requerida": "power_hammer",
	"zona_requerida": "scrap_yard",
	"radio_isla": 150.0,
	"radio_arena": 72.0,
}

const JEFE := {
	"vida_nucleo": 4000.0,
	"cantidad_placas": 4,
	"vida_placa": 800.0,
	"ventana_expuesta": 16.0,
	"fraccion_tope_golpe": 0.15,
	"duracion_intro": 3.0,
	"inactividad_reinicio": 60.0,
	"espera_entre_peleas": 12.0,
	"mantener_consola": 0.6,
	"aviso_minimo": 1.0,
	"ataque_disco": {"radio": 14.0, "aviso": 1.4, "dano": 30.0, "intervalo": 4.6},
	"ataque_anillo": {"radio_interior": 11.0, "radio_exterior": 34.0, "aviso": 1.7, "dano": 30.0},
	"recompensa": {"cash": 6000, "scrap": 600, "xp": 300},
	"plano_primera_victoria": "SCRAP_CLEAVER",
}

const TUTORIAL := [
	{"titulo": "GRAB YOUR TOOL", "texto": "Press 1 or tap the hammer in your hotbar"},
	{"titulo": "BREAK SOMETHING", "texto": "Follow the arrow. Hold WRECK to keep hitting"},
	{"titulo": "GET CASH", "texto": "Wreck small objects for Cash"},
	{"titulo": "UPGRADE", "texto": "Open UPGRADES and buy DAMAGE for 25 Cash"},
	{"titulo": "WRECK MORE", "texto": "Wreck 10 objects"},
	{"titulo": "PLAY YOUR WAY", "texto": "Unlock DOWNTOWN, reach level 5 and take on the Scrap Colossus"},
]


static func cash_de(def: Dictionary) -> int:
	var base: float = def["cash"]
	if def["tamano"] == "Small":
		base *= PAGO_OBJETOS_PEQUENOS
	return int(round(base))


static func scrap_de(def: Dictionary) -> int:
	var base: float = def["scrap"]
	if def["tamano"] == "Small":
		base *= PAGO_OBJETOS_PEQUENOS
	return int(round(base))


static func xp_de(def: Dictionary, zona: String) -> int:
	var base: float = XP_POR_TAMANO[def["tamano"]]
	return int(round(base * float(ZONAS[zona]["xp"])))


static func total_objetos(zona: String) -> int:
	var total := 0
	for def in OBJETOS[zona]:
		total += int(def["cantidad"])
	return total
