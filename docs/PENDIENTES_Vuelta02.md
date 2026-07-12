# PENDIENTES — Vuelta 02 (lo que queda POR agregar)

> Estado tras cerrar la Vuelta01 + tandas de economía (2026-07-11). Cruzado
> contra el GDD completo (`GDD_Context_Summary.md` y Parts 1–5), el CHANGELOG
> y los docs de balance/testing. Prioridades: **P0** = para la prueba pública ·
> **P1** = para el lanzamiento · **P2** = post-lanzamiento / si hay tracción.

---

## 🤖 P0 — Testing (el plan nuevo: `PLAN_Testing.md`)
| Qué | Detalle |
|---|---|
| **Modo Robot en la app** | Botón admin "🤖 Prueba automática": tour real (economía→creador→mazos→3 partidas CPU vs CPU→cofres) con log `[PASS]/[FAIL]` a archivo + reporte en pantalla. **El siguiente paso natural.** |
| **Burn-in** | 10+ partidas CPU vs CPU aceleradas midiendo fps/memoria/errores en el teléfono. |
| **Checklist humana** | Pasar la lista SI-O-SI completa en 2 teléfonos antes de cada subida a Play. |
| **Prueba de ACTUALIZACIÓN** | Instalar versión vieja → jugar → actualizar → verificar que NO se pierde nada (inventario/mazos/customs/nivel). Nunca la hemos hecho formalmente. |

## 🎨 P0 — Assets (lado de GOJAN, el código ya los espera)
- SFX reales (11 carpetas en `game/assets/audio/sfx/`).
- Storm Valkyrie regenerada en Meshy (sigue excluida de la CPU).
- Isla real + rocas/árboles de borde (`island_platform/`, `rock_*/`, `tree_small/`).
- Iconografía propia para piezas/cofres/botones (hoy emojis enmarcados).
- Clips de ataque extra por figura (el sistema de clips ya los soporta).

## ⚖ P1 — Piece Points (roadmap en `Balance_PiecePoints.md`)
1. **F1 Medidor**: `pp_of(fig)` + barra "PP usados" en Creador/Dex (solo informa).
2. **F2 Presupuesto real**: guardar exige PP ≤ presupuesto de la rareza (usuario).
3. **F3 Rarezas con dientes**: subir de rareza amplía presupuesto.
4. **F4 Telemetría y ajuste por temporada** (regla 55/45).

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

## El orden que recomiendo para la Vuelta 02
1. **Modo Robot + burn-in** (asegura TODO lo demás; 1 tanda).
2. **Prueba de actualización** + checklist humana en 2 teléfonos → subir a Play.
3. **Piece Points F1 (medidor)** — barato y le da identidad al Creador.
4. **Puzzle Battles + 2-3 tutoriales temáticos** (contenido barato con el motor actual).
5. **Duplicados→fragmentos + misiones diarias** (cierra el loop económico).
6. Lo demás según feedback de los testers.
