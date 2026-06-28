# Handoff: NodeChess — Rediseño UI/UX (móvil)

> **Para tu Claude Code (el que tiene el repo Godot).** Este paquete describe, con valores exactos,
> cómo llevar el rediseño visual de NodeChess al motor **sin tocar la lógica del juego**.

---

## 1. Overview
NodeChess es un juego de mesa táctico (Godot 4.6.3, Android, portrait) cuyo UI hoy se **pinta por código**
en GDScript con `StyleBoxFlat`, `Color()` y emojis sobre la fuente por defecto de Godot. Este rediseño
le da una dirección visual **Pokémon Duel × Clash Royale**: oscuro, cinemático, premium y táctil,
respetando el GDD Part 5 (UI/UX) y la paleta fijada.

El objetivo es **embellecer interfaces, botones, "tarjetas" base, espacios, tipografía e iconos** —
**NO** los modelos 3D de los personajes ni la lógica de combate.

## 2. Sobre los archivos de diseño
Los archivos `*.dc.html` / `support.js` de este bundle son una **referencia de diseño hecha en HTML**
(un prototipo navegable que muestra el look y el flujo buscados), **no código para copiar tal cual**.
La tarea es **recrear ese look en el entorno real del juego (GDScript / Godot)** usando los nodos y
funciones que YA existen en el repo, cambiando únicamente su *estilo*.

Abre el prototipo (`NodeChess UI.dc.html`) para ver el destino visual de cada pantalla: Home, Deck Builder,
Colección, Detalle de figura, Batalla (tablero), Combate y Victoria.

## 3. Fidelidad: **ALTA (hi-fi)**
Colores, tipografía, radios, sombras y jerarquía son finales. Reprodúcelos con precisión usando los
widgets `Control` existentes. Las medidas en el mockup están a **432×936** (referencia portrait);
escala proporcionalmente a la resolución real del proyecto.

---

## 4. ⚠️ REGLA DE ORO — No romper funcionalidad
**Cambia SOLO estilo.** En cada script, modifica colores, fuentes, tamaños, paddings, radios, bordes,
glow y jerarquía visual. **NO** toques:

- Nombres de nodos, ni la estructura del árbol (`$Path/To/Node`, `get_node`, `@onready`).
- `signal` / `connect` / `emit`, ni los nombres de los callbacks.
- `change_scene_to_file(...)` ni las rutas de escena.
- La lógica de juego: `GameState.gd`, `Combat.gd`, `MapData.gd`, `Roster.gd`, `Loadout.gd`.
- Los **modelos 3D** de personajes ni sus animaciones.
- Los **colores de combate** (ver §6) — deben seguir coincidiendo con `Combat.color_of`.

Trabaja script por script, prueba que la escena sigue cargando y respondiendo, y recién entonces pasa al siguiente.

---

## 5. Tipografía
El mayor salto de calidad: **dejar de usar la fuente por defecto de Godot.**

- **Display / títulos / botones grandes:** `Sora` (700–800). Geométrica, premium, con toque tech.
- **UI / texto / labels / números:** `Manrope` (400–700). Limpia y muy legible.

Setup en Godot:
1. Descarga `Sora` y `Manrope` (Google Fonts, OFL) → `res://assets/fonts/`.
2. Crea un `Theme` (`res://ui/theme.tres`) con `default_font = Manrope-Medium.ttf`.
3. En títulos/botones grandes aplica override: `label.add_theme_font_override("font", load("res://assets/fonts/Sora-ExtraBold.ttf"))`.
4. Tamaños mínimos (a 1080p de ancho): cuerpo **24px**, subtítulos 26–30px, títulos 36–56px, números grandes 40px+.
   En labels: `add_theme_font_size_override("font_size", N)`.

---

## 6. Design tokens — Paleta
Hex → `Color()` de Godot (RGB normalizado). Úsalos en `StyleBoxFlat`, `modulate`, `add_theme_color_override`.

