# WRECKRUSH — v1.0 (port a Godot)

**DESTROY. GET RICH. REBIRTH.** Simulador de destrucción 3D. Port a **Godot 4.7 (GDScript)** del juego de Roblox del equipo OpenGames, construido a partir de los talleres (Rol 1, 2, 3 y Entrega Final) y la *Guía completa* (estado al 13-oct-2026).

## Qué incluye la v1.0 (alcance del Corte 1)

- Spawn Plaza, **Scrap Yard** (29 objetos), **Downtown** (24 objetos, puerta de 1.5K) y la isla **Rust Atoll** con el **Scrap Colossus**.
- Martillo (Scrap Hammer / Power Hammer), críticos, Cash, Scrap en orbes con imán y bolsa con capacidad, XP y niveles.
- 6 mejoras: DAMAGE, ATTACK SPEED, CRITICAL CHANCE, MAGNET RANGE, MOVE SPEED, SCRAP CAPACITY.
- Jefe: 4 placas → núcleo expuesto 16 s → las placas vuelven; avisos naranja en el suelo (≥ 1 s) que se esquivan saltando.
- Efectos del taller: contorno amarillo, explosión por tamaño, números flotantes, orbes, vibración de cámara, atardecer fijo 17:36 (16:18 en la isla), tinte por distrito.
- HUD, tutorial de 6 pasos con flecha, guardado automático, ajustes, sonidos procedurales.
- Balance del Rol 3 aplicado: los objetos **Small pagan el doble** de Cash y Scrap.

Fuera de alcance (siguientes cortes): Rebirth, Workshop/materiales, mascotas, tienda, misiones, las otras 4 zonas y 5 islas, multijugador. Ver `docs/ALCANCE_V1.md`.

## Cómo ejecutarlo

1. Instala [Godot 4.7](https://godotengine.org/download) (estándar, no .NET). Si abres el proyecto con otra versión de 4.x, Godot avisa; es normal.
2. Abre la carpeta con Godot (la primera vez importa los recursos) y pulsa **F5**.

Por consola:

```bash
godot --headless --path . --import
godot --path .
```

## Controles

| Acción | Tecla |
|---|---|
| Moverse | WASD / flechas |
| Atacar (mantener) | Clic izquierdo o F, o botón WRECK |
| Saltar (esquivar al jefe) | Espacio |
| Herramienta | 1 / 2 |
| Interactuar (mantener en consolas) | E |
| Girar cámara | Arrastrar con clic derecho |
| Mejoras / Herramientas / Ajustes | U / T / Tab |
| Cerrar panel | Retroceso o Esc |

Trucos de desarrollo (solo builds de debug): **F1** +100K Cash, **F2** subir nivel, **F3** +Scrap, **F4** ir a la isla del jefe.

## Pruebas

```bash
godot --headless --path . --import
godot --headless --path . res://tests/test_runner.tscn
```

65 pruebas: fórmulas y tablas de los talleres, economía, guardado, selección de objetivos y la máquina de estados del jefe. Sale con código 1 si algo falla.

## Estructura

```
scripts/core      Formulas, Curvas (funciones puras), colores, input
scripts/config    GameConfig: todo el balance
scripts/autoload  GameState (estado y guardado), Sfx, Fx (EffectsController)
scripts/player    Player, CameraController, HammerController, interacción, tutorial
scripts/world     CityWorld, BossIsland, Destructible, ScrapOrb, AmbienceController
scripts/boss      ScrapColossus, BossPart, BossWarning
scripts/ui        HUD y paneles
shaders           contorno, barra de vida, aviso del jefe, suelo
tests             pruebas automáticas
docs              arquitectura y alcance
```
