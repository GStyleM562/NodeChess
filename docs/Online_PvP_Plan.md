# NodeChess — Plan de Online PvP (por turnos alternos)

> Referencia: `F:\App Gnosia\claudenoderps` (NODEHACK). Ese proyecto ya tiene PvP 1v1
> con **servidor autoritativo en Dart + WebSocket + salas con código de 4 letras**,
> reusando su **motor puro** en cliente y servidor. La diferencia clave: NODEHACK
> resuelve el turno de **ambos a la vez** tras "LISTO"; NodeChess es **alterno**
> (tu turno → turno del rival → …), lo cual es **más simple** (solo 1 jugador actúa
> a la vez, sin simultaneidad que reconciliar).

## 0. Lo que ya juega a favor
- **El motor de NodeChess ya es puro** (`GameState`, `Combat`, `MapData`, `Roster`
  son `RefCounted`, sin nodos). Igual que NODEHACK: se puede correr fuera de la UI y
  ser la única fuente de verdad. Esto es el 80% del trabajo pesado ya hecho.
- Las acciones son **discretas y validables**: Deploy / Move / Attack / Modifier / End.
- Salvo el ataque, **todo es determinista** (sin azar). El azar vive solo en
  `_roll_full` (tiradas) dentro de `attack()`.

## 1. Modelo de autoridad — recomendación por fases
| Fase | Modelo | Anti-trampa | Esfuerzo |
|------|--------|-------------|----------|
| **A (test)** | **Relay + lockstep determinista** | Confianza entre amigos | Bajo |
| **B (beta)** | **Servidor autoritativo** (corre el motor y valida) | Alto | Medio-alto |

**Fase A (para probar ya):** un servidor **relay** (tonto) con salas por código que
solo **reenvía** la acción del jugador activo al rival. Como el motor es determinista
y los turnos son alternos, **ambos clientes aplican la misma acción** y quedan
sincronizados. El cliente activo **resuelve** su ataque (tira los dados) y envía el
**resultado ya resuelto** (`rec` con `idx_a/idx_b/seg_a/seg_b/ko/rankup/…`); el rival
lo **aplica sin volver a tirar**. Cero divergencia de RNG.

**Fase B (más adelante):** mover la autoridad al servidor. Dos caminos:
1. **Godot headless como servidor** (una instancia del motor por sala) — reusa el
   mismo GDScript, valida cada acción, y tira los dados él (autoritativo). Es el
   equivalente directo a lo que hizo NODEHACK con su servidor Dart.
2. **Portar `GameState` a un lenguaje de servidor** (Dart/TS/Go) — máxima portabilidad
   pero duplica el motor. NODEHACK eligió esto (motor Dart compartido). No lo
   recomiendo para nosotros porque duplicaría reglas.

> Recomendación: **A ahora**, y **B-1 (Godot headless)** cuando quieras cerrar trampas.

## 2. Transporte
- **`WebSocketPeer`** de Godot 4 (crudo, JSON) → idéntico patrón a NODEHACK
  (`{t: tipo, ...datos}`). Un `NetClient.gd` (autoload) que conecta, envía y emite
  señales al recibir.
- Servidor relay: cualquier cosa mínima (Node `ws`, Python `websockets`, o Dart como
  NODEHACK). ~120 líneas: mapa `code -> [peerA, peerB]`, y `broadcast al otro`.
- **Salas con código de 4 letras** (crear/unirse), igual que NODEHACK. Deploy gratis
  en Render/Cloud Run (free tier).

## 3. Protocolo de mensajes (JSON `{t, ...}`)
Cliente→Servidor / Servidor→Cliente:
```
CREATE_ROOM            -> ROOM_CREATED {code}
JOIN_ROOM {code}       -> JOINED {seat:0|1} | ERROR {reason}
DECK {figures:[...], seat} (intercambio de mazos al conectar)  -> broadcast
START {map, first, seed}  (el servidor/host fija mapa, quién empieza, semilla)
ACTION {kind, ...}     -> broadcast al rival  (kind: deploy|move|attack|modifier|end)
   deploy {uid, node}
   move   {uid, to}
   attack {rec}        (rec ya resuelto por el jugador activo)
   modifier {mid}
   end
STATE_HASH {turn, hash}  (chequeo de desync opcional cada turno)
LEFT / RESIGN / GAME_OVER {winner}
```
Nota: las **claves** conviene centralizarlas en un `NetKeys.gd` (una sola fuente de
verdad), como NODEHACK con `protocol_keys`.

