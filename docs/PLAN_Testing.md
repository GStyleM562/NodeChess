# NodeChess — Plan de Testing (automático + humano)

> El juego ya está "más para allá que para acá": el costo de un bug ya no es
> re-escribir una función, es un tester (o un jugador de Play) frustrado.
> Este plan define QUÉ prueba la máquina, QUÉ prueba el humano, y CUÁNDO.

---

## Recomendación general (el resumen de 30 segundos)

**4 capas, de la más barata a la más cara.** Cada capa atrapa lo que la
anterior no puede ver. Nunca subir un `.aab` sin pasar las capas 1–3; nunca
publicar a testers sin la capa 4.

| Capa | Qué es | Quién la corre | Cuándo |
|---|---|---|---|
| 1 | **Suite headless** (43 tests de motor/UI/red) | Claude o TÚ (`run_suite.ps1`) | En CADA cambio de código |
| 2 | **🤖 Modo Robot** (tour automático DENTRO de la app, con log) | Tú, en el teléfono (1 botón) | Antes de cada `.aab` |
| 3 | **Burn-in** (N partidas CPU vs CPU aceleradas) | Parte del Modo Robot | Antes de cada `.aab` |
| 4 | **Checklist humana SI-O-SI** (§4) | Tú + un segundo tester | Antes de subir a Play |

---

## Capa 1 — Suite headless (YA EXISTE: 43 tests, todos verdes)

Cada `game/tools/test_*.gd` es un test independiente. Cubren: motor completo
(combate, estados, saltos, rodeo, buff nodes, desplazamientos, mapas y sus
reglas de espejo/candados), IA (dificultades, personalidades, tutorial),
economía (piezas, crafteo, cofres, tienda, fondos, reglas por color), mazos
(multi-mazos, códigos, borrado seguro), online (lockstep, espejo, sync,
mazos reales por el relay local, reconexión) y smoke de pantallas.

**Cómo correrla TÚ** (nuevo, ya en el repo):

```powershell
# Windows (PowerShell) — desde la raíz del repo:
.\game\tools\run_suite.ps1
# con el test del Render desplegado incluido:
.\game\tools\run_suite.ps1 -IncludeLive
```

Imprime una tabla `test → OK/FAIL` y termina con `FALLOS: N`. Necesita Node
instalado para el test del relay local (si no hay Node, ese test se salta).

**Regla**: si `FALLOS > 0`, no se hace `.aab`. Sin excepciones.

**Cómo se escribe un test nuevo** (patrón de la casa): `extends SceneTree`,
`_initialize()` con `_expect(etiqueta, got, want)`, imprime `X_OK`/`X_FAIL`,
`quit()`. Autoloads via `get_root().get_node("Nombre")` (su `_ready` no corre
en `--script`; todos ya tienen lazy-init).

## Capa 2 — 🤖 Modo Robot (POR CONSTRUIR — la pieza que falta)

Un botón **"🤖 Prueba automática"** en Configuración (solo admin) que ejecuta
un TOUR real dentro de la app — con el juego renderizando de verdad en el
teléfono — y deja un LOG legible:

**El tour (orden propuesto):**
1. **Higiene**: respaldar inventario/loadout reales → cuenta de prueba limpia.
2. **Economía round-trip**: dar fondos → comprar 1 pieza (verificar recibo y
   saldo) → craftear 10 fragmentos → abrir caja gratis → verificar 🧾 log.
3. **Creador**: crear una figura con el pool por defecto (verificar que
   CONSUME piezas), editarla (verificar delta), verificar que aparece en Dex.
4. **Mazos**: crear mazo nuevo, renombrar, marcar EN USO, exportar/importar
   código NCDECK, borrar (verificar que NO pisa al Mazo 1).
5. **Partida CPU vs CPU** (bot juega ambos lados, `time_scale` alto): 3
   partidas en 3 mapas distintos; en cada media-jugada `board_consistent()`;
   al final verificar XP/monedas/cofre ganado según el resultado.
6. **Cofres**: descifrar (acortando el timer en modo prueba), abrir, verificar
   piezas entregadas vs recibo.
7. **Restaurar** los datos reales del jugador SIEMPRE (pase o falle).

**El log**: `user://autotest/reporte_AAAA-MM-DD_HHMM.txt` — una línea por paso
`[PASS]/[FAIL] paso — detalle`, y al final un resumen. En pantalla, la ventana
de recibo (RewardPopup) muestra el resultado con el conteo PASS/FAIL, y el
archivo se puede copiar al portapapeles para pegármelo a mí directamente.

**Por qué en la app y no solo headless**: atrapa lo que el headless no ve —
renderizado real, táctil, tiempos de carga de GLB, memoria/fps del teléfono.

**Esfuerzo estimado**: 1 tanda (script `AutoTester.gd` + botón + timers de
prueba). Es el siguiente paso natural de este plan.

## Capa 3 — Burn-in (estabilidad y rendimiento)

Dentro del Modo Robot, modo extendido: **10+ partidas CPU vs CPU seguidas**
alternando los 5 mapas y las 3 dificultades, midiendo:
- FPS mínimo/promedio por partida (objetivo GDD: 60, aceptable 30).
- Memoria al inicio vs al final (fugas: la señal es crecimiento sostenido).
- Cero errores de script (se registra `push_error` en el log).
- `board_consistent()` en cada media-jugada de cada partida.

