# ✅ IMPLEMENTADO — 🤖 Modo Robot (2026-07-12)

> **Este standby ya se ejecutó**: el robot vive en `game/scripts/AutoTester.gd`
> (botones en Configuración admin: "🤖 Prueba automática" y "🔥 Burn-in") y por
> CLI con `game/tools/robot_boot.gd`. Ver `PLAN_Testing.md` Capa 2-3. Se
> conserva este doc como registro del diseño original.

## Qué es
Botón **"🤖 Prueba automática"** en Configuración (solo admin) que ejecuta un
TOUR real dentro de la app con log `[PASS]/[FAIL]` y reporte en pantalla.

## El tour (orden ya diseñado)
1. Respaldar `user://inventory.json` + `user://loadout.json` → cuenta de prueba limpia.
2. Economía round-trip: `adjust_funds` → `buy()` (verificar recibo/saldo/pieza) →
   `add_frags`+`convert()` → `open_free()` → verificar `tx_log`.
3. Creador: `CharacterCreator.make_figure` + `CustomFigures.add/apply_live` →
   verificar `consume_for` descuenta exacto → editar → verificar delta.
4. Mazos: crear/renombrar/EN USO/`deck_code`→`import_deck_code`/borrar
   (verificar que el Mazo 1 no se pisa).
5. 3 partidas CPU vs CPU en 3 mapas (`bot_difficulty` 2 ambos lados, tablero
   REAL renderizando, `Engine.time_scale` 8-12): cada media-jugada
   `board_consistent()`; al final verificar XP/monedas/cofre según resultado.
6. Cofres: `grant_won_chest` → `start_unlock` (timer acortado en modo prueba:
   escribir `ready_at = now`) → `open_won_chest` → verificar entrega vs recibo.
7. SIEMPRE restaurar los archivos reales (pase o falle) — patrón de respaldo
   idéntico a `tools/test_inventory.gd`.

## Burn-in (modo extendido)
10+ partidas CPU vs CPU alternando los 5 mapas y 3 dificultades midiendo:
fps mín/prom (`Performance.get_monitor(TIME_FPS)`), memoria
(`Performance.MEMORY_STATIC`), errores (`push_error` interceptado), y
`board_consistent()` continuo.

## Log
`user://autotest/reporte_AAAA-MM-DD_HHMM.txt` — una línea por paso
`[PASS]/[FAIL] paso — detalle` + resumen final. En pantalla: RewardPopup con
PASS/FAIL y botón "Copiar reporte" (`DisplayServer.clipboard_set`) para
pegárselo a Claude directo.

## Esqueleto técnico (decidido)
- `game/scripts/AutoTester.gd` (autónomo, `Node`): se instancia desde el botón
  de Configuración; corre como corrutina con `await`; conduce escenas reales
  (`change_scene_to_file` + esperar `process_frame`).
- Para las partidas usa `board.tscn` con un flag `AutoTester.cpu_vs_cpu = true`
  que Board3D lee para que el "player" también lo juegue `bot_action`
  (mismo patrón que `_bot_turn` del enemigo).
- Los timers de cofres/relojes NO se esperan: se escriben (`ready_at = now`).

## Puntos de reanudación
1. Crear `AutoTester.gd` + flag en Board3D + botón en Config (admin).
2. Probarlo primero en PC (ventana), luego en el teléfono.
3. Añadir el burn-in con métricas y el guardado del reporte.
4. Actualizar `PLAN_Testing.md` (Capa 2: POR CONSTRUIR → LISTA) y CHANGELOG.