## 4. Sincronizar personajes (responde tu pregunta #2)
**Sí funciona con personajes distintos construidos por cada quien.** La ficha de cada
figura es **JSON** (ataques, tipo, %s, estamina, pasivas, evolución) → se transmite
tal cual. Flujo:
1. Al conectar, cada cliente envía su **mazo** = las 6 figuras elegidas **+ el cierre
   de evolución** (toda figura referenciada por `evolves_id`, recursivo), como dicts.
2. Ambos construyen un **roster de partida idéntico** = `deck(seat0) + deck(seat1)` en
   el mismo orden → **índices `rindex` compartidos** (clave para que las acciones
   viajen como números y signifiquen lo mismo en ambos lados).
3. `GameState` se inicializa desde ese roster de partida (hoy usa `Roster.FIGURES`
   global; para online se le pasa el roster combinado).

**Modelos 3D:** funciona **siempre que las figuras usen modelos que ambos ya tienen**.
Hoy el creador siempre **toma prestado un modelo existente** (bundled en el APK), así
que **funciona de fábrica**. Un GLB *subido por el usuario* (no bundled) requeriría
**transferir el asset** (fuera de alcance para la fase de test). Recomendación para
test: restringir el creador a modelos bundled (ya es el caso).

## 5. Perspectiva (cada quien se ve "abajo")
El tablero es simétrico. Estado **canónico** (p0 abajo, p1 arriba) en el servidor y en
`GameState`. Cada cliente se dibuja a sí mismo abajo:
- **p0:** cámara normal.
- **p1:** **gira la cámara 180°** (su meta queda abajo). Los `node id` siguen siendo
  compartidos → **no se traduce la lógica**, solo la cámara. (Más simple que espejar
  ids como hace NODEHACK con su "perspectiva propia".)

## 6. Cambios en el motor (`GameState`)
- **Aplicar acción remota sin re-tirar:** métodos `apply_attack(rec)`,
  `apply_move(uid,node)`, `apply_deploy(uid,node)`, `apply_modifier(team,mid)` que
  reproducen el efecto de un `rec` ya resuelto (hoy `attack()` tira dados internamente;
  separar “resolver” de “aplicar”).
- **Inyección de roster:** `GameState.new(map, match_roster)` en vez del `Roster`
  global.
- **Semilla RNG opcional** (`seed`) por si algún día se quiere lockstep con re-tirada.

## 7. Cambios en la UI (`Board3D`)
- **Gating por turno:** el input de deploy/move/attack solo si `turn_team == mi_asiento`.
- **Reemplazar `_bot_loop`** por “esperar acción del rival” (señal de `NetClient`) y
  **animar la acción remota** reusando `_animate_bot(rec)` (ya anima acciones ajenas).
- **Enviar mi acción** justo después de aplicarla localmente.
- Indicadores: “Tu turno” / “Turno del rival…”, estado de conexión, reconexión.

## 8. Menú / flujo
- Nueva pantalla **JUGAR ONLINE**: campo Servidor, **CREAR SALA** (muestra código),
  **UNIRSE** (escribe código). Igual que NODEHACK (`PVP_QUICKSTART.md`).
- Selección de mazo (reusa Deck Builder) → al conectar se intercambia.

## 9. Tests (headless, como ya hacemos)
- Motor: `apply_*` reproduce exactamente lo que `attack()/move()/deploy()` producen
  (mismo `rec` → mismo estado en ambos lados).
- Serialización figura↔JSON (round-trip) del mazo + cierre de evolución.
- Un test de “dos GameState en paralelo” aplicando el mismo stream de acciones →
  mismos hashes de estado (equivalente al `integration_ws_test` de NODEHACK).

## 10. Hitos sugeridos
1. `NetClient.gd` + servidor relay + salas con código (conectar 2 dispositivos).
2. Intercambio de mazos + roster de partida compartido + perspectiva (cámara p1).
3. `apply_*` en el motor + envío/recepción de acciones + gating por turno.
4. Animar acciones remotas + fin de partida + reconexión básica.
5. (Beta) migrar a servidor autoritativo (Godot headless) para anti-trampa.

---
**Resumen de una línea:** como el motor ya es puro y los turnos son alternos, la fase
de test es factible con un **relay + lockstep determinista** (enviando el `rec` ya
resuelto), y el intercambio de **fichas JSON** hace que **personajes distintos**
funcionen mientras usen **modelos bundled**.
