# NodeChess — Estado del proyecto y registro de cambios

> Resumen vivo: qué está HECHO, qué entró en la última tanda, y qué queda
> PENDIENTE (mecánicas / diseño / mapa / técnico). Actualizado: 2026-07-04.

## ✅ Sistemas funcionando hoy

**Núcleo de juego**
- Combate por colores del GDD (Blanco vs Oro POR DAÑO), 13 estados, pasivas,
  desplazamientos (empuje/jalón/intercambio), KO por rodeo, Rank Up en partida
  con cambio de modelo, energía + modificadores, buff node.
- Saltos: aterrizan en cualquier casilla libre adyacente al rival (imposible si
  está tapado); aterrizajes en DORADO + banner "¡SALTO!".
- Anti-stack de motor (`move_unit` rechaza ocupados) + auditor `board_consistent`.
- Mapas (4): +1 fila (mínimo entrada→meta 6–8), candados temporales 🔒 que abren
  en la ronda 3, espejo 180° automórfico verificado (requisito online).
- IA CPU (docs/AI_CPU.md): GANAR YA → PORTERO → CERCO → ATAQUE ÚTIL →
  DESPLIEGA TODO (y camina con la estamina restante) → BUFF → AVANZA ESQUIVANDO.

**Online 1v1**
- Relay Node en Render (free, con arranque en frío tolerado por el cliente:
  wake-GET + reintentos ~3 min). Salas por código de 4 letras.
- Lockstep determinista + perspectiva local sin voltear tablero.
- Mazo viaja {"team", "lib"} (cierre de evoluciones separado) → uids/modelos
  idénticos en ambas pantallas.

**Progresión / economía (base de monetización)**
- Modo ADMIN (todo ∞) / USUARIO (regla dura) en Configuración.
- Inventario persistente de PIEZAS del Creador (figuras, rarezas, tipos,
  colores, estados, pasivas, estamina) + fragmentos (10 = 1 pieza).
- Cofres en el lobby con animación de apertura: Gratis (fragmentos) +
  5/10/15 min por reloj real (rearman al reclamar; mejores piezas por nivel).
- ECONOMÍA REAL: crear un personaje GASTA sus piezas; editar cobra solo lo
  nuevo y reembolsa lo retirado; las piezas invertidas no bloquean la edición.
- XP y NIVELES persistentes: +60 victoria / +25 derrota (+15 online); cada
  nivel regala piezas premium; barra animada al final de la partida y nivel
  visible en el menú.
- Personajes custom: guardado local + códigos de respaldo/compartir
  (NCFIG1/NCPACK1) con importación validada.
- TODO el progreso persiste local en user:// (inventario, ajustes, mazos,
  customs) + respaldo automático de Google activado en el export.

**Presentación**
- Tablero 3D con assets Meshy o 2D digital futurista (grid emisivo + chispas),
  elegible en Configuración. Cache estática de GLBs (carga rápida tras la 1ª).
- Banca con RETRATOS 3D de tus personajes + contador ⏳ de regreso de cada K.O.
- Invocación al desplegar, luces de victoria/derrota en combate, banner
  "¡ES TU TURNO!", preview de CUALQUIER figura (aliada/rival, cualquier turno).
- Victoria: tarjeta que estalla + confeti; Derrota: tarjeta que cae + sacudida.
- Música por estado (menú/partida/ventaja/peligro con retorno) + 11 slots SFX;
  volúmenes en Configuración ⚙ (y vista Admin/Usuario, tablero 3D/2D).

## 🕐 PENDIENTES (revisión honesta)

**Mecánicas**
- Buff nodes del GDD completos (cargas, cooldown, ownership; hoy: bono al pisar).
- Catálogo de modificadores GDD (trampas, revive, escudos…) — hoy 4 básicos.
- Resistencias a estados por figura (GDD) — no implementadas.
- Timer por turno online (dejado preparado, no activado).
- Reconexión a partida online tras cerrar la app.
- Cofre por nivel (hoy los niveles regalan piezas directas) y XP→misiones.

**Diseño / UX**
- Tienda y Perfil reales (placeholders a propósito).
- Dex/Colección: búsqueda, filtros, favoritos (GDD Collection).
- Iconografía propia para piezas/cofres (hoy emojis).
- Animaciones de ataque por tipo de figura (hoy set genérico).
- Tutorial/onboarding (GDD contempla 10).

**Mapa / assets**
- Decoración de borde (rocas/árboles) e ISLA como asset (el GLB actual en
  island_platform es un tramo de camino, no se usa).
- Portal de Túneles con visual de portal; más arquetipos de mapas GDD.
- Reemplazar el modelo de Storm Valkyrie (buggeado, "el ave") — excluida de la
  CPU mientras tanto.

**Técnico**
- Guardado en la nube (hoy local + backup Google).
- Cobertura de pruebas de UI táctil (drag&drop de banca es manual).

## 📜 Historial breve de tandas recientes
- Cofres al lobby + animación de apertura; Inventario como pantalla propia.
- IA CPU 5 comportamientos + despliega-y-camina; salto verificado con tests.
- FIX online desincronizado (mazo team/lib) + anti-stack + preview universal.
- Mapas +1 fila con candados temporales; buff aterrizado como su propio tile.
- Economía real de piezas + XP/niveles + retratos de banca + animaciones de
  fin de partida + menú con acentos/partículas + piso 2D futurista + ⏳ de K.O.
