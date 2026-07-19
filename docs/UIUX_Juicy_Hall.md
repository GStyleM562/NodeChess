# NodeChess — Reglas de diseño "JUICY HALL" (UI/UX/HUD)

> **CANÓNICO desde 2026-07-19.** Estas reglas gobiernan TODA la interfaz del
> juego (menús, pantallas, HUD del tablero). Sustituyen la paleta oscura del
> handoff anterior (Part 6); la ESTRUCTURA de aquel handoff (jerarquía,
> scroll, secciones, tamaños táctiles) sigue vigente — solo cambió la piel.
> Referencia visual: mockups estilo TCG Pocket que pasó Gojan (2026-07-18/19).
> Fuente de verdad en código: `game/scripts/UITheme.gd` (tokens + fábricas).

---

## 1. Los 6 principios (memorizables)

1. **Hall luminoso**: fondo amarillo cálido, NUNCA blanco frío ni gris.
   Las pantallas se sienten como el vestíbulo soleado de un juego alegre.
2. **Tarjeta crema con LABIO 3D**: todo panel/tarjeta/botón es crema con un
   borde inferior GRUESO tintado (y fino en los otros lados). El labio es lo
   que hace que todo se vea "presionable" y con volumen.
3. **Botón físico**: los botones primarios son EXTRUIDOS (cara de color viva +
   labio inferior oscuro de la misma familia). Al presionar, el labio se
   encoge y la cara BAJA (content margins del estado pressed). Las tarjetas
   táctiles se hunden (scale 0.94).
4. **Texto TINTA**: el texto es tinta oscura cálida sobre claro. JAMÁS texto
   blanco/claro sobre crema. Sobre rellenos de color saturado: blanco (o tinta
   oscura sobre dorado/verde claro).
5. **Acentos PROFUNDOS**: los colores de acento se usan en versión profunda
   (ámbar en vez de amarillo pastel, verde bosque en vez de menta) para que
   sean legibles sobre claro tanto de relleno como de texto.
6. **Sombra CÁLIDA**: las sombras son marrón-doradas translúcidas y suaves
   (`_warm_shadow`), nunca negras duras.

## 2. Paleta (tokens en UITheme.gd — usar SIEMPRE los tokens, no hex sueltos)

| Token | Valor | Uso |
|---|---|---|
| `BG_DEEP` / `BG` | amarillo cálido `(0.972,0.925,0.72)` | fondo de pantalla/entornos 3D de menú |
| `SURFACE` | crema `(1.0,0.985,0.94)` | tarjetas, paneles, botones secundarios |
| `SURFACE2` | crema honda | segundo nivel (pills, filas) |
| `PANEL_DEEP` | crema-tan | paneles agrupadores |
| `INPUT_BG` | casi blanco | campos de texto/SpinBox |
| `BORDER` / `GROUP_BORDER` | tan cálido | bordes/labios neutros |
| `TEXT` | TINTA `(0.24,0.21,0.13)` | texto principal |
| `TEXT2` / `MUTED` | tinta suave / gris cálido | secundario / hints |
| `PRIMARY` | azul `#2E6BFF` | acción principal |
| `GOLD` | ámbar profundo | títulos, recompensas, legendario |
| `SUCCESS` / `DANGER` / `ORANGE` / `ENERGY` | profundos | semántica estándar |
| Rarezas `R_*` | profundas | común gris / rara azul / épica púrpura / legendaria ámbar |

Colores de MODO del Home: `MODE_BLUE` (Probar), `MODE_GOLD` (BATALLA),
`MODE_PURPLE` (Online) — en `MainMenu.gd`.

## 3. Fábricas (no reinventar StyleBoxes a mano)

- `UITheme.panel(bg, border, radius, bw, pad)` → tarjeta con labio (bw+4 abajo).
- `UITheme.primary(accent)` / `style_primary(b, accent)` → botón extruido con
  labio `accent.darkened(0.32)` y estado pressed que "baja".
- `UITheme.style_surface(b, ...)` → botón secundario crema con labio.
- `UITheme.chip(selected, accent)` → chip conmutable (seleccionado = extruido).
- `UITheme.input()` → campo blanco. Para **SpinBox**, estilar su
  `get_line_edit()` (ver `CharacterCreator._style_spin` — el default de Godot
  es oscuro y se ve como un tajo negro).
- `UITheme.pill / icon_tile / group_panel / alert_box / section` → igual que
  antes, ya en clave clara.
- En el Home además: `_card_style` (tarjeta + labio con acento), `_gloss`
  (brillo superior en degradado para botones grandes), `_vgrad` (cielo/suelo).

## 4. Reglas duras (checklist al crear CUALQUIER pantalla/elemento)

- [ ] Fondo de pantalla = `BG_DEEP` (o entorno 3D con ese color ambiente cálido).
- [ ] Todo Label lleva color EXPLÍCITO vía `UITheme.label(...)` — el default de
      Godot es BLANCO y desaparece sobre crema.
- [ ] Todo PanelContainer lleva stylebox EXPLÍCITO — el default de Godot es
      gris oscuro (franja fea).
- [ ] Botones: `UITheme.button_font` (incluye `font_disabled_color` correcto)
      + `style_primary`/`style_surface`/`chip`.
- [ ] Nada de texto claro sobre crema; nada de paneles oscuros salvo:
      **combate** (overlay/ruleta conserva su dramatización oscura a propósito)
      y el **tablero 3D** (arte del juego; su HUD SÍ es claro).
- [ ] Dims de modales: negro translúcido está bien (0.55–0.75).
- [ ] Cada sección/función tiene UN solo punto de entrada (sin botones
      duplicados); si dos cosas van de la mano, una vive DENTRO de la otra
      (ej. cofres dentro de 🎁 Recompensas; mazos dentro de ⚔ BATALLA).
- [ ] Avisos = punto rojo (14px, borde blanco 2px) arriba-derecha de la tarjeta.
- [ ] Verificar con CAPTURA REAL 540×960 (`--rendering-driver opengl3`) antes
      de commitear una pantalla nueva o retocada.

## 5. Trampas de Godot que ya nos mordieron (no repetir)

- **PanelContainer estira a TODOS sus hijos**: un punto rojo/badge anclado se
  vuelve tarjeta completa. Usar `Control` plano como raíz y un `Panel` de
  fondo (ver `MainMenu._rail_card`).
- **CanvasLayer NO hereda `visible` del Control padre**: para ocultar un modal
  pre-construido, el modal debe SER el CanvasLayer.
- **Labels/paneles sin estilo usan el theme oscuro por defecto de Godot** →
  blanco invisible / franjas grises (checklist §4).
- **SpinBox**: estilar su LineEdit interno.
- El click global de botones ya lo pone `UITheme.button_font` (no añadir otro).

## 6. Dónde NO aplica (excepciones deliberadas)

- **Overlay de combate / presentación de ataques** (`CombatOverlay`,
  `AttackPresenter`): oscuro cinematográfico, intencional.
- **El tablero 3D y sus materiales** (nodos, candados, marcos): arte de juego;
  el color de nodo COMUNICA reglas. Solo su HUD (paneles flotantes, banners,
  banca, barra de modificadores) sigue el tema claro.