| Rol | Hex | `Color()` |
|---|---|---|
| Fondo base | `#0B0E1A` | `Color(0.043,0.055,0.102)` |
| Fondo profundo (3D) | `#070912` | `Color(0.027,0.035,0.07)` |
| Superficie / panel | `#161B2E` | `Color(0.086,0.106,0.18)` |
| Superficie 2 (chips) | `#1E2540` | `Color(0.118,0.145,0.251)` |
| Borde sutil | `#2E3658` | `Color(0.18,0.212,0.345)` |
| **Primario Azul** | `#2E6BFF` | `Color(0.18,0.42,1.0)` |
| Azul claro (edge/glow) | `#5AA0FF` | `Color(0.353,0.627,1.0)` |
| **Secundario Naranja** | `#FF8A3D` | `Color(1.0,0.541,0.239)` |
| **Acento Oro** | `#FFC53D` | `Color(1.0,0.773,0.239)` |
| Éxito / meta propia | `#36D17F` | `Color(0.212,0.82,0.498)` |
| Peligro / enemigo | `#FF5247` | `Color(1.0,0.322,0.278)` |
| Energía ⚡ | `#4FC3F7` | `Color(0.31,0.765,0.969)` |
| Texto primario | `#F4F6FF` | `Color(0.957,0.965,1.0)` |
| Texto secundario | `#A9B2D0` | `Color(0.663,0.698,0.816)` |
| Texto muted | `#6B7596` | `Color(0.42,0.459,0.588)` |

**Rareza:** Común `#8A93AD` · Rara `#3D7DFF` · Épica `#B873FF` · Legendaria `#FFC53D`.

### Colores de combate — **NO CAMBIAR** (deben coincidir con `Combat.color_of`)
Blanco `#EBF0FF` · Oro `#FFD140` · Púrpura `#B873FF` · Azul `#599AFF` · Rojo/Fallo `#E64D4D`.
Jerarquía (solo visual, ya implementada): Azul bloquea todo · ciclo Blanco›Oro›Púrpura›Blanco · Rojo siempre pierde.

### Estados de Buff Node (GDD): Inactivo `#6B7280` · Cargando `#FF8A3D` · Activo `#2E6BFF` · Enfriamiento `#FF5247`.

## 7. Design tokens — Formas
- **Radios:** tarjetas 16–20px · chips/pills full (999) · botones 14–18px · iconos en cuadro 9–13px.
- **Bordes:** 1–2px. Color base `#2E3658`; en foco/activo subir a `#3D7DFF` o al color de acento.
- **Sombras:** paneles `Color(0,0,0,0.35)` desplazada ~y+12, blur amplio. Glow = borde claro + (en 3D) `emission`.
- **Botón primario "jugoso":** `StyleBoxFlat` con gradiente vertical azul (`#4D8BFF`→`#2E6BFF`→`#1F4FD1`),
  `border_width_top = 2` color `#5AA0FF`, sombra inferior, y leve `position.y += 2` en `button_down`.

## 8. Iconografía
Hoy: emojis (🪙💎⚡🃏📖🎲🛍🏆🏠👤🎁🔒➕⚙). El mockup usa **iconos de línea** (stroke 2px, esquinas redondeadas).
Recomendado: exporta un set SVG/PNG a `res://assets/ui/icons/` y reemplaza los emojis por `TextureRect`/`Button.icon`.
Mínimo imprescindible: nav inferior (home, mazos, grid, tienda, perfil), monedas, gema, energía ⚡, engranaje,
cofre, candado, reloj, play ▶, dado, moneda, ruleta, escudo, estrella, +, buscar, chevrons, ✕.
Si el tiempo aprieta, conserva emoji solo en lugares secundarios; prioriza iconos propios en nav + acciones clave.

---

## 9. Cambios archivo por archivo (GDScript)

> Para cada uno: misma estructura de nodos y señales; solo reemplaza estilos. Las funciones citadas
> son las que ya existen y generan cada widget — modifica lo que *devuelven/configuran*, no su firma.

