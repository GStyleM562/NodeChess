# NodeChess — Handoff de Menús/Interfaz (UI/UX)

> ⚠️ **PALETA SUPERSEDIDA (2026-07-19).** El LOOK de este handoff (tema oscuro
> azul) fue reemplazado por el tema claro **"JUICY HALL"** — reglas canónicas
> en **`docs/UIUX_Juicy_Hall.md`** (fondo amarillo cálido, tarjetas crema con
> labio 3D, botones extruidos, texto tinta). La ESTRUCTURA de este handoff
> (jerarquía, secciones, scroll, helpers de UITheme, tamaños táctiles) SIGUE
> VIGENTE. Ante cualquier conflicto de color/estilo, gana `UIUX_Juicy_Hall.md`.

> **Handoff NUEVO y SEPARADO.** No mezclar con los anteriores (`_ui...` y `_shop_profile`).
> Cubre SOLO pantallas de **menú / interfaz / configuración**. **NO** toca combate, batalla, ni modelos 3D.
> Referencia visual: **`NodeChess Menus.dc.html`** (ábrelo en un navegador — es la fuente de verdad del look).

---

## 0. Alcance — qué SÍ y qué NO

**SÍ rediseñar (solo presentación):**
- `MainMenu.gd` → **Home** (barra superior, título, cofres, botón JUGAR, rejilla de 6, nav inferior) + **modal Configuración ⚙**
- `DeckBuilder.gd` → **Arma tu equipo**
- `Dex.gd` → **Colección** (solo el overlay de UI: buscador, panel de info, barra inferior)
- `InventoryScreen.gd` → **Inventario**
- `OnlineLobby.gd` → **Jugar en línea**
- `CharacterCreator.gd` → **Crear Personaje**
- `FigureCard.gd` → tarjetas (borde por rareza, tipografía) — **sin tocar `_portrait()`/arte**
- `UITheme.gd` → añadir 3 helpers (abajo)

**NO tocar (dejar igual):**
- Modelos / 3D: `MainMenu` (líder flotante), `Dex` (modelo), `Figure3D.gd`, `FigurePreview.gd`, `Board3D.gd`
- Combate: `CombatOverlay.gd`, `AttackPresenter.gd`, `AttackTester.gd`
- Lógica/datos: `Inventory.gd`, `Settings.gd`, `NetClient.gd`, `NetSession.gd`, `GameState`, `Music.gd`, `Sfx.gd`
- **Ningún cambio de comportamiento.** Los botones, sus señales (`pressed`) y sus funciones se mantienen — solo cambia cómo se ven y cómo se ordenan.

**Regla de oro:** mantener TODOS los botones existentes y sus conexiones. Solo reordenar, reestilizar y respetar el scroll vertical (arriba→abajo).

---

## 1. Mapa de archivos (dónde vive cada pantalla)

| Pantalla (mock) | Script Godot | Ancla real |
|---|---|---|
| Home + Configuración | `game/scripts/MainMenu.gd` | config: línea ~543 (`⚙ Configuración`) |
| Arma tu equipo | `game/scripts/DeckBuilder.gd` | título: línea 42 |
| Colección / Dex | `game/scripts/Dex.gd` | toggle info: líneas 155 / 338 |
| Inventario | `game/scripts/InventoryScreen.gd` | header: línea 75 |
| Jugar en línea | `game/scripts/OnlineLobby.gd` | título: línea 45 |
| Crear Personaje | `game/scripts/CharacterCreator.gd` | título: línea 167 |
| Tarjeta de figura | `game/scripts/FigureCard.gd` | `_portrait()` (NO tocar arte) |
| Tokens/estilos | `game/scripts/UITheme.gd` | (añadir helpers, §3) |

---

## 2. El sistema YA está centralizado en `UITheme`

Todas las pantallas usan `UITheme`. Reutiliza SIEMPRE estos helpers existentes en vez de crear StyleBox a mano:

- `UITheme.label(lbl, size, color, title=false, weight=-1)` — tipografía (Sora si `title`, Manrope si no).
- `UITheme.button_font(btn, size, color, title, weight)` — fuente de botón (+ engancha el SFX de click).
- `UITheme.panel(bg, border, radius, bw, pad)` — tarjeta/panel (con sombra).
- `UITheme.pill(bg, border, pad)` — píldora redonda (para las monedas de la barra superior).
- `UITheme.style_primary(btn, accent, radius)` — botón primario "jugoso" (relleno + borde superior claro + sombra).
- `UITheme.style_surface(btn, bg, border, radius)` — botón secundario plano (normal/hover/pressed/disabled).

**Colores ya definidos** (úsalos por nombre, no pongas hex sueltos):
`BG #0B0E1A` · `SURFACE #161B2E` · `SURFACE2 #1E2540` · `BORDER #2E3658` · `PRIMARY #2E6BFF` · `PRIMARY_EDGE #5AA0FF` · `ORANGE #FF8A3D` · `GOLD #FFC53D` · `SUCCESS #36D17F` · `DANGER #FF5247` · `ENERGY #4FC3F7` · `TEXT #F4F6FF` · `TEXT2 #A9B2D0` · `MUTED #6B7596` · rarezas `R_COMMON / R_RARE / R_EPIC / R_LEGEND`.

> **Fuentes:** el tema ya carga `res://assets/fonts/Sora.ttf` y `Manrope.ttf`. Verifica que ambos existan; si faltan, el look cae a la fuente por defecto. Descárgalas de Google Fonts (Sora + Manrope) y colócalas ahí.

---

## 3. Añadir a `UITheme.gd` (pegar tal cual)

El rediseño usa 4 piezas nuevas. Pégalas al final de `UITheme.gd`:

```gdscript
# ---- NUEVO (rediseño menús) ----------------------------------------------
const SECTION := PRIMARY_EDGE                      # azul de encabezados de sección
const PANEL_DEEP := Color(0.047, 0.071, 0.165)     # #0C122A  paneles agrupadores
const INPUT_BG := Color(0.039, 0.063, 0.125)       # #0A1020  campos de formulario

## Encabezado de sección: azul, 12px, MAYÚSCULAS, Manrope 700.
static func section(l: Label, text := "") -> void:
	if text != "": l.text = text.to_upper()
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", SECTION)
	var f := body(700)
	if f != null: l.add_theme_font_override("font", f)

## Cuadro redondeado tintado para enmarcar un emoji/icono (18–20px de glifo dentro).
static func icon_tile(accent := PRIMARY, radius := 11) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.16)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(6)
	return sb

## Campo de entrada (nombre, servidor, código, dropdowns cerrados).
static func input(bg := INPUT_BG, border := BORDER, radius := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(1)
	sb.border_color = border
	sb.set_content_margin_all(12)
	return sb

## Chip conmutable (mapa / modificador / estado / dificultad).
## selected=false → superficie con borde; selected=true → relleno accent + borde superior claro.
static func chip(selected: bool, accent := PRIMARY, radius := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(radius)
	if selected:
		sb.bg_color = accent
		sb.border_width_top = 2
		sb.border_color = accent.lightened(0.35)
	else:
		sb.bg_color = PANEL_DEEP
		sb.set_border_width_all(1)
		sb.border_color = BORDER
	sb.set_content_margin_all(11)
	return sb
```

> Con esto, cambiar un chip seleccionado es una línea:
> `btn.add_theme_stylebox_override("normal", UITheme.chip(is_sel, UITheme.PRIMARY))`
> (mapa/dificultad usan `PRIMARY`; modificadores seleccionados usan `ORANGE`).

---

## 4. Reglas globales de layout (aplican a TODAS las pantallas)

1. **Estructura de pantalla = 3 zonas verticales** con `VBoxContainer`:
   - **Header fijo** (arriba): título + acciones. No scrollea.
   - **Cuerpo scroll**: `ScrollContainer` con `VBoxContainer` dentro (`size_flags_vertical = SIZE_EXPAND_FILL`). Aquí va TODO el contenido largo.
   - **Barra inferior fija**: botones Menú / Jugar / navegación. No scrollea.
   Esto respeta el "slide arriba↔abajo" y evita que los botones de acción se pierdan.
