# NodeChess — Estado del proyecto y registro de cambios

> Resumen vivo: qué está HECHO, qué entró en la última tanda, y qué queda
> PENDIENTE (mecánicas / diseño / mapa / técnico). Actualizado: 2026-07-08.
> Plan de la vuelta y estados por punto: `docs/PENDIENTES_Vuelta01.md`.

## ✅ Sistemas funcionando hoy

**Núcleo de juego**
- Combate por colores del GDD (Blanco vs Oro POR DAÑO), 13 estados, pasivas,
  KO por rodeo, Rank Up en partida con cambio de modelo, energía, buff node.
- MAZO DE 6 figuras (GDD exacto) en builder, banca, online y CPU.
- RESISTENCIAS por figura (`resists: []`, máx 2): anulan el estado en combate
  ("RESISTIÓ"), editables en el Creador (pieza de inventario `resist:*`),
  visibles en la Dex, validadas por FigureValidator.
- Desplazamientos completos y deterministas: empuje / jalón / intercambio /
  DASH (el ganador avanza) / RETIRADA / TELETRANSPORte (a entrada propia libre).
- Pasivas de movimiento: HOVER (cruza candados/terreno sin parar en ellos) y
  FAST RECOVERY (K.O. −2 medio-turnos); + WARCRY, GOALKEEPER (+20/+1★ en su
  meta), SCAVENGER (+2 energía por K.O. rival).
- BUFF NODES GDD completos: 2 finales de turno propios parado en el nodo ⚡ →
  figura POTENCIADA permanente (+20 daño/+1★ hasta K.O.), cooldown del nodo
  10 medio-turnos, progreso visible en el tablero y prefijo ⚡ en el nombre.
- 10 MODIFICADORES: power_surge, surge_big, cleanse, adrenaline + iron_wall
  (inmune a desplazamientos), shield (Fallo→Azul), haste (+1 estamina equipo),
  energy_drain, revive (saca del K.O.), trap (nodo oculto que inmoviliza).
- K.O.: 3 rondas (6 medio-turnos) — decisión Vuelta01 (el GDD decía 5 turnos).
- Anti-stack de motor (`move_unit` rechaza ocupados) + auditor `board_consistent`.
- Mapas (5, +“Cruce” nuevo): mínimo entrada→meta 6–8, candados 🔒 que abren en
  la ronda 3, espejo 180° automórfico verificado por test (requisito online).
- IA CPU (docs/AI_CPU.md): GANAR YA → PORTERO → CERCO → ATAQUE ÚTIL →
  DESPLIEGA TODO (y camina) → BUFF → AVANZA. Dificultad Fácil/Media/Difícil
  (selector en Deck Builder) + 5 PERSONALIDADES (equilibrada/agresiva/defensiva/
  corredora/cazadora) elegidas al azar y anunciadas en un banner.

**Online 1v1**
- Relay Node en Render (free, arranque en frío tolerado: wake-GET + reintentos
  ~3 min). Salas por código de 4 letras.
- Lockstep determinista + perspectiva local sin voltear tablero; el mazo viaja
  {"team", "lib"} → uids/modelos idénticos en ambas pantallas.
- TIMER de 75 s por turno (⏱ en pantalla; al agotarse pasa solo).
- RECONEXIÓN: si se corta la red, el cliente reconecta y hace re-join a la sala
  (el server guarda el asiento 90 s y avisa al rival con banner de pausa).
- REVANCHA online: botón en la pantalla final; si ambos aceptan, nueva partida
  en la misma sala con nuevo seed y los mismos mazos.

**Progresión / economía (base de monetización)**
- Modo ADMIN (todo ∞) / USUARIO (regla dura) en Configuración.
- Inventario persistente de PIEZAS del Creador (figuras, rarezas, tipos,
  colores, estados, pasivas, resistencias, estamina) + fragmentos (10 = 1).