**Regla**: el burn-in corre en el TELÉFONO real antes de cada `.aab` que vaya
a Play (el rendimiento de PC no cuenta).

## Capa 4 — Checklist humana SI-O-SI (§ el TODO LIST)

Lo que la máquina no puede juzgar: sensación, claridad, y flujos de 2
teléfonos. **Marcar TODAS las casillas antes de subir a Play.**

### A. Arranque y primera experiencia
- [ ] Instalación limpia: abre sin crash, pide lo que debe, orientación vertical fija.
- [ ] Primera vez: JUGAR lleva al TUTORIAL; se completa de inicio a fin; al ganar marca hecho y JUGAR ya lleva al Deck Builder.
- [ ] 🎓 Repetir tutorial desde Configuración funciona.
- [ ] **ACTUALIZACIÓN desde la versión anterior instalada: NO se pierden inventario, mazos, customs, nivel, monedas** (probar SIEMPRE: instalar versión vieja → jugar algo → actualizar).

### B. Mazos y Creador (economía de verdad)
- [ ] Crear mazo, renombrar, ✓ EN USO visible, borrar con confirmación (el Mazo 1 queda intacto).
- [ ] Exportar código NCDECK → importarlo en el OTRO teléfono.
- [ ] Modo usuario: figuras no poseídas 🔒, Jugar bloqueado si el mazo no está 6/6.
- [ ] Crear figura consume piezas EXACTAS (verificar en 📦 antes/después); editar cobra solo el delta.
- [ ] Sin una pieza (daño/estrella/prob/clase): el guardado se bloquea y el banner dice QUÉ falta.
- [ ] 📦 del Creador y el Inventario muestran los mismos conteos.

### C. Cofres, Tienda y progresión
- [ ] Ganar partida (usuario) → cofre al inventario; con 4/4 ranuras la victoria AVISA.
- [ ] Descifrar el cofre QUE YO ELIJA (varios a la vez), countdown vivo, ¡ABRIR! entrega lo que dice el recibo.
- [ ] Comprar con 🪙 y con 💎: recibo correcto, saldo baja, pieza aparece, "tienes ×N" sube.
- [ ] Sin fondos: mensaje claro de cuánto falta; nada se descuenta.
- [ ] Subir de nivel: +🪙 (nivel×100), cofre 🏅; en nivel 5/10/15: +💎 (nivel×2).
- [ ] 🧾 muestra cada movimiento de esta sesión.
- [ ] Borrar inventario (Config): piezas/frags a cero, kit inicial de vuelta, personajes/nivel/cofres INTACTOS.

### D. Partida vs CPU
- [ ] Fácil/Media/Difícil se sienten distintas; banner de personalidad visible.
- [ ] Banca: retratos, ⏳ de K.O. baja y la figura vuelve; despliegue por arrastre cómodo.
- [ ] Candados 🔒 abren en ronda 3; saltos aterrizan bien; rodeo (K.O. por encierro) funciona.
- [ ] Buff node ⚡: 2 turnos parado → potenciada permanente (prefijo ⚡).
- [ ] Combate ×2 y ⏭ Saltar no rompen nada; victoria/derrota muestran XP/recompensas correctas.
- [ ] Pinch-zoom suave; 30–60 fps estables en el gama media.

### E. Online (2 teléfonos, MISMA versión)
- [ ] Crear sala + unirse por código; el lobby muestra "Mazo en uso" y BLOQUEA mazos incompletos.
- [ ] Ambos ven los MISMOS nombres/modelos/movimientos toda la partida (sin desync).
- [ ] Timer ⏱ 75s visible; al agotarse pasa el turno solo.
- [ ] Apagar WiFi 10s a mitad de partida → banner de pausa → reconecta y sigue.
- [ ] Revancha: ambos aceptan → nueva partida misma sala.
- [ ] Arranque en frío del server (tras ~15 min sin uso): la app espera y conecta sola (~1–3 min).
- [ ] Cerrar la app a mitad de partida online → el rival recibe el aviso y la sala muere a los 90s.

### F. Estabilidad general
- [ ] Minimizar la app y volver (en menú, en partida, en combate): no crashea, no congela.
- [ ] Botón ATRÁS de Android en cada pantalla: hace lo esperado, nunca cierra en seco.
- [ ] 30 min de juego continuo: sin calentamiento excesivo ni degradación.
- [ ] Sonido: volúmenes de Config respetados; sin música duplicada al cambiar de pantalla.

---

## Cadencia (cuándo corre qué)

1. **Cada cambio de código** → Capa 1 (la corro yo siempre; tú puedes con el script).
2. **Antes de cada `.aab`** → Capas 1 + 2 + 3 (robot + burn-in en el teléfono).
3. **Antes de subir a Play** → Capa 4 completa en 2 teléfonos (idealmente uno gama media).
4. **Bug encontrado** → primero se escribe el test que lo reproduce (capa 1 o 2), LUEGO se arregla. Así jamás regresa.

## Futuro (cuando haya equipo/CI)
- GitHub Actions: correr la Capa 1 en cada push (Godot headless Linux) — el repo ya está listo, es configuración.
- Telemetría anónima de crashes/winrate para alimentar el balance (ver `Balance_PiecePoints.md` §2.4).
