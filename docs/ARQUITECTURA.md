# Arquitectura y equivalencias Roblox → Godot

Esta guía sirve para estudiar cómo se tradujo cada idea del juego de Roblox.

| Roblox | Godot (este proyecto) | Por qué |
|---|---|---|
| `ModuleScript` de fórmulas | `class_name Formulas` con funciones `static` | Funciones puras, sin estado: se prueban sin escena |
| `Config` en ReplicatedStorage | `GameConfig` (constantes) | Todo el balance en un solo lugar |
| Service del servidor (`DataService`, `EconomyService`…) | Autoload `GameState` | Un único dueño del estado; los demás lo consultan |
| `RemoteEvent` / `OnClientEvent` | **Señales** (`signal`, `.connect`) | La UI y los efectos reaccionan sin buscar nodos por nombre en cada frame |
| `DataStore` | `FileAccess` + JSON en `user://` | Guardado local; se sanea al cargar |
| Controllers del cliente | Nodos con `_process` / `_unhandled_input` | `HammerController`, `CameraController`, `InteractionController`… |
| `ProximityPrompt` | `Interactable` + `InteractionController` | Distancia al jugador y mantener E |
| `Workspace` con partes | Escena construida por código (`CityWorld`, `BossIsland`) | Igual que la UI "por código" del original; sin editores de escena que mantener |
| Highlight (contorno) | Shader de *inverted hull* (`outline.gdshader`) en `next_pass` | Contorno amarillo que no depende de la luz |
| `Lighting` | `AmbienceController` (`Environment` + `DirectionalLight3D`) | Hora fija 17:36, 16:18 en la isla |
| `Humanoid` | `CharacterBody3D` con aceleración 80 / fricción 64 | Valores del taller |

## Mapa del diagrama de clases del taller

| Taller | Código |
|---|---|
| `Formulas.velocidadCaminar / radioIman` | `Formulas.velocidad_caminar / radio_iman` |
| `Curvas.suavizado` | `Curvas.suavizado` |
| `CameraController.actualizar` (k = 5, desfase 0,8,12) | `CameraController.actualizar` |
| `EffectsController.golpe / romper` | `Fx.golpe / Fx.romper` |
| `AmbienceController.cambiarDistrito` | `AmbienceController.cambiar_distrito` |
| `BossWarning.mostrar` | `BossWarning.mostrar` |

(Los nombres pasan a `snake_case`, la convención de GDScript.)

## Un golpe, frame a frame

1. `HammerController` detecta clic/F y respeta el cooldown (0,45 s).
2. Elige el objetivo más cercano dentro del alcance (`distancia_a` mide hasta la superficie de la caja).
3. Tira el crítico y llama `recibir_golpe` en el objetivo.
4. El objetivo baja vida y llama `Fx.golpe` (número, chispas, sonido).
5. Si la vida llega a 0: `GameState.registrar_objeto_roto` paga Cash/XP, `Fx.romper` lanza la explosión, se sueltan los orbes y arranca el respawn.
6. `CameraController` vibra 0,15 s si el golpe fue fuerte.

## Decisiones propias (marcadas como propuesta, como pedía el taller)

- **Precio de mejoras**: ×1,5 por nivel los primeros 10 y ×1,15 después (la guía no da el factor).
- **Nivel de herramienta**: el bono de +12 % empieza en el nivel 2, así el Scrap Hammer inicial hace 10 (como en la traza del Rol 3).
- **Jefe**: núcleo 4 000 PV, placas 800 PV, tope de daño por golpe 15 % de la vida de cada pieza, daño de ataque 30 de 100 PV. La guía no fija estos números.
- **Ataque en anillo**: radio 11–34 alrededor del jefe, para castigar a quien pelea pegado a las placas.
- **Muerte**: reaparece en la isla a los 45 s y el jefe se reinicia.
- **Llave de Rust Atoll**: sin Alloy/Copper (aún no hay Workshop): nivel 5 + Power Hammer + Scrap Yard.
- **Sonidos**: generados por código como marcadores; hay que reemplazarlos por audio real.
