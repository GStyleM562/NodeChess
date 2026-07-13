# PENDIENTES — Vuelta 02 (lo que queda POR agregar)

> Estado tras cerrar la Vuelta01 + economía + FULL tutorial + Modo Robot.
> Última revisión: 2026-07-13. Cruzado contra el GDD completo
> (`GDD_Context_Summary.md` y Parts 1–5), el CHANGELOG y los docs de
> balance/testing. Prioridades: **P0** = para la prueba pública ·
> **P1** = para el lanzamiento · **P2** = post-lanzamiento / si hay tracción.

---

## 🤖 P0 — Testing (el plan: `PLAN_Testing.md`)
| Qué | Estado |
|---|---|
| **Modo Robot en la app** | ✅ HECHO (`AutoTester.gd`, commit 4946df1): botón admin, tour real (economía→creador→mazos→cofres→partidas CPU vs CPU) con log `[PASS]/[FAIL]` + reporte. Verificado 34/0. |
| **Burn-in** | ✅ HECHO (botón "🔥 Burn-in", 10 partidas con fps/memoria). |
| **⚠ HUECO — el robot NO conduce las lecciones del tutorial** | Ni `AutoTester` ni `test_full_tutorial` instancian Board3D para RECORRER cada una de las 11 lecciones paso a paso. El crash del marcador 👉 (8fd3d29) vivió justo ahí y fue invisible a la suite. **Prioridad alta**: añadir al robot un paso que cargue cada lección, avance sus pasos y ejecute la acción de cada uno (cazaría tweens huérfanos, gates rotos, nodos inválidos EN VIVO). |
| **Checklist humana** | Pasar la lista SI-O-SI completa en 2 teléfonos antes de cada subida a Play. |
| **Prueba de ACTUALIZACIÓN** | Instalar versión vieja → jugar → actualizar → verificar que NO se pierde nada (inventario/mazos/customs/nivel). Nunca la hemos hecho formalmente. |

## 🎨 P0 — Assets (lado de GOJAN, el código ya los espera)
- SFX reales (11 carpetas en `game/assets/audio/sfx/`).
- Storm Valkyrie regenerada en Meshy (sigue excluida de la CPU).
- Isla real + rocas/árboles de borde (`island_platform/`, `rock_*/`, `tree_small/`).
- Iconografía propia para piezas/cofres/botones (hoy emojis enmarcados).
- Clips de ataque extra por figura (el sistema de clips ya los soporta).

## ⚖ P1 — Piece Points / Construcción de personajes (PLAN v2 EXHAUSTIVO listo:
## `Balance_PiecePoints.md` — pendiente APROBAR §10 y luego codificar F1–F6)
1. **F1 Medidor**: `pp_cost`/`pp_budget` + barra y desglose en Creador/Dex (solo informa; calibrar vs los 8 integrados).
2. **F2 Presupuesto real**: guardar exige PC ≤ presupuesto (candado de guardado ya existe).
3. **F3 Clases con efectos**: buffs/debuffs en partida (Ágil +1⚡/−10 daño, etc.).
4. **F4 Modelo innato**: pasivas/resistencias ocultas gratis que superan topes.
5. **F5 Evolución**: checkbox +30% budget + castigo (mitad de todo, sin pasivas) al usarla sin evolucionar.
6. **F6 Telemetría** para el ajuste 55/45.

## 🧩 P1 — Contenido del GDD aún no implementado
| Sistema | GDD | Estado hoy |
|---|---|---|
| **Tutoriales** | 10 planeados (Part 3) | ✅ **11 capítulos** (aula "Cómo jugar" 2026-07-11): primera partida + 8 lecciones guionadas de tablero + 2 guías de menú, con XP por capítulo y bienvenida. Falta solo: lección de Rank-Up (requiere más contenido de evoluciones) |
| **Puzzle Battles** | Part 3 | Nada — buen candidato Vuelta02 (reusa el motor tal cual) |
| **Boss Battles** | Part 3 (PvE-only, pueden romper reglas) | Nada |
| **Personalidades de bot** | 8 (incl. Turtle, Random, Expert 3+ turnos) | 5 implementadas; falta profundidad "Expert" |
| **Clases con contenido** | Part 2 (bonos/pasivas ocultas por clase) | Inventariadas pero VACÍAS — decidir qué da cada clase |
| **Colección completa** | tags, wishlist, siluetas de enciclopedia, skins | Hay búsqueda/filtros/favoritos/% — falta el resto (skins = cosmético puro) |
| **Arquetipos de mapa** | Fortress, Triple Spawn, Ring, Temple | 5 mapas hechos (Rieles, Reloj, Plaza, Túneles, Cruce) — faltan 4 arquetipos y el generador+validador procedural (Part 2C) |
| **Duplicados → fragmentos** | Part 4 | Los duplicados de piezas se acumulan ×N; falta la conversión inversa (pieza→frags) |
| **PvP gate por nivel** | Part 4 (PvP se abre en L10) | Online abierto siempre — decidir si se respeta el gate |
| **Rank Up con más figuras** | cadenas 1–4 fases | Motor listo; falta CONTENIDO (más evoluciones integradas) |

## 💰 P1 — Economía/monetización real (Part 4, "no pay-to-win")
- IAP reales (paquetes de 💎) + anuncios opcionales con recompensa (nunca forzados).
- Misiones diarias/semanales + pity system (GDD los marca "MVP disabled").
- Moneda de evento (cuando haya eventos).
- Inbox/buzón de la Home (el GDD lo lista en la top bar).

## 📱 P1 — Cuenta y datos
- Guardado en la nube / cuentas (hoy: local + backup Google + códigos NCFIG/NCPACK/NCDECK).
- Editar nombre/avatar del Perfil (el lápiz ✎ ya existe como placeholder).
- Migración de saves versionada (hoy los JSON toleran campos nuevos; formalizar un "v" por archivo como ya hace loadout).

## 🌐 P2 — Online plus
- Matchmaking (hoy: solo salas por código).
- Espectador / repeticiones (el lockstep ya lo haría barato: guardar la lista de acciones).
- Chat rápido de emotes.

## 🛠 P2 — Técnico
- CI (GitHub Actions con Godot headless) corriendo la Capa 1 en cada push.
- Telemetría anónima (crashes + winrate por figura/pieza para el balance F4).
- Optimización de tamaño del .aab (175 MB — auditar GLBs/texturas, split por ABI).

---

## El orden que recomiendo para la Vuelta 02 (actualizado 2026-07-13)
1. ~~Modo Robot + burn-in~~ ✅ HECHO.
2. **Robot recorre las 11 lecciones del tutorial** (cierra el hueco que dejó
   pasar el crash del 👉; media tanda).
3. **Prueba de actualización** + checklist humana en 2 teléfonos → subir a Play.
4. **Piece Points F1 (medidor)** — barato y le da identidad al Creador.
5. **Puzzle Battles + 2-3 tutoriales temáticos** (contenido barato con el motor actual).
6. **Duplicados→fragmentos + misiones diarias** (cierra el loop económico).
7. Lo demás según feedback de los testers.