### 9.1 `scripts/MainMenu.gd` → Pantalla **Home**
Builders: `_build_ui()`, `_build_env()` (centro 3D del líder — **no tocar el modelo**), `_gift_slot()`,
`_big_button()`, `_menu_button()`, `_nav_btn()`, `_chip()`, `_soon()`.
- **Top bar:** avatar con anillo de progreso dorado (`conic`/`TextureProgress`) + badge de nivel `#FFC53D`;
  chips de moneda/gema = pill `#12172A` borde `#232C4A`, número en Sora 700; engranaje en cuadro 36px.
- **Centro (líder):** mantener el `_build_env` 3D. Añadir glow radial dorado detrás (un `TextureRect` con
  gradiente radial `#FFC53D` α.26) y elipse de "piso". Nombre en Sora 800 (27px) + pill "LÍDER · LEGENDARIA"
  (fondo `#241D0D`, borde `#6B5417`, texto `#FFD98A`, estrella).
- **Cofres (`_gift_slot`):** cuadro 48px con frame por rareza; estado debajo: "¡Listo!" en `#36D17F`, o reloj+timer
  en `#A9B2D0`, o vacío `+` en `#46506F`. Ver §11 Chest UX del GDD.
- **JUGAR (`_big_button`):** botón primario jugoso (§7), alto 70px, "JUGAR" Sora 800 (23px) + subtítulo
  "Partida rápida" Manrope 600 (11.5px) en `rgba(255,255,255,.82)`.
- **Nav inferior (`_nav_btn`):** 5 tabs; activo = icono+label `#5AA0FF` con barrita superior `#5AA0FF` (glow azul);
  inactivo `#6B7596`. Fondo con leve blur sobre `#0B0E1A`.

### 9.2 `scripts/FigureCard.gd` → Tarjeta de figura (se usa en tablero **y** combate)
`setup(data, rank, team_col, compact)`, `_portrait()`, `accent_of()`. **Mejorar aquí mejora todo en cascada.**
- **`_portrait`** (hoy panel de color + iniciales): conviértelo en el **marco** donde irá el arte real.
  Mientras no haya arte, usa fondo `radial-gradient(120% 95% at 50% 14%, accent, rgba(8,10,20,.4) 76%)`
  con la inicial/monograma en Sora 800 centrado y `text-shadow` oscuro. `accent_of()` ya da el color dominante.
- **Frame por rareza:** borde 2px con el color de rareza (§6) + barrita superior 3–4px del mismo color.
- **Stamina:** badge inferior-derecha con ⚡ `#4FC3F7` + número en Sora 800.
- **Nombre** Sora 700, **tipo** Manrope 600 `#8A93B4`. En `compact`, reduce paddings y oculta pasivas.

### 9.3 `scripts/DeckBuilder.gd` → **Arma tu equipo**
`_build_maps()`, `_build_modsel()` (toggle de modificadores), `_refresh()` (6 slots de equipo), `_build_available()`.
- **Header:** "Arma tu equipo" Sora 800 (24px) + contador pill `N/6` (verde el N).
- **Mapas (`_build_maps`):** tarjetas 150px de ancho, scroll horizontal; mini-grafo del mapa con nodos azules
  y nodo buff dorado; badge "POPULAR" `#FF8A3D` en el destacado.
- **Equipo (`_refresh`):** grid 3 col; cada slot = mini FigureCard con frame de rareza + stamina; slot vacío = `+`.
- **Modificadores (`_build_modsel`):** 4 tarjetas (2 col). Usa los datos REALES de `GameState.MODIFIERS`:
  - Power Surge — coste **3** — "Tu próximo ataque: +20 daño / +1★"
  - Fury — coste **5** — "Tu próximo ataque: +40 daño / +2★"
  - Cleanse — coste **2** — "Quita los debuffs de tus figuras"
  - Adrenaline — coste **2** — "Tu próximo ataque repite un Fallo"
  Coste = badge ⚡N `#4FC3F7`. Estado equipado = borde del color del mod + botón "✓ Equipado"; si no, "Equipar".
