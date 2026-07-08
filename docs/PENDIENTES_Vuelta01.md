# PENDIENTES — Vuelta 01 (prototipo para pruebas internas públicas)

> **ESTADO 2026-07-08: VUELTA 01 COMPLETADA (F0–F6).** ✅ = hecho y con test;
> 🎨 = espera SOLO assets de Gojan (el cableado ya existe); ⏭ = pospuesto a
> Vuelta 02 por decisión. Detalle de lo construido: `docs/CHANGELOG.md`.
>
> Los 30 puntos faltantes, agrupados en FASES ordenadas por dependencia para
> **no retrabajar**: primero lo que cambia el MOTOR y el ESQUEMA de las figuras
> (todo lo demás se construye encima), luego contenido, luego CPU/online, luego
> móvil/UX, assets, y al final onboarding + economía. Anuncios/monetización
> real quedan para la Vuelta 02.
>
> Cada punto lleva: (#id de la revisión) · esfuerzo S/M/L · de qué depende.

---

## FASE 0 — Quick wins (sin dependencias, evitan dolor inmediato)

| Punto | Esf. | Notas |
|---|---|---|
| ✅ (#20) **Pinch-to-zoom táctil** en el tablero | S | Gesto de 2 dedos (`InputEventMagnifyGesture`), altura 7–26. |
| ✅ (#30) **Decisión: cooldown de K.O.** | S | DECIDIDO: 3 rondas (6 medio-turnos, `KO_COOLDOWN 6`); Fast Recovery −2. |
| 🎨 (#24) **SFX reales** | S | Todo cableado (11 carpetas). Solo faltan TUS archivos .mp3/.wav. |
| 🎨 (#25) **Regenerar GLB de Storm Valkyrie** | S | Tarea Meshy (tuya). Mientras, sigue excluida de la CPU. |

## FASE 1 — Motor y esquema de figura (la base: cambiarlo después rompe todo)

> Regla de oro: **todo lo que toca el diccionario de figura o GameState va
> primero**, porque Creador, validador, códigos NCFIG, IA, online y tutorial
> dependen de esa forma final.

| Punto | Esf. | Depende de | Notas |
|---|---|---|---|
| ✅ (#1) **Mazo de 6 figuras** (GDD exacto) | M | — | `DECK_SIZE = 6` en builder, banca (scroll horizontal), online y CPU. |
| ✅ (#3) **Resistencias a estados** por figura | M | — | `resists: []` (máx 2) + "RESISTIÓ" en combate + Creador/Dex/validador + pieza `resist:*`. |
| ✅ (#4) **Hover y Fast Recovery** | S/M | — | Hover cruza candados/terreno sin parar en ellos; Fast Recovery K.O. −2 medio-turnos. |
| ✅ (#5) **Dash, Retreat, Teleport** | M | — | Deterministas (dash mueve al ganador; teleport a entrada propia libre) + FX_OPTS del Creador. |
| ✅ (#2) **Buff nodes con CARGA** (GDD completo) | L | #1 (balance) | 2 finales de turno parado → POTENCIADA permanente (+20/+1★ hasta K.O.); cooldown 10 medio-turnos; progreso visible; determinista online. |

**Cierre de fase:** ✅ suite completa verde (test_v1_fase1: 26 checks). El esquema de figura quedó CONGELADO para la vuelta.

## FASE 2 — Contenido sobre el motor congelado

| Punto | Esf. | Depende de | Notas |
|---|---|---|---|
| ✅ (#19) **DECISIÓN: ¿los mazos exigen poseer las figuras?** | S | — | DECIDIDO: SÍ en modo usuario (integradas via pieza `model:`, customs propias siempre); filas 🔒 y jugar bloqueado. |
| ✅ (#6) **Catálogo de modificadores** | L | Fase 1 | 10 en total: + iron_wall, shield, haste, energy_drain, revive, trap (nodo oculto con objetivo, viaja como acción). La IA difícil usa revive/power_surge. |
| ✅ (#9) **Más pasivas** | M | Fase 1, #2 | Warcry, Goalkeeper (+20/+1★ en su meta), Scavenger (+2 energía por K.O.), Hover, Fast Recovery — todas como piezas. |
| ✅ (#7) **Mazos múltiples (hasta 20) + código de mazo** | M | #1, #19 | Pestañas + duplicar/borrar + código NCDECK1 (gzip+base64) exportar/importar; `loadout.json` v2 migra v1. |
| ✅ (#8) **Colección 2.0** | M | #19 | Búsqueda, filtros (todas/⭐/poseídas/tuyas ✎), favoritos persistentes, % completado, línea de resistencias. Skins → Vuelta 02. |

## FASE 3 — CPU y Online de calidad de prueba pública

| Punto | Esf. | Depende de | Notas |
|---|---|---|---|
| ✅ (#10) **Selector de dificultad** | S | — | Chips 😌/🙂/😈 en el Deck Builder → `Settings.cpu_level` → `bot_difficulty`. |
| ✅ (#11) **Personalidades de bot** | M | Fase 1–2 | 5 (equilibrada/agresiva/defensiva/corredora/cazadora) re-ponderando score/umbral; al azar por partida + banner. |
| ✅ (#13) **Timer por turno online** | M | Fase 1 | 75 s con ⏱ en pantalla; al expirar pasa solo (banner a ambos). |
| ✅ (#14) **Reconexión a partida** | L | #13 | Cliente reconecta + re-join; el server guarda el asiento 90 s y avisa al rival (banner de pausa). |
| ✅ (#15) **Revancha online** | S | #13/#14 | Botón en pantalla final; ambos aceptan → nuevo seed, misma sala y mazos. |

**Cierre de fase:** ✅ server redeployado UNA vez con timer+rejoin+rematch (validado local NET_OK). ⚠ Ambos teléfonos necesitan la build nueva (el protocolo creció). |

## FASE 4 — Móvil / UX transversal (con pantallas ya estables)

| Punto | Esf. | Depende de | Notas |
|---|---|---|---|
| ✅ (#21) **Velocidad ×2 y saltar animación de combate** | S/M | — | Toggle ⏩ en Configuración + botón ⏭ en combate (Engine.time_scale; el reloj online no se drena). |
| ✅ (#22) **Modo daltónico** | M | — | Paleta Okabe-Ito + símbolos ■◆✦⬟✖ en segmentos; persistente. |
| 🎨 (#23) **Iconografía propia** (piezas, cofres, botones) | M | Diseño tuyo/Meshy | Sustituir emojis por sprites. Mientras tanto los emojis funcionan. |

## FASE 5 — Assets y presentación del mapa

| Punto | Esf. | Depende de | Notas |
|---|---|---|---|
| 🎨 (#26) **Isla como asset + decoración de borde** (rocas/árboles) | S/M | Assets tuyos | Ya hay carpetas (`island_platform/`, `rock_small/`, `rock_big/`, `tree_small/`); el GLB actual de island_platform es un tramo de camino — regenerar. El cableado es rápido (mismo loader). |
| ✅ (#27) **Portal visual en Túneles + mapa nuevo** | M | Fase 1 (#2 buff final) | Toro violeta girando en los teleporters + mapa "Cruce" (5º), validado por test de reglas (distancia, candados, automorfismo). |
| 🎨 (#28) **Animaciones de ataque por figura** | M/L | Assets Meshy tuyos | Clips extra por figura (cast/ranged/etc.). El sistema de clips ya lo soporta — es trabajo de assets + mapear. |

## FASE 6 — Onboarding y cierre de la vuelta

| Punto | Esf. | Depende de | Notas |
|---|---|---|---|
| ✅ (#16) **Cofre por nivel** (en vez de piezas directas) | S | Fase 2 | Subir de nivel → cofre 🏅 reclamable en el lobby (3 piezas, 1 premium); chip en la pantalla de victoria. |
| ✅ (#12) **Tutorial jugable** (1 bueno, no 10) | L | TODO lo anterior | Primera partida (o 🎓 en Configuración): panel de 6 pasos contra muñeco de práctica (`bot_difficulty -1`: camina, JAMÁS ataca); al ganar se marca hecho. |
| ⏭ (#17) **Tienda + monedas/gemas GDD** | L | Vuelta 02 | El sistema piezas/fragmentos la sustituye por ahora. Diseñar monetización real en Vuelta 02 (con anuncios). |
| ⏭ (#18) **Misiones diarias / pity** | M | Vuelta 02 | GDD las marca "MVP disabled". |
| ⏭ (#29) **Guardado en la nube / cuentas** | L | Vuelta 02 | Hoy: local + backup Google + códigos de respaldo. Suficiente para pruebas internas. |

---

## Decisiones tomadas (defaults aplicados, avísame si quieres cambiarlas)
1. ✅ (#30) K.O.: 3 rondas (6 medio-turnos), como se sentía bien.
2. ✅ (#19) Deck Builder en modo usuario SÍ exige poseer las figuras.
3. ✅ (#1) Mazo de 6 confirmado.

## Tareas de TU lado (paralelas, no bloquean)
- SFX (11 carpetas en `game/assets/audio/sfx/`).
- Meshy: Storm Valkyrie nueva, isla real, rocas/árboles, (opcional) clips de ataque extra.
- Probar la build nueva en DOS teléfonos (online). ⚠ El protocolo del relay creció
  (rejoin/peer/rematch): ambos teléfonos deben tener ESTA build, la v12 ya no empareja bien.

## Definition of Done — Vuelta 01 lista para prueba interna pública
- [x] Fases 0–4 completas; Fase 5 con portal + mapa nuevo (isla/decoración = assets 🎨).
- [x] Tutorial (#12) jugable de inicio a fin.
- [x] Suite headless completa en verde (42/42, incl. tutorial y relay local NET_OK).
- [ ] 1 partida online real entre 2 teléfonos sin desync (te toca probar).
- [ ] 60 fps (o 30 estables) en un gama media con tablero 3D (te toca probar).
- [x] CHANGELOG actualizado; .aab nuevo generado — falta subirlo a Play (tuyo).