2. **Márgenes laterales:** 16 px (usar `MarginContainer` o `content_margin`). **Padding inferior del scroll:** 20 px.
3. **Separación (`add_theme_constant_override("separation", …)`):** entre secciones 13 px; entre elementos de una lista 8–9 px; dentro de una fila 8–10 px.
4. **Radios:** paneles/tarjetas 16 px · botones/chips 12–14 px · píldoras 999 · tiles de icono 11 px.
5. **Encabezado de sección** = `UITheme.section(lbl, "MODIFICADORES")` (azul, MAYÚSCULAS). Debajo, 9 px de aire.
6. **Tarjetas agrupadoras** (paneles que envuelven varias secciones) = `UITheme.panel(UITheme.PANEL_DEEP, Color(0.125,0.157,0.267), 18, 1, 14)`.
7. **Jerarquía tipográfica:** título de pantalla Sora 800 · 24–26px; título de sección Sora 800 · 16px (color `SECTION`); cuerpo Manrope 500–600 · 13–15px; nota/ayuda Manrope 500 · 12px `MUTED`.
8. **Botón primario** siempre `UITheme.style_primary(btn, UITheme.PRIMARY)`; secundario `UITheme.style_surface(btn)`.
9. **Nunca** texto < 12px. Área táctil mínima 44px de alto en botones.

---

## 5. Iconos (mantener emoji, enmarcarlos)

Los emoji actuales (🎁 💎 👑 🎴 📖 📦 🌐 🛠️ 🎲 😊 🙂 😈) son triviales en Godot y **se conservan**. El salto de calidad viene de **enmarcarlos**: un `Panel`/`PanelContainer` cuadrado (38×38) con `UITheme.icon_tile(accent)` de fondo y un `Label` con el emoji (font_size 19) centrado.

```gdscript
func _icon_tile(emoji: String, accent: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(38, 38)
	pc.add_theme_stylebox_override("panel", UITheme.icon_tile(accent))
	var l := Label.new()
	l.text = emoji
	l.add_theme_font_size_override("font_size", 19)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pc.add_child(l)
	return pc
```

(Opcional: si más adelante hay texturas de icono, se sustituye el `Label` por un `TextureRect` — el tile no cambia.)

---

## 6. Pantalla por pantalla

> Para cada una: abre la pantalla equivalente en `NodeChess Menus.dc.html` y copia el orden, tamaños y colores. Aquí van los puntos clave.

### 6.1 `MainMenu.gd` — HOME
Orden vertical exacto (arriba→abajo):
1. **Barra superior** (fija): avatar `P1` con aro dorado (aro = `conic`/`Panel` circular; puedes dejar el aro con un `StyleBoxFlat` circular dorado al 62%) · nombre "Jugador" + barra fina de XP (6px, relleno `PRIMARY`) + "Nv 2 · 20/200" `MUTED` · a la derecha, 3 píldoras de moneda con `UITheme.pill()` (oro 1,250 · gema 30 · ⚡8) · botón ⚙ (34×34, `style_surface`).
2. **Wordmark "NodeChess"** centrado, Sora 800 · 34px, color `TEXT` (opcional leve glow).
3. **Héroe / líder** (NO tocar el modelo 3D flotante): debajo, nombre del líder Sora 800 · 24px + píldora "★ LÍDER · RARA" con borde `R_RARE`.
4. **Cofres**: encabezado `UITheme.section(lbl, "COFRES · toca uno para abrirlo")`. Fila de **5** botones iguales (grid de 5 columnas, gap 8). Cada uno: tile de icono (§5) con su color, label (Sora 700 · 10px) y estado (Sora 800 · 9px). Colores/estados: Gratis→`PRIMARY`/"¡Gratis!" · Común→`SUCCESS`/"¡LISTO!" · Épico→`R_EPIC`/"¡LISTO!" · Legendario→`GOLD`/"¡LISTO!" · Nivel→`ORANGE`/"×1". Borde del botón = su color; fondo = `PANEL_DEEP`.
5. **Botón JUGAR** grande: `style_primary(btn, PRIMARY, 18)`; texto "▶ JUGAR" Sora 800 · 22px + subtítulo "Partida rápida" 12px (usa un `VBox` dentro o un segundo Label).
6. **Rejilla 3×2** (Mazos, Colección, Inventario, Online, Crear, Probar): `GridContainer(columns=3)`, gap 9. Cada celda: tile de icono con su acento + label Sora 700 · 12px. Acentos: Mazos `PRIMARY_EDGE` · Colección `R_EPIC` · Inventario `TEXT2` · Online `ENERGY` · Crear `SUCCESS` · Probar `ORANGE`. Borde de celda = acento al ~33% (usa `Color(acento, .33)`), fondo `SURFACE`/`#10152A`.
7. **Nav inferior** (fija): 3 ítems Home / Tienda / Perfil. El activo (Home) lleva subrayado 26×3 `PRIMARY_EDGE` e icono+label en `PRIMARY_EDGE`; inactivos en `MUTED`.