- **Footer:** botón primario "Jugar con este mazo".

### 9.4 `scripts/Dex.gd` → **Colección**
Turntable 3D existente (no tocar modelo) + paneles de Pasivas/Evoluciones/Ataques.
- **Header** "Tus figuras" + contador `8/24` (8 en oro). **Buscador** (pill `#11152A` + lupa) y **chips de filtro**
  (Todas activo `#FFC53D` texto oscuro; resto `#11152A` borde `#232C4A`).
- **Grid 2 col** de tarjetas (reusa FigureCard): portrait con monograma, frame de rareza, ⚡stamina,
  etiqueta de rareza, nombre Sora 700, "Rol · Tipo" Manrope 700 `#8A93B4`. Tap → Detalle (§9.7).

### 9.5 `scripts/Board3D.gd` → **Batalla (HUD del tablero)**
`_build_ui()`, `_end_btn()`, `_bench_box()`, `_energy_label()`, `_mods_box()`, `_banner()`, `_hud_label()`,
`_active_card_slot()` (usa FigureCard), `ROLE_COLOR`, `HILITE_*`. El tablero ocupa ~70–80%.
- **Top bar:** botón menú (cuadro 40px), pill central "Tu turno" con punto `#36D17F` y glow; contador figuras
  `3 vs 2` (verde vs rojo).
- **Tablero:** nodos como círculos — normal `#161D33` borde `#2A3357`; entrada propia anillo punteado `#36D17F`,
  enemiga `#FF5247`; **meta** disco con glow (propia verde, enemiga roja) + icono corona; **buff** disco dorado
  con glow + estrella (pulso). Aristas = líneas `#212A47` 3px. Resaltado de alcance del activo = anillo `#5AA0FF`
  con glow. Fichas = disco con gradiente de accent + anillo de equipo (propio `#36D17F`, enemigo `#FF5247`);
  el activo lleva anillo dorado `#FFC53D` con glow (pulso). (Mapea a `ROLE_COLOR`/`HILITE_*`.)
- **Panel inferior:** barra de **energía** segmentada (10 segmentos; llenos `#4FC3F7`, vacíos `#1A2238`) + "7/10";
  fila de **modificadores** equipados (chips con icono+coste); **tarjeta de figura activa** (FigureCard horizontal:
  portrait 52px + nombre + ⚡stamina + tipo); botón naranja **"Atacar"** (jugoso) y **"Terminar turno"** secundario
  (`#141A30` borde `#2A3357`) → corresponde a `_end_btn`.

### 9.6 `scripts/CombatOverlay.gd` + `scripts/AttackPresenter.gd` → **Combate**
Fondo oscurece (mantener `Color(0,0,0,0.86)`); dos `FigureCard` `compact`; presentación 3D (ruleta/moneda/dado)
en `SubViewport`.
- **Layout split simultáneo (lo pediste explícito):** dos columnas. Cada columna = **carta arriba** + su
  **presentación abajo** (atacante: ruleta; defensor según su tipo, p.ej. moneda). Etiquetas "ATACANTE" `#5EE6A0`
  / "DEFENSOR" `#FF8077`. Carta del atacante con borde `#FFC53D` + glow; defensor borde neutro `#46506F`.
- **Título** "¡COMBATE!" Sora 800, letter-spacing 3px, `#FFD98A` con glow, entre dos filetes dorados.
- **Badge "VS"** circular centrado entre columnas (`#222C4E`→`#11152A`, borde `#44507A`).
- **Chips de resultado** bajo cada presentación: cuadrito del color de combate + etiqueta ("Crítico 80" oro,
  "Golpe 50" blanco). **Respeta los colores de combate (§6).**
- **Banner de resultado:** panel con tinte del color ganador + "K.O." si aplica (badge `#FFC53D`) y "¡<Nombre> gana!".
  Botón primario "Continuar".
  La presentación 3D (`AttackPresenter`) no cambia de lógica; solo reestiliza marcos/labels alrededor.