- Cofres en el lobby: Gratis (fragmentos) + 5/10/15 min por reloj real
  (rearman al reclamar) + COFRE DE NIVEL 🏅 (al subir de nivel: 3 piezas,
  1 premium garantizada; reclamable con la misma animación).
- ECONOMÍA REAL: crear GASTA piezas; editar cobra el delta y reembolsa. El flujo
  USUARIO completo: cofres → fragmentos → "Convertir" (10=1 pieza completa) →
  botón 📦 en el CREADOR (modal con TUS piezas ×N sin salir de la creación) →
  guardar consume 1 de cada pieza usada.
- MONEDAS 🪙 y DIAMANTES 💎: subir de nivel da 🪙 (nivel × 100) y cada 5 niveles
  💎 (nivel × 2); TODAS las cajas tienen % de soltar 💎 (mejor cofre, más %).
  Saldos reales en Home y Tienda; panel ADMIN en Configuración para
  añadir/quitar fondos.
- TIENDA REAL: cada tarjeta es una pieza del inventario (modelos, colores,
  estados, pasivas, tipos, estamina/resist/rareza); comprar descuenta 🪙/💎 y
  AÑADE la pieza a tu inventario (usable en Creador y mazos).
- COFRES GANADOS 📦: al VENCER (modo usuario) cae un cofre (60% común / 30%
  épico / 10% legendario) a tus 4 ranuras; en el Inventario lo DESCIFRAS (uno a
  la vez, 5/10/15 min) y al abrirlo da piezas + % de 💎. El slot 📦 del lobby
  abre el que esté listo con la animación. (Los cofres de reloj t5/t10/t15 del
  lobby se retiraron: ahora los cofres SE GANAN.)
- XP y NIVELES persistentes: +60 victoria / +25 derrota (+15 online).
- ESTADÍSTICAS de perfil persistentes: ganadas/perdidas/racha/mejor racha
  (se actualizan en cada fin de partida).
- MAZOS MÚLTIPLES (hasta 20) con pestañas en el Deck Builder + código de mazo
  NCDECK1 para compartir/importar. En modo USUARIO el builder exige POSEER las
  figuras (integradas via pieza `model:`; customs propias siempre).
- Dex/Colección 2.0: búsqueda, filtros (todas/⭐favoritas/poseídas/tuyas),
  favoritos persistentes y % de completado.
- Personajes custom: guardado local + códigos NCFIG1/NCPACK1 validados.

**Presentación / UX**
- Tablero 3D con assets Meshy o 2D digital futurista, elegible en Configuración.
- PINCH-TO-ZOOM táctil en el tablero (gesto de 2 dedos, 7–26 de altura).
- Velocidad de combate ×2 (Configuración) + botón ⏭ para saltar la animación.
- MODO DALTÓNICO: paleta Okabe-Ito + símbolo por color (■◆✦⬟✖) en ruletas.
- Portal visual (toro violeta girando) en los teleporters de Túneles.
- FULL TUTORIAL — aula "🎓 Cómo jugar" (botón en Home, rejilla 4×2): 11
  capítulos por categoría con ✓/XP. 🎲 Tablero (9): primera partida + 8
  LECCIONES GUIONADAS estilo NODEHACK — combates con resultado YA marcado
  (índices forzados al motor real), acciones OBLIGATORIAS (gate: lo que no
  corresponde al paso se ignora), rival ESTATUA, marcador 👉 pulsante sobre el
  objetivo (desplegar/mover, combatir, Cleanse, saltar, rodear, tapar entrada,
  buff node, tomar portería). 📱 Menú (2): guías "pícale aquí" reales para
  craftear y descifrar cofres. Cada capítulo da XP la PRIMERA vez (repetibles);
  BIENVENIDA al abrir el juego con pendientes por categoría y XP por reclamar.
- TIENDA y PERFIL visitables desde la nav inferior (vista PREVIA, solo ver):
  Tienda con categorías reales (Modelos/Ataques/Pasivas/Tipos/Partes) y
  precios de muestra; Perfil con identidad, estadísticas REALES y favoritos.