### 6.1b `MainMenu.gd` — MODAL CONFIGURACIÓN ⚙
Fondo oscurecido (`Color(0,0,0,.72)`) + tarjeta central `panel(SURFACE, Color(0.17,0.22,0.38), 22, 1, 18)`, scrolleable. Orden:
- Título "⚙ Configuración" centrado, Sora 800 · 20px, `GOLD`.
- **Música** — fila (label izq + "80%" `GOLD` der) + `HSlider`. Estiliza el slider: `grabber` y `slider` con `PRIMARY`/`#1A2238`.
- **Sonidos (SFX)** — igual.
- Sección `TABLERO (solo visual)`: 2 botones (3D con assets ✓ / 2D digital). El activo = `style_primary(btn, PRIMARY)`; inactivo = `style_surface`. Añade el ✓ al texto del activo. Debajo, nota `MUTED` 12px.
- Sección `COMBATE Y ACCESIBILIDAD`: 2 botones (▶ Combate ×1 / 👁 Daltónico) `style_surface`; luego "🎓 Repetir tutorial" ancho completo `style_surface`.
- Sección `VISTA (progresión)`: 2 botones (👑 Admin / 👤 Usuario). Activo Admin = `style_primary(btn, GOLD)` (texto oscuro `Color(0.16,0.12,0.02)`); Usuario activo = `style_primary(btn, PRIMARY)`. Nota `MUTED` debajo.
- Bloque de ayuda de audio: `panel(PANEL_DEEP, BORDER, 13, 1, 12)`, textos `MUTED` 11px, interlineado holgado.
- Botón **Cerrar** ancho: `style_primary(btn, PRIMARY, 14)`.

### 6.2 `DeckBuilder.gd` — ARMA TU EQUIPO
Header (fijo): título "Arma tu equipo" Sora 800 · 26px + subtítulo `MUTED` 13px. Debajo, fila de pestañas: "Mazo 1" (`style_primary`) · "Mazo 2" (`style_surface`) · spacer · 3 botones-icono cuadrados 40×40 (`style_surface`): reordenar (verde `SUCCESS`), vaciar (papelera, `TEXT2`), duplicar (`GOLD`).
Cuerpo (scroll):
- **Panel agrupador A** (`panel(PANEL_DEEP,…,18)`):
  - `MAPA`: fila **horizontal scrollable** (`ScrollContainer` horizontal) de chips `UITheme.chip(sel, PRIMARY)` (seleccionado azul). Nombres reales: Rieles · Reloj de Arena · Plaza · Túneles · Cruce…
  - `MODIFICADORES · elige hasta 3`: `GridContainer(columns=2)`, gap 8. Cada chip = nombre + ⚡ + coste. Seleccionado = `UITheme.chip(true, ORANGE)` con texto oscuro; no seleccionado = `chip(false)` con coste en `GOLD`. **Respeta el tope de 3** (misma lógica actual).
  - `DIFICULTAD CPU (vs máquina)`: 3 chips (😊 Fácil / 🙂 Media / 😈 Difícil), seleccionado `chip(true, PRIMARY)`.
