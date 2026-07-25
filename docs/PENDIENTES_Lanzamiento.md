# ¿Qué falta para LANZAR NodeChess? — auditoría completa

> Revisión del proyecto entero (código, docs, assets, servidor, trámites) el
> **2026-07-25**, build **0.33** (versionCode 33). Sustituye como lista maestra
> a `PENDIENTES_Vuelta02.md` (Vueltas 01–03 ya cerradas).
>
> **Veredicto corto:** el JUEGO está terminado y estable (50/50 pruebas verdes,
> 15 capítulos de tutorial, online funcionando contra Render v25). Lo que falta
> **no es programación de mecánicas**: es **audio**, **activar los anuncios**,
> **trámites de Play Console** y **probarlo en teléfonos reales**.

---

## 🔴 P0 — BLOQUEANTES (sin esto no se debe lanzar)

### 1. NINGÚN efecto de sonido (SFX 0 de 11) — el juego se siente inerte
El motor está completo y probado. Estado real:

- **Música: ✅ 4/4 pistas presentes** — `Music` cambia por estado
  (menú / batalla / ventaja / peligro) con crossfade y funciona.
  ⚠️ Pero las pistas parecen **cruzadas**: `battle/` tiene "Menu Node Music",
  `menu/` tiene "music_deckbuild", `advantage/` tiene "music_victory" y
  `danger/` tiene "music_combat". Vale la pena reordenarlas (es mover archivos
  entre carpetas, nada de código).
- **SFX: ❌ 0/11** — las 11 carpetas de `game/assets/audio/sfx/` solo tienen
  `.gitkeep`. NO suena golpe, fallo, bloqueo, efecto, despliegue, K.O.,
  rank-up, fin de turno, victoria, derrota ni clic.

El código no crashea sin archivos (cae en silencio), así que la suite pasa
verde y el hueco es invisible a las pruebas — pero un combate sin ningún
impacto sonoro es lo primero que nota un tester.

- **Qué hacer:** soltar UN archivo (`.mp3`/`.ogg`/`.wav`) en cada una de las 11
  carpetas de `sfx/`. No hay que renombrar nada: la carpeta decide cuándo suena
  (ver `assets/audio/README.md`).
- **Quién:** Gojan (o packs libres tipo Kenney/freesound con licencia CC0).
- **Costo:** cero código. Son 11 archivos.

### 2. Los anuncios NO generan dinero todavía
`Ads.gd` está integrado y el popup 🎁 Recompensas ya entrega premio **solo si
se completa** el anuncio, con tope diario por tipo (🪙×5 / 💎×3 / 📦×2). Pero
hoy los anuncios se **simulan**: falta el plugin y el ID real.

- Falta: (a) crear la unidad **Rewarded** en AdMob, (b) pegar su ID en
  `Ads.gd → UNIT_RELEASE` (hoy `""`), (c) instalar el plugin **AdMob para
  Godot 4** y activarlo en el preset de Android, (d) activar el mensaje
  **UMP/GDPR** en AdMob, (e) datos fiscales en AdMob → Pagos.
- **Pasos exactos ya escritos:** `docs/Ads_Setup.md`.
- Nota: con UNA sola unidad rewarded bastan los 3 botones (la recompensa la
  decide el juego, no AdMob).

### 3. Trámites de Google Play Console (los textos legales ya existen)
La app ya cumple por dentro: `Legal.gd` trae Términos y Aviso de Privacidad
embebidos, pantalla de aceptación obligatoria al primer arranque, y toggle de
anuncios personalizados. Falta lo administrativo:

| Trámite | Estado | Dónde está el material |
|---|---|---|
| Publicar `/terminos` y `/privacidad` en el sitio web | ⚠️ pendiente | Textos + spec: `terminosycondiciones.md` §5 y §7 |
| Pegar la **URL de privacidad** en Play Console | ⚠️ pendiente | (necesita el sitio arriba) |
| Sección **"Seguridad de los datos"** | ⚠️ pendiente | Mapa ya hecho: §5.3 |
| Cuestionario **IARC** (edad 13+, anuncios, online) | ⚠️ pendiente | §8 |
| Completar datos legales `[corchetes]` | ⚠️ pendiente | §0 |
| Revisión por abogado en México | recomendada | — |

### 4. Nunca se ha probado en teléfonos reales de verdad
- **Online en 2 teléfonos**: el relay ya responde `NodeChess relay OK v25`
  (verificado hoy) y el matchmaking funciona en pruebas locales, pero **la
  partida humana teléfono-contra-teléfono sigue sin hacerse**.
- **Checklist humana** completa antes de subir (`PLAN_Testing.md`).
- **Prueba de ACTUALIZACIÓN — nunca hecha formalmente**: instalar un build
  viejo → jugar (crear personajes, abrir cofres, subir de nivel) → actualizar
  al 0.33 → verificar que NO se pierde inventario/mazos/customs/nivel. Es la
  prueba más barata que evita el peor desastre post-lanzamiento.

---

## 🟡 P1 — Calidad visible (no bloquea, pero se nota)

