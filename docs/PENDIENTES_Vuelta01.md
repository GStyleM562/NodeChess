# PENDIENTES — Vuelta 01 (prototipo para pruebas internas públicas)

> Los 30 puntos faltantes, agrupados en FASES ordenadas por dependencia para
> **no retrabajar**: primero lo que cambia el MOTOR y el ESQUEMA de las figuras
> (todo lo demás se construye encima), luego contenido, luego CPU/online, luego
> móvil/UX, assets, y al final onboarding + economía. Anuncios/monetización
> real quedan para la Vuelta 02.
>
> Cada punto lleva: (#id de la revisión) · esfuerzo S/M/L · de qué depende.
> Estado actual del proyecto: `docs/CHANGELOG.md`.

---

## FASE 0 — Quick wins (sin dependencias, evitan dolor inmediato)

| Punto | Esf. | Notas |
|---|---|---|
| (#20) **Pinch-to-zoom táctil** en el tablero | S | Hoy solo rueda del mouse: en teléfono NO se puede hacer zoom. `InputEventMagnifyGesture` + fallback de 2 dedos. Cero riesgo de retrabajo. |
| (#30) **Decisión: cooldown de K.O.** | S | GDD dice "5 turnos"; hoy 6 medio-turnos (3 rondas). DECIDIR y fijar constante + test. Antes del tutorial para no documentarlo dos veces. |
| (#24) **SFX reales** | S | Todo cableado (11 carpetas). Solo faltan TUS archivos .mp3/.wav. Sueltalos cuando quieras — cualquier momento sirve. |
| (#25) **Regenerar GLB de Storm Valkyrie** | S | Tarea Meshy (tuya). Mientras, sigue excluida de la CPU. |

## FASE 1 — Motor y esquema de figura (la base: cambiarlo después rompe todo)

> Regla de oro: **todo lo que toca el diccionario de figura o GameState va
> primero**, porque Creador, validador, códigos NCFIG, IA, online y tutorial
> dependen de esa forma final.

| Punto | Esf. | Depende de | Notas |
|---|---|---|---|
| (#1) **Mazo de 6 figuras** (GDD exacto) | M | — | `DECK_SIZE 5→6`. Toca: Deck Builder, banca (6+K.O. caben?), online `_half`, equipo CPU, balance de mapas (re-verificar distancias/candados), tests. Hacerlo ANTES de balancear nada más. |
| (#3) **Resistencias a estados** por figura | M | — | Nuevo campo `resists: []` en el esquema + chequeo en `apply_status` + UI en Creador/Dex + pieza de inventario nueva + validador. Cambia el esquema ⇒ temprano (los códigos NCFIG toleran campos nuevos, pero mejor de una vez). |
| (#4) **Rasgos de movimiento faltantes**: Hover, Fast Recovery | S/M | — | Hover = ignora candados/terreno (no obstáculos-figura); Fast Recovery = −1 ronda al K.O. Pasivas nuevas en el catálogo (piezas de inventario incluidas). |
| (#5) **Desplazamientos faltantes**: Dash, Retreat, Teleport | M | — | Nuevos `disp` en segmentos + animaciones + regla GDD "Teleport/Swap a meta ⇒ chequeo de rodeo ANTES de victoria". Actualizar FX_OPTS del Creador. |
| (#2) **Buff nodes con CARGA** (GDD completo) | L | #1 (balance) | Cargas por turnos parado (irse reinicia), efecto al completar (Ofensivo/Defensivo/Utilidad/Economía por mapa), cooldown y propiedad. Toca GameState + visual de progreso en tablero + IA (prioridad 6) + online (estado determinista, sin mensajes nuevos). |

**Cierre de fase:** suite completa + partida online de humo. El esquema de figura queda CONGELADO para la vuelta.

## FASE 2 — Contenido sobre el motor congelado

| Punto | Esf. | Depende de | Notas |
|---|---|---|---|
| (#19) **DECISIÓN: ¿los mazos exigen poseer las figuras?** | S | — | Decidir ANTES de #7 para no rehacer el builder. Propuesta: modo usuario solo alinea figuras poseídas (integradas se "poseen" via pieza `model:`) + las custom propias. |
| (#6) **Catálogo de modificadores** (trampas, revive, escudo, control, economía) | L | Fase 1 | Trampas = estado en nodo oculto hasta pisarlo (online: viaja como acción). Revive = saca de ko_bench. 8–12 modificadores con costo 1–10. IA los usa (ampliar prioridad 4). |
| (#9) **Más pasivas/triggers** (OnDeploy, BuffNode, Goal, OncePerMatch, Cooldown) | M | Fase 1, #2 | Infra de triggers genérica primero; luego 6–10 pasivas nuevas como piezas. |
| (#7) **Mazos múltiples (hasta 20) + código de mazo** | M | #1, #19 | Pestañas en Deck Builder, `loadout.json` versionado a lista, código NCDECK1 (reusar infra NCFIG). |
| (#8) **Colección 2.0**: búsqueda, filtros, favoritos, % completado, enciclopedia | M | #19 | Dex con barra de filtros + estrella de favorito (persistente) + contador de posesión por rareza. Skins quedan Vuelta 02. |

## FASE 3 — CPU y Online de calidad de prueba pública

| Punto | Esf. | Depende de | Notas |
|---|---|---|---|
| (#10) **Selector de dificultad** (Fácil/Media/Difícil) | S | — | UI en Deck Builder o Configuración → `bot_difficulty` 0/1/2. |
| (#11) **Personalidades de bot** (Agresivo, Defensivo, Goal Rusher, Rank-Up Lover) | M | Fase 1–2 | Re-ponderar los pesos del score por personalidad (ya documentado en AI_CPU.md). Elegirla al azar por partida para variedad. |
| (#13) **Timer por turno online** | M | Fase 1 | 60–90 s por turno; al expirar pasa el turno solo (aviso a ambos). El protocolo ya contempla "end"; sumar countdown UI sincronizado por timestamps. |
| (#14) **Reconexión a partida** | L | #13 | Guardar estado local + room re-join en el relay (server: mantener sala ~90 s tras desconexión; re-emitir últimas acciones). Cambia protocolo ⇒ hacerlo JUNTO a #13 para versionar el server una sola vez. |
| (#15) **Revancha online** | S | #13/#14 | Mensaje "rematch" en la misma sala; si ambos aceptan, nuevo seed y a jugar. Misma versión de protocolo que #13/#14. |

**Cierre de fase:** server del relay se redeploya UNA vez con timer+resume+rematch.

## FASE 4 — Móvil / UX transversal (con pantallas ya estables)

| Punto | Esf. | Depende de | Notas |
|---|---|---|---|
| (#21) **Velocidad ×2 y saltar animación de combate** | S/M | — | Toggle en Configuración + botón "⏭" durante el combate (multiplicar timers/tweens del overlay y cutaway). |
| (#22) **Modo daltónico** | M | — | Paleta alternativa para los 5 colores de ataque + formas/íconos en segmentos (no solo color). Persistente en Settings. |
| (#23) **Iconografía propia** (piezas, cofres, botones) | M | Diseño tuyo/Meshy | Sustituir emojis por sprites. Mientras tanto los emojis funcionan. |

## FASE 5 — Assets y presentación del mapa

| Punto | Esf. | Depende de | Notas |
|---|---|---|---|
| (#26) **Isla como asset + decoración de borde** (rocas/árboles) | S/M | Assets tuyos | Ya hay carpetas (`island_platform/`, `rock_small/`, `rock_big/`, `tree_small/`); el GLB actual de island_platform es un tramo de camino — regenerar. El cableado es rápido (mismo loader). |
| (#27) **Portal visual en Túneles + 1–2 arquetipos de mapa nuevos** | M | Fase 1 (#2 buff final) | Portal con anillo/efecto; mapas nuevos ya con reglas finales (distancia ≥6, candados, automorfismo — test existente los valida solos). |
| (#28) **Animaciones de ataque por figura** | M/L | Assets Meshy tuyos | Clips extra por figura (cast/ranged/etc.). El sistema de clips ya lo soporta — es trabajo de assets + mapear. |

## FASE 6 — Onboarding y cierre de la vuelta

| Punto | Esf. | Depende de | Notas |
|---|---|---|---|
| (#16) **Cofre por nivel** (en vez de piezas directas) | S | Fase 2 | Al subir de nivel: cofre gratis reclamable en el lobby (reusar animación). |
| (#12) **Tutorial jugable** (1 bueno, no 10) | L | TODO lo anterior | Partida guiada contra CPU pasiva: desplegar → mover → atacar → salto → rodeo → buff → ganar. Se escribe AL FINAL para no re-grabarlo con cada cambio de regla. |
| (#17) **Tienda + monedas/gemas GDD** | L | Vuelta 02 | El sistema piezas/fragmentos la sustituye por ahora. Diseñar monetización real en Vuelta 02 (con anuncios). |
| (#18) **Misiones diarias / pity** | M | Vuelta 02 | GDD las marca "MVP disabled". |
| (#29) **Guardado en la nube / cuentas** | L | Vuelta 02 | Hoy: local + backup Google + códigos de respaldo. Suficiente para pruebas internas. |

---

## Decisiones que necesito de TI antes de arrancar
1. (#30) K.O.: ¿3 rondas como hoy, o "5 turnos" del GDD? (propongo dejar 3 rondas: se siente bien)
2. (#19) ¿El Deck Builder en modo usuario exige poseer las figuras? (propongo SÍ)
3. (#1) Confirmar mazo de 6 (afecta balance de todo lo que sigue).

## Tareas de TU lado (paralelas, no bloquean)
- SFX (11 carpetas en `game/assets/audio/sfx/`).
- Meshy: Storm Valkyrie nueva, isla real, rocas/árboles, (opcional) clips de ataque extra.
- Probar la v12 en dos teléfonos (online) y reportar.

## Definition of Done — Vuelta 01 lista para prueba interna pública
- [ ] Fases 0–4 completas y Fase 5 con al menos isla+decoración.
- [ ] Tutorial (#12) jugable de inicio a fin.
- [ ] Suite headless completa en verde + 1 partida online real entre 2 teléfonos sin desync.
- [ ] 60 fps (o 30 estables) en un gama media con tablero 3D.
- [ ] CHANGELOG actualizado y versionCode nuevo subido a Play (prueba interna).