- **Panel agrupador B**: `TU EQUIPO · toca una carta para quitarla` → fila horizontal de tarjetas (usa `FigureCard`, §6.7) 80×96 con borde por rareza.
- `DISPONIBLES · toca para añadir`: lista vertical de filas ancho completo (`panel(SURFACE,…,13)` con `border_left` 3px del color de rareza): nombre Sora 700 · 15px + "· Tipo ·" `MUTED` + ⚡ + coste `GOLD`.
Barra inferior (fija): "Menú" (`style_surface`) + "▶ Jugar" (`style_primary`, expand fill).

### 6.3 `Dex.gd` — COLECCIÓN (solo overlay UI; el modelo 3D NO se toca)
Header (fijo, centrado): "`N/16`" `PRIMARY_EDGE` 14px + nombre Sora 800 · 24px; debajo "Tipo de ataque: Ruleta" `PRIMARY_EDGE` 13px.
Fila de búsqueda (fija): campo con `UITheme.input()` + icono lupa + placeholder "Buscar…" · botón "Todas" (`chip`-azul tenue) · botón ★ (44×44 `style_surface`, estrella `GOLD`).
Cuerpo: el **modelo 3D queda igual** (déjalo). Debajo, botón ancho "▼ Ocultar info / ▲ Ver info" (`style_surface`) — ya existe la lógica en líneas 155/338, solo reestiliza.
Panel de info (`panel(PANEL_DEEP,…,16)`):
- `PASIVAS`: viñetas (punto `PRIMARY_EDGE`) con **nombre en negrita** + descripción `TEXT2` 13px.
- `EVOLUCIONES · RANK UP`: texto `MUTED` (p.ej. "— (no evoluciona)").
- `ATAQUES · probabilidad`: filas: swatch 20×20 del color del segmento + nombre + línea de puntos + `%` Sora 800. Colores reales: Azul `R_RARE`/`#4A90E2`, Blanco `#E8ECF5`, Oro `#F5C842`, Rojo `#E85555`.
Barra inferior (fija): ◄ (52×48) · "Menú" · ► (52×48), todos `style_surface`.

### 6.4 `InventoryScreen.gd` — INVENTARIO
Header (fijo): botón ← (44×44 `style_surface`) + "Inventario" Sora 800 · 24px `GOLD` + píldora "👤 USUARIO" (borde `PRIMARY_EDGE`, texto `PRIMARY_EDGE`).
Cuerpo: nota `TEXT2` 13px ("Los COFRES se abren…"). Tarjeta **Fragmentos** (`panel` con leve tinte azul): tile 🧩 + "Fragmentos / 10 fragmentos = 1 pieza" + contador a la derecha (`GOLD` 20px + "disponibles" `MUTED`). Encabezado `TU INVENTARIO`. Cuando esté vacío, **estado vacío**: `panel` con borde punteado, tile 📦 grande, "Aún no tienes piezas" Sora 800 · 17px, ayuda `MUTED`, y botón "🎁 Ir a los cofres" (`style_primary`). Cuando haya piezas, rejilla de tarjetas (reusar `FigureCard`).

### 6.5 `OnlineLobby.gd` — JUGAR EN LÍNEA
Título "Jugar en línea" centrado Sora 800 · 26px `GOLD`. Campos con label `TEXT2` 12px encima:
- "Tu nombre" → `LineEdit` con `UITheme.input()`, valor "Jugador".
- "Servidor" → `LineEdit` `input()`, `wss://…` en `TEXT2` (elipsis si desborda).
Botón **CREAR SALA** ancho, verde: `style_primary(btn, SUCCESS, 15)` (texto oscuro `Color(0.03,0.14,0.06)`).
Fila: campo "CÓDIGO" (`input()`, `letter_spacing` visual con mayúsculas) + botón "UNIRSE" (`style_primary(btn, PRIMARY)`).
Barra inferior: "← Menú" ancho `style_surface`.