- **Storm Valkyrie sigue EXCLUIDA** del equipo por defecto (`Loadout.gd`): su
  modelo "ave" tapa la pantalla y solo tiene 1 clip de animación. Hay que
  regenerarla en Meshy o dejarla fuera a propósito y documentarlo.
- **Iconografía propia**: hoy todo son emojis enmarcados (piezas, cofres,
  botones). Funciona y se ve consistente, pero delata "juego hecho rápido".
- **Assets de escenario**: isla real, rocas y árboles de borde
  (`island_platform/`, `rock_*/`, `tree_small/` ya los espera el código).
- **Clips de ataque extra por figura** (el sistema de clips ya los soporta).
- **Tamaño del `.aab`: 176 MB** (assets 205 MB — figuras 112 MB + tablero
  88 MB). Ya se han subido builds así sin problema, pero conviene auditar GLBs
  y texturas antes de que crezca más.

## 🟡 P1 — Decisiones de diseño que solo Gojan puede tomar

- **¿Qué BONO da cada CLASE?** Hoy las clases (Balanced, Specialist,
  Controller, Agile, Tank, Striker, Debuffer, Buffer) solo tienen **costo** en
  Piece Points (`PiecePoints.CLASS_PC`); el GDD quería además bonos/pasivas
  ocultas por clase. Están inventariadas pero **vacías de efecto**.
- **Misiones diarias / pity system**: el GDD las marca "MVP disabled". Hoy el
  enganche diario lo llevan los anuncios (topes por día) y los cofres por
  tiempo. Decidir si entran.
- **Lección de Rank-Up**: el motor de evolución funciona en partida, pero no
  hay capítulo de tutorial porque falta CONTENIDO de evoluciones integradas.

---

## 🟢 P2 — Post-lanzamiento / si hay tracción

- **Guardado en la NUBE / cuentas** (hoy: local + backup de Google + códigos
  NCFIG/NCPACK/NCDECK para mover cosas a mano).
- **CI** (GitHub Actions con Godot headless corriendo la suite en cada push).
  Hoy la suite se corre a mano con `game/tools/run_suite.ps1`.
- **Telemetría** anónima (crashes + winrate por figura/pieza) → cierra la fase
  **F6** de `Balance_PiecePoints.md`, la única que falta del sistema.
- **El 🤖 robot in-app no conduce las lecciones**: `test_lessons_live` (headless)
  sí las recorre y ahora exige que las figuras tengan modelo 3D, pero
  `AutoTester.gd` (el botón de admin) no las toca. Hueco menor ya mitigado.
- **Pruebas de UI táctil**: el drag&drop de la banca sigue siendo manual.
- **Online plus**: espectador/repeticiones (el lockstep lo haría barato:
  basta guardar la lista de acciones) y chat de emotes.

---

## 🚫 DIFERIDO por decisión de Gojan (no se hace)

Puzzle Battles · Boss Battles · arquetipos de mapa nuevos (Fortress, Triple
Spawn, Ring, Temple) y generador procedural · **ladder / PvP gate por nivel**
(solo "crear sala" + "encontrar rival") · colección completa (skins, wishlist,
siluetas) · personalidades de bot extra (las 5 actuales bastan) · conversión
inversa duplicados→fragmentos · IAP reales (por diseño: el juego declara
legalmente que NO tiene compras dentro de la app).

---

## 📊 Estado del juego (lo que SÍ está terminado)

| Área | Estado |
|---|---|
| Motor de combate, estados, pasivas, desplazamientos, buff nodes, K.O. | ✅ |
| 5 mapas espejo verificados + candados + portales | ✅ |
| 12 figuras Meshy + Creador de personajes con Piece Points (F1–F5) | ✅ |
| Economía: piezas, fragmentos, cofres, cajas por tipo, 🪙/💎, tienda real | ✅ |
| Online 1v1: salas por código + **matchmaking**, lockstep, timer, reconexión, revancha | ✅ (falta prueba humana) |
| Tutorial: **15 capítulos** (primera partida + 8 lecciones + 2 guías + 4 meta) | ✅ |
| IA CPU: 3 dificultades × 5 personalidades | ✅ |
| UI/UX "Juicy Hall" + **modo oscuro** + nav inferior + menú de pausa | ✅ |
| Legal: Términos + Aviso embebidos + gate de aceptación | ✅ (falta trámite) |
| Pruebas automatizadas | ✅ **50/50 verdes** |
| Presentación: splash propio, icono propio, sin logo de Godot | ✅ |

---

## ✅ El orden que recomiendo

1. **SFX** (11 archivos) + reordenar las 4 pistas de música — el salto de
   calidad más grande por el menor esfuerzo.
2. **Prueba en 2 teléfonos**: online + checklist humana + **prueba de
   actualización**. Aquí saldrán los bugs que quedan.
3. **Trámites de Play Console** (sitio web → URL → Data safety → IARC).
4. **Activar anuncios reales** (plugin + `UNIT_RELEASE` + UMP + pagos).
5. Lanzar en **prueba interna → cerrada**, y con el feedback decidir P1
   (iconografía, bonos de clase, misiones diarias).