### 9.7 **Detalle de figura** — *pantalla NUEVA* (GDD §10)
Hoy no existe; créala como `CanvasLayer`/`Control` superpuesto que se abre al tocar una carta en Colección.
- Hero (marco de figura grande + glow + frame de rareza), nombre Sora 800, "Rol · Tipo", y 2 tarjetas de stat
  (⚡Stamina, Rareza).
- **Tabs** Resumen / Combate / Evolución:
  - *Resumen:* lista de **Pasivas** (icono escudo + nombre + descripción) — datos reales en `Roster.FIGURES`.
  - *Combate:* **ruleta** (disco con segmentos de color de combate, ya tienes los pools) + leyenda de segmentos
    con % + recuadro "Jerarquía de colores".
  - *Evolución:* cadena de rangos (p.ej. Emberborn → Flame Champion → Infernal Warlord; Venom Witch → Plague Matron),
    marcando "ACTUAL" y los siguientes con candado. Usa `Roster.FIGURES[i].ranks`.
- Botón "Añadir al mazo".

### 9.8 **Victoria / Recompensas** — *mayormente NUEVO* (GDD §18–19 + §11 Chest)
Hoy `Board3D._show_winner()` solo muestra un `Label`. Diseña pantalla:
- Figura ganadora con glow dorado + "¡VICTORIA!" Sora 800 (42px) `#FFD98A`.
- **Barra de XP** ("Nivel 12" + "+120 XP", relleno oro→naranja), **chips** "+85 Monedas" / "+30 Trofeos",
  y **cofre** ganado (§11 Chest UX): card con cofre, "Desbloquea en 2h · o con 💎", botón "Abrir".
- Botones "Revancha" (secundario) y "Reclamar y volver" (primario).

---

## 10. Datos reales (no inventar — viven en `Roster.gd` / `GameState.gd`)
**8 figuras:** Stone Golem (ST1, Ruleta, Bedrock/Counter-Stone), Ironclad Knight (ST2, Dado D6,
Hold the Line/Bulwark), Nightblade (ST3, Moneda, Lunge/Bloodthirst), Rift Mage (ST2, Suma 2d6,
Arcane Pull/Blink), Venom Witch (ST2, Ruleta, Venom Hex/Hexstep → Plague Matron), Storm Valkyrie
(ST4, Ruleta, Aerial/Dive), Emberborn (ST3, Dado D6 → Flame Champion → Infernal Warlord),
Coin Trickster (ST3, Doble Moneda). ST = stamina.
**Modificadores:** ver §9.3 (de `GameState.MODIFIERS`). **Energía:** inicia 0, +1/turno, tope `ENERGY_MAX = 10`;
controlar el buff node da +1/turno. Solo se gasta en modificadores.

## 11. Orden de implementación sugerido
1. Fuentes + `Theme` global (§5) → impacto inmediato en todo.
2. `FigureCard.gd` (§9.2) → mejora tablero, combate, colección y deck a la vez.
3. `MainMenu.gd` Home (§9.1).
4. `DeckBuilder.gd` (§9.3) y `Dex.gd` (§9.4).
5. `Board3D.gd` HUD (§9.5) y `CombatOverlay.gd` (§9.6).
6. Pantallas nuevas: Detalle (§9.7) y Victoria (§9.8).
Tras cada paso: corre la escena, verifica que señales/navegación siguen funcionando.

## 12. Archivos en este bundle
- `NodeChess UI.dc.html` — prototipo navegable hi-fi (las 7 pantallas). Es la **referencia visual**.
- `support.js` — runtime del prototipo (solo para que abra; no es del juego).
- `README.md` — este documento (autosuficiente).

> Nota: el prototipo está hecho en HTML como referencia de *aspecto y flujo*. No se envía al juego;
> se recrea en GDScript siguiendo §9. Los modelos 3D y la lógica permanecen intactos.