### 6.6 `CharacterCreator.gd` — CREAR PERSONAJE
Header (fijo): ← + "Crear Personaje" Sora 800 · 23px `GOLD` + "⤒ Importar" (`style_surface`).
Cuerpo (scroll) en **paneles agrupadores** (`panel(PANEL_DEEP,…,16)`), cada uno con título de sección Sora 800 · 16px `SECTION`:
- **Identidad**: filas `label(82px) + campo`. Nombre/Descripción = `input()` con placeholder `MUTED`. Clase (Balanced) y Rareza (Épica, texto `R_EPIC`) = `input()` con chevron ▾ a la derecha (`OptionButton` reestilizado con `input()` como `normal`).
- **Combate**: Estamina = `input()` con valor Sora 800 · 16px + flechas ▲▼ (`SpinBox` o botones). Tipo ataque (Ruleta) y Modelo (Stone Golem) = dropdowns `input()`. Toggle "Evoluciona (Rank Up)": `CheckButton` reestilizado (pista `PRIMARY` cuando ON) + label `GOLD`.
- **Pasivas (máx. 3)**: nota `MUTED` + `GridContainer(columns=2)` de chips: nombre 13px + botón ⓘ circular (`i` en `PRIMARY_EDGE`, borde `#3A4670`). Activo = fondo `Color(PRIMARY,.16)` + borde `PRIMARY_EDGE`.
- **Resistencias a estados (máx. 2)**: nota + `GridContainer(columns=3)` de 13 chips (Miedo, Debilitado, Paralizado, Inmovilizado, Quemadura, Veneno, Congelado, Silencio, Confusión, Sueño, Maldición, Marcado, Escudo Roto). Seleccionado = `chip`-azul tenue.
- **Pool de ataque**: nota + tarjetas por segmento (`panel(INPUT_BG,…,13)`): fila 1 = dropdown color (swatch + "Blanco/Azul/Rojo") + nombre; fila 2 = Daño / ★ / % (cada uno mini-input con ▲▼; `%` en `GOLD`) + ⓘ + ✗ (rojo `DANGER`); fila 3 = dropdown efecto ("Ninguno"). Abajo: "+ Segmento" (`chip`-azul tenue) + "Total: 100%" en `SUCCESS`.
Barra inferior (fija): línea de validación en `DANGER` ("✗ Inválido · ✗ Falta el nombre.") + botón "Guardar figura" (deshabilitado = `style_surface` `disabled`; habilitado = `style_primary`).

### 6.7 `FigureCard.gd` — TARJETAS (sin tocar `_portrait()`/arte)
- Borde de la tarjeta = **color de rareza** (`R_COMMON/R_RARE/R_EPIC/R_LEGEND`), 1.5px, radio 13.
- Fondo `#12172E`; contenido: retrato (déjalo como está) + nombre centrado Sora 700 · 11px `TEXT`.
- Tamaños: equipo/disponibles 80×96; rejillas de colección adaptables.

---

## 7. Checklist de verificación