- Banca con RETRATOS 3D + ⏳ de K.O.; victoria/derrota animadas con XP real.
- Música por estado + 11 slots SFX; volúmenes y toggles en Configuración ⚙.

## 🕐 PENDIENTES
> Lista completa y priorizada: `docs/PENDIENTES_Vuelta02.md` · Plan de
> pruebas (suite + 🤖 robot + checklist humana): `docs/PLAN_Testing.md`.

**Del lado de GOJAN (assets, no bloquean código)**
- 🔴 URGENTE — REDESPLEGAR EL RELAY EN RENDER (el auto-deploy NO funciona: los
  pushes del 4-jul, 8-jul y 17-jul nunca se desplegaron; Render corre el server
  del 1-jul que vacía los mazos → el online muere al empezar). En
  dashboard.render.com → nodechess-server → "Manual Deploy → Deploy latest
  commit"; y en Settings → Build & Deploy poner Auto-Deploy: Yes (branch main).
  VERIFICAR: https://nodechess-server.onrender.com debe responder
  "NodeChess relay OK v24". Después, ambos teléfonos con el build v24.
- SFX reales (11 carpetas en `game/assets/audio/sfx/`).
- Meshy: Storm Valkyrie nueva (sigue excluida de la CPU), isla real,
  rocas/árboles de borde, clips de ataque extra por figura.
- Iconografía propia para piezas/cofres/botones (hoy emojis).
- Probar build nueva en dos teléfonos (online) y reportar.

**Vuelta 02 (decidido posponer)**
- Tienda + monedas/gemas reales, anuncios/monetización (la Tienda ya se VE como
  vista previa; falta activar compras). Perfil: editar nombre/avatar.
- Misiones diarias / pity (GDD las marca "MVP disabled").
- Guardado en la nube / cuentas (hoy: local + backup Google + códigos).
- Cobertura de pruebas de UI táctil (drag&drop de banca es manual).

## 🔁 Protocolo de reanudación (si se corta la sesión)
1. Leer este archivo y `docs/PENDIENTES_Vuelta01.md` (estados por punto).
2. Suite: `run_suite.sh` estilo — cada `game/tools/test_*.gd` headless
   (`Godot_v4.6.3-stable_win64_console.exe --headless --path game --script
   res://tools/test_X.gd`); `test_net.gd` necesita `node nodechess_server/server.js`
   local; `test_net_live.gd` pega al Render desplegado.
