class_name Formulas
extends RefCounted

const MAX_VELOCIDAD := 40.0
const PRECIO_NIVELES_EXPONENCIALES := 10
const CRECIMIENTO_PRECIO_INICIAL := 1.5
const CRECIMIENTO_PRECIO_TARDIO := 1.15
const PRECIO_MAXIMO := 1.0e15


static func velocidad_caminar(nivel: int) -> float:
	return minf(16.0 + 0.6 * nivel, MAX_VELOCIDAD)


static func radio_iman(nivel: int) -> float:
	return 12.0 + 1.5 * nivel


static func multiplicador_dano(nivel_mejora: int) -> float:
	return 1.0 + 0.25 * nivel_mejora


static func dano_golpe(dano_herramienta: float, nivel_herramienta: int, multiplicador: float) -> float:
	return dano_herramienta * (1.0 + 0.12 * (nivel_herramienta - 1)) * multiplicador


static func probabilidad_critico(nivel: int) -> float:
	return minf(0.05 + 0.01 * nivel, 0.75)


static func cooldown_ataque(cooldown_base: float, nivel_velocidad: int) -> float:
	return cooldown_base / (1.0 + 0.06 * nivel_velocidad)


static func capacidad_bolsa(nivel: int) -> int:
	return int(round(500.0 * pow(1.3, nivel)))


static func xp_para_nivel(nivel: int) -> int:
	return int(round(25.0 * pow(nivel, 1.35)))


static func precio_mejora(precio_base: float, nivel_actual: int, siempre_exponencial: bool = false) -> int:
	var tope := PRECIO_NIVELES_EXPONENCIALES
	var precio := 0.0
	if siempre_exponencial or nivel_actual <= tope:
		precio = precio_base * pow(CRECIMIENTO_PRECIO_INICIAL, nivel_actual)
	else:
		precio = precio_base * pow(CRECIMIENTO_PRECIO_INICIAL, tope) * pow(CRECIMIENTO_PRECIO_TARDIO, nivel_actual - tope)
	return int(round(minf(precio, PRECIO_MAXIMO)))


static func elevacion_sol(hora: float) -> float:
	return clampf((18.5 - hora) * 13.0, 4.0, 60.0)


static func abreviar(valor: float) -> String:
	var sufijos := ["", "K", "M", "B", "T"]
	var v := absf(valor)
	var i := 0
	while v >= 999.95 and i < sufijos.size() - 1:
		v /= 1000.0
		i += 1
	if i == 0:
		return str(int(v))
	return ("%.1f" % v).trim_suffix(".0") + sufijos[i]


static func formato_tiempo(segundos: float) -> String:
	var total := int(maxf(segundos, 0.0))
	return "%d:%02d" % [total / 60, total % 60]