- [ ] `Sora.ttf` y `Manrope.ttf` presentes en `res://assets/fonts/`.
- [ ] Helpers `section / icon_tile / input / chip` pegados en `UITheme.gd`.
- [ ] Cada pantalla = header fijo + `ScrollContainer` + barra inferior fija.
- [ ] Márgenes 16px, separación de secciones 13px, radios consistentes.
- [ ] Todos los emoji enmarcados con `icon_tile`.
- [ ] Chips seleccionados: mapa/dificultad azul, modificadores naranja.
- [ ] Encabezados de sección en azul MAYÚSCULAS (`UITheme.section`).
- [ ] **Ningún botón eliminado**; todas las señales `pressed` intactas.
- [ ] Modelos 3D (Home, Dex) y combate SIN cambios.
- [ ] Comparar cada pantalla con `NodeChess Menus.dc.html`.
- [ ] Scroll VISIBLE en 'Tu equipo' (horizontal) y 'Disponibles' (acotado).
- [ ] ⓘ en cada modificador y cada estado → popup con descripción REAL.
- [ ] Cadena de evolución visible al activar el toggle en Crear.
- [ ] Aviso de validación con contenedor/fondo propio + icono ⚠.
- [ ] Botón JUGAR con halo pulsante + barrido + respiración (sin romper `pressed`).
- [ ] Tienda: categorías Modelos/Ataques/Pasivas/Tipos de ataque/Partes.
- [ ] Perfil: stats (ganadas/perdidas/%/racha) + favoritos (mazo/mapa/figura).

---

## 8. Abrir la referencia visual
Abre **`NodeChess Menus.dc.html`** en un navegador (Chrome/Edge). Navega desde Home a cada pantalla con los botones de la rejilla. Es la fuente de verdad de orden, tamaños y colores. Los valores hex del mock ya están mapeados a constantes de `UITheme` arriba, así que **prefiere las constantes** (mantiene todo consistente y fácil de re-tematizar).

---

## 9. Correcciones de esta revisión (v2)

### 9.1 Scroll VISIBLE
- **Tu equipo** → `ScrollContainer` horizontal con barra visible + degradado lateral derecho + chevron ► como pista de que hay más. En Godot: `horizontal_scroll_mode = SCROLL_MODE_SHOW_ALWAYS` (o tematiza la `HScrollBar`), y da `custom_minimum_size = Vector2(80,96)` a cada `FigureCard` para que desborde y el scroll aparezca.
- **Disponibles** → lista acotada (`custom_minimum_size.y`/`max` ~210px) dentro de un `ScrollContainer` vertical con barra visible.
- **Barra estilizada** (tema global de `ScrollBar`): grabber `#33406B`, fondo `#0B1024`, grosor 7px, esquinas 99px.

### 9.2 ⓘ en Modificadores y Resistencias a estados
- Cada chip lleva un botón **ⓘ** (círculo: 20px en modificadores, 16px en estados, esquina/borde derecho). Al tocarlo abre un **popup** con `{ título, descripción }`.
- En Godot: añade un `Button` circular por chip; en `pressed` muestra un `PopupPanel`/panel propio (fondo `SURFACE`, borde `#2C3760`, radio 18, con Label título Sora 800 + Label cuerpo Manrope 500 + botón "Entendido").
- ⚠️ **Las descripciones deben salir de tus datos reales**: `GameState.MODIFIERS[i].desc` y el registro de estados. Las del mock son de ejemplo — sustitúyelas por las oficiales.

### 9.3 Cadena de evolución (Crear Personaje)
- Al activar **"Evoluciona (Rank Up)"** se revela el bloque **"SE CONVIERTE EN"**: fila horizontal `Base → (Elegir figura + Requisito ▾) → [+ Rango]`.
- En Godot: un contenedor `visible = evolves` (se muestra/oculta con el toggle) con un `HBoxContainer` scrolleable: tarjeta BASE (figura actual, borde `GOLD`), flecha →, tarjeta RANGO 1 (borde punteado, `OptionButton` de figura destino + campo "Requisito"), y botón `+ Rango` para encadenar más niveles.
- Guarda cada eslabón como `{ figura_id, requisito }`. No toca combate ni modelos.

### 9.4 Alerta de validación con contenedor
- El aviso deja de ser texto suelto: ahora es un **banner** con fondo `rgba(DANGER,.12)`, borde `rgba(DANGER,.42)`, radio 12, icono ⚠ y el mensaje. En Godot: `PanelContainer` con `StyleBoxFlat` (bg DANGER α0.12, border DANGER, radius 12, pad 11/13) + `HBox`(icono ⚠ + `Label`). Aplica el mismo patrón a cualquier alerta/toast del juego.