3. El .aab solo cuando Gojan lo pida (script en scratchpad; keystore en
   `F:\GodotProjects\keystores\` — JAMÁS commitear).

## 📜 Historial breve de tandas recientes
- 🐛🎯 CAUSA RAÍZ REAL del online roto: **Render corría el server.js del 1-jul**,
  que solo aceptaba mazos ARRAY (`Array.isArray(msg.deck)`); desde el 4-jul el
  cliente manda `{team, lib}` (Dictionary) → el server viejo guardaba `[]` → el
  "start" viajaba SIN mazos (113 bytes, medido con sonda en vivo) → bancas 0/0 →
  la red de seguridad rebotaba a AMBOS al menú al instante (y antes de existir
  la red: "mapa sin figuras", el síntoma histórico). El fix del buffer (e799e7a)
  era real pero NO era el bug de los teléfonos. Remedios en esta tanda:
  · server.js: versión visible en el health (`NodeChess relay OK v24`) para
    verificar QUÉ corre Render desde fuera; push → redeploy.
  · FORMATO DE RED v24: integradas viajan como `{"nc_ref": id}` y customs SIN
    runtime (reusa `_strip_runtime`); rehidratación en NetSession.build_match
    (`CustomFigures.wire_unpack`, tolera el formato legado). Payloads: 168 B /
    1.6 KB (antes decenas de KB) — inmune a topes de tamaño para siempre.
  · VALIDACIÓN con voz: el lobby rechaza mazos rotos en ORIGEN (antes de crear
    sala) y en DESTINO (start con mazos vacíos → mensaje claro, sin ir al
    tablero); la red de seguridad del tablero deja el motivo en un popup del
    menú; bitácora persistente `user://logs/online_debug.txt` + botón 📶 en el
    lobby (ver/copiar); etiqueta "red v24" visible para confirmar que AMBOS
    teléfonos traen el mismo build. test_online_deck reescrito (formato v24,
    espejo, legado); AMBOS teléfonos deben actualizar a v24.
- 🐛 FIX CRÍTICO online: al pulsar "Empezar Partida" AMBAS pantallas "tronaban" y
  volvían al lobby ANTES de jugar. Causa: el "start" del relay lleva LOS DOS mazos
  completos y, con figuras engordadas por Piece Points (clase/evolución/pasivas/
  rangos), cruzaba los 64 KB del buffer WS por defecto de Godot → `WebSocketPeer`
  CIERRA el socket al recibir un mensaje mayor que el buffer → ambos clientes caían
  justo al iniciar (el join, que lleva UN solo mazo, sí cabía → por eso emparejaban
  bien). Fix: `NetClient._open_ws` fija `inbound/outbound_buffer_size = 1 MiB`
  ANTES de `connect_to_url`. Requiere el nuevo build en LOS DOS teléfonos. Guardado
  por `test_net` (caso "start grande" ~85 KB que sin el fix tira el socket).
- PIECE POINTS F5 (evolución): checkbox "Es Evolución" (+30% de PC) + CASTIGO al
  desplegarla sin evolucionar — toda la partida a la mitad de estamina/daño, −1★,
  SIN pasivas (construidas+ocultas) ni clase; las resistencias construidas SÍ
  sobreviven. Marca ⧗ atenuada en el tablero. El Rank-Up llega con stats
  completos (no cambia el rindex a la figura-evolución). test_evolution.
  → Sistema Piece Points COMPLETO (F1–F5).
- PIECE POINTS F4 (modelo innato): cada modelo trae pasivas/resistencias OCULTAS
  + PC; el motor las OTORGA en combate (gratis, superan los topes 3/2). Pobladas
  las 12 figuras (Stone Golem: Bedrock + resiste Congelado, etc.). El Especialista
  no hereda las pasivas ocultas (las paga si las pone); una evolución sin
  evolucionar (class_off) pierde ambas. Visible en el Creador bajo el modelo.
- PIECE POINTS F3 (clases con efectos): cada clase aplica buff+debuff EN PARTIDA
  (Ágil +1⚡/−10 daño/−1★ · Tanque azul indestructible+resiste Debilitado/−1⚡ ·
  Atacante +15 daño/−1⚡ · Debilitador +1★+estados+2t/−15 · Potenciador +1
  energía equipo/−10/−1⚡ · Controlador desplaza+1 nodo+inmune/−10). Visible en el
  Creador; `class_off` los anula (hook para F5). Test `test_classes`.
- PIECE POINTS F1+F2: motor `PiecePoints` (costo/presupuesto/desglose) calibrado
  contra los 8 integrados; medidor "PC usado/presupuesto" con barra y ⓘ en el
  Creador; pasarse de PC BLOQUEA el guardado (usuario; admin bypass); aviso si
  el destino de evolución ya trae la resistencia/pasiva elegida. Fix del botón
  Guardar tapado (banner de 1 línea + candado airtight). Plan v2 en
  `docs/Balance_PiecePoints.md`.
- 🤖 MODO ROBOT (Capa 2-3 del plan): botón admin en Configuración que hace un
  tour REAL (economía→creador→mazos→cofres→partidas CPU vs CPU renderizando)
  con log [PASS]/[FAIL] a user://autotest/ + popup con copiar; respalda y
  RESTAURA los datos del jugador siempre; burn-in de 10 partidas con fps/mem;
  corrible por CLI (robot_boot.gd, exit code = fallos). 1er hallazgo: bots
  difíciles pueden empatar técnico a la defensiva (>250 medio-turnos).
- FULL TUTORIAL: aula "Cómo jugar" con 11 capítulos (8 lecciones guionadas con
  resultados marcados + gate de acciones + 👉, 2 guías de menú, XP por capítulo,
  bienvenida con pendientes). 🤖 Modo Robot en standby (docs/STANDBY_ModoRobot.md).
- STATS INVENTARIADAS: daños (5–100 de 5 en 5), estrellas (1–3), probabilidades
  (5–70%) y clases ahora son PIEZAS coleccionables con reglas de consumo por
  color (blanco/oro consumen daño; púrpura consume estrellas; azul/rojo ni uno
  ni otro; todo segmento consume su %). Tienda con categoría 💥 Potencia; kit
  inicial ampliado; doc de diseño `docs/Balance_PiecePoints.md` (fórmulas y
  roadmap del sistema Piece Points).
- CONSUMIBLES BLINDADOS: precio CANÓNICO en el motor (la UI jamás lo decide —
  anti-trampa), compra/crafteo/cofres atómicos y validados con RECIBO,
  🧾 log persistente de movimientos (evidencia para soporte) con visor en el
  Inventario, ventana vistosa RewardPopup en compras/crafteos/cofres,
  descifrado LIBRE (el cofre que quieras, varios a la vez), ranuras (N/4)
  visibles y aviso de "ranuras llenas" en la victoria.
- ECONOMÍA VIVA: 🪙 por nivel + 💎 cada 5 niveles y en cajas (%), Tienda que
  compra DE VERDAD al inventario, cofres GANADOS por victoria con descifrado
  manual (Inventario), chips de recompensa en la victoria, fondos admin.
- FIX crítico online: JAMÁS empezar sin banca. El lobby muestra el MAZO EN USO
  (nombre + 6/6) y bloquea crear/unirse si está incompleto o con figuras no
  poseídas; Board3D aborta al menú si algún mazo llega vacío; offline cae al
  equipo por defecto. Deck Builder: tarjetas de mazo con ✓ EN USO (el que juega
  online y vs CPU), renombrar ✎, borrar con confirmación (y sin pisar el Mazo 1
  — bug corregido), ＋ Nuevo; reorden: equipo → disponibles → ajustes de
  partida. Configuración: 🗑 borrar inventario (piezas+fragmentos; personajes,
  XP y cofres intactos; re-entrega el kit inicial en modo usuario).
- Tienda y Perfil visitables (vista previa) + flujo USUARIO de crafteo visible:
  📦 en el Creador (tus piezas ×N), stats de perfil persistentes.
- Rediseño de menús Part 6 (handoff): helpers UITheme, Home hipnótico, chips,
  scroll visible, banner de validación + fixes de teléfono (servidor oculto,
  nombres visibles, Deck Builder scrolleable).
- **Vuelta01 completa (F0–F6)**: zoom táctil, mazo de 6, resistencias,
  hover/fast-recovery, dash/retirada/teleport, buff nodes con carga,
  10 modificadores (trampas/revive/escudo…), gating de mazos por posesión,
  multi-mazos + NCDECK1, Dex 2.0, dificultad+personalidades CPU, timer online,
  reconexión, revancha, combate ×2/skip, modo daltónico, portal visual,
  mapa "Cruce", cofre de nivel y tutorial jugable.
- Cofres al lobby + animación de apertura; Inventario como pantalla propia.
- IA CPU 5 comportamientos + despliega-y-camina; salto verificado con tests.
- FIX online desincronizado (mazo team/lib) + anti-stack + preview universal.
- Mapas +1 fila con candados temporales; buff aterrizado como su propio tile.
- Economía real de piezas + XP/niveles + retratos de banca + animaciones de fin.