### 9.5 Botón JUGAR "hipnótico" (invita a tocarlo)
Tres capas, **sin cambiar la señal `pressed`**:
1. **Respiración**: `Tween` en bucle (`set_loops()`) sobre `scale` 1.0↔1.02, 2.6s, `TRANS_SINE`; pon el `pivot_offset` al centro del botón.
2. **Halo pulsante**: un `Panel`/`TextureRect` DETRÁS del botón con glow (StyleBoxFlat `shadow_size` alto y `shadow_color` PRIMARY, o textura radial); `Tween` de `modulate:a` 0.3↔0.72.
3. **Barrido de brillo**: un `ColorRect` con gradiente diagonal blanco encima del botón, con `clip_contents=true` en el botón; `Tween` de `position:x` de fuera-izq → fuera-der en bucle (~2.8s).
Opcional: leve `scale` 0.96 en `button_down` para "juice".

---

## 10. Esquema — TIENDA (nueva pantalla / sección)
> Es un **esquema**: define la estructura; tú decides los ítems concretos de cada categoría.
- **Nav inferior** con **Tienda** activa (Home / Tienda / Perfil).
- **Header**: "Tienda" Sora 800 · 24px + píldoras de moneda (oro / gema).
- **Chips de categoría** (scroll horizontal, `UITheme.chip`): **Modelos · Ataques · Pasivas · Tipos de ataque · Partes**. (Estas son las categorías pedidas; el primero activo.)
- **Rejilla 2-col** de tarjetas de ítem (placeholder "Elemento"): tile de icono con color de **rareza** + nombre + etiqueta de rareza + botón de **precio** (icono moneda/gema + cantidad). Muestra ~6 por categoría.
- Rarezas: `R_COMMON / R_RARE / R_EPIC / R_LEGEND`. Precio en oro o gema según el ítem.
- **Qué rellenas tú**: por cada categoría, la lista real de piezas (p. ej. en "Modelos": Stone Golem, Ironclad Knight…; en "Ataques": Bedrock Wall, Boulder Fist…; en "Pasivas": Bedrock, Counter-Stone…; en "Tipos de ataque": Ruleta, Dado D6, Doble Moneda…; en "Partes": piezas del creador). El diseño (tarjeta + precio) se mantiene igual para todas.

---

## 11. Esquema — PERFIL (nueva pantalla / sección)
- **Nav inferior** con **Perfil** activa.
- **Tarjeta de identidad**: avatar `P1` (aro dorado) + nombre "Jugador" + nivel + barra XP + botón editar (lápiz).
- **ESTADÍSTICAS** (rejilla 2×2, cada una `panel` con valor grande + etiqueta): **Ganadas** (`SUCCESS`) · **Perdidas** (`DANGER`) · **% Victorias** (`PRIMARY_EDGE`) · **Mejor racha** (`ORANGE`). Amplía con las que quieras (Trofeos, Partidas jugadas, KOs…).
- **FAVORITOS** (filas: tile de icono tintado + etiqueta + valor + chevron): **Mazo favorito** · **Mapa favorito** · **Figura favorita**. Puedes añadir "Tipo de ataque favorito", "Clase favorita", etc.
- **Qué rellenas tú**: enlaza cada dato a tus contadores reales (partidas, mazo más usado, mapa más jugado, figura más usada). El layout no cambia.

---

## 12. Novedades para pegar en `UITheme.gd` (además de §3)
```gdscript
## Popup de información (ⓘ de modificadores/estados). Reusa panel() para el marco.
static func info_popup_box() -> StyleBoxFlat:
	return panel(SURFACE, Color(0.17,0.22,0.38), 18, 1, 16)

## Banner de alerta (validación / error). tint = DANGER por defecto.
static func alert_box(tint := DANGER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(tint.r, tint.g, tint.b, 0.12)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(1)
	sb.border_color = Color(tint.r, tint.g, tint.b, 0.42)
	sb.set_content_margin_all(12)
	return sb
```
