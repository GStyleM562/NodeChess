# PENDIENTES — Vuelta 03 (petición de Gojan, 2026-07-20)

> Lote nuevo de trabajo. Orden de ejecución por DEPENDENCIA: bugs/verificación
> rápidos → rediseño de cajas → anuncios → tutorial META → matchmaking online.
> Las cajas son la base del tutorial-meta y de los anuncios, por eso van antes.

## 🎯 EN ESTA VUELTA (hacer)

### A. Bugs / verificación (rápidos)
- [x] **Salto**: a veces atravesaba rivales. Arreglado (move_path respeta el
      candado; arco Bézier por encima). test_jump reforzado. (commit 4c66707)
- [x] **Tutoriales de gameplay**: verificar que las lecciones cargan y avanzan
      EN VIVO (Board3D), no solo la data. `test_lessons_live` recorre las 8
      lecciones paso a paso. (commit 7d37338)
- [x] **FIX lecciones atoradas**: el test recorría los pasos por código, pero
      NADIE creaba el modelo 3D de las figuras que la lección PRE-COLOCA (solo
      se creaba al desplegar) → figuras invisibles/intocables y lección
      atorada para siempre. `_spawn_preplaced()` + aserción
      `modelos3D == unidades_en_tablero` en el test. (commit 35257bc)
- [x] **Legibilidad en modo oscuro**: 9 paneles del HUD tenían fondo claro FIJO
      con texto que sí seguía al tema → `UITheme.surf()/tint()`. (35257bc)

### HECHO en esta vuelta
- [x] B. Cajas por tipo (motor + tienda en Recompensas). commits 845e47d,0ce71e6
- [x] C. Anuncios diarios (🪙/💎/caja). commit 0ce71e6
- [x] D. Tutorial META "Progreso" (+ kit regalado). commit 6860948
- [x] E. Matchmaking "Encontrar rival" (server v25 + cliente). ✅ DESPLEGADO:
      https://nodechess-server.onrender.com responde "NodeChess relay OK v25"
      (verificado 2026-07-25). Falta solo la prueba humana en 2 teléfonos.

### B. Sistema de CAJAS por tipo (rediseño)  ← base de C y D
- Agrupar para NO tener demasiados tipos, pero poder buscar lo que quieres:
  - **Caja de FIGURAS** (modelos), **Caja de PIEZAS DE ATAQUE**
    (colores/potencia/estados/tipos), **Caja de PASIVAS**, **Caja RANDOM**
    (lo que sea, todas las categorías).
  - **Rareza** aplica igual: mejor rareza → MÁS contenido, pero ESPECÍFICO de
    esa caja (una caja de figuras épica = más/mejores figuras; una random épica
    = más de todo).
- Reusar el motor de cofres actual (descifrado por tiempo, ranuras) — solo
  añadir el EJE "tipo" al contenido.

### C. ANUNCIOS con usos diarios
- 2–3 tipos con límite por día: (1) ver anuncio → 🪙 monedas · (2) → 💎
  diamantes · (3) → 📦 caja aleatoria. Sin red real: simulado (espera breve).

### D. Tutorial META (no de partida): cómo CONSEGUIR/mejorar personajes
- Capítulos: cómo CREAR un personaje · cómo MANEJAR el inventario · cómo
  funcionan las CAJAS · qué son los recursos (🪙/💎/fragmentos), cómo se
  obtienen y para qué.
- CLAVE: cada vez que se juega el tutorial, **regala las piezas necesarias**
  para construir lo que enseña — siempre un personaje BÁSICO / de nivel bajo,
  para que no importe "regalar" piezas. Cada capítulo que lo necesite.

### E. Online: "ENCONTRAR RIVAL" (matchmaking simple)
- Además de "crear sala": botón para emparejar con un rival RANDOM (cola en el
  relay). Necesita cambio en `server.js` (redeploy en Render) + cliente.
- NOTA: no verificable hasta que Gojan redespliegue Render.

## 🚫 POSPUESTO por decisión de Gojan (NO hacer ahora)
- Puzzle Battles · Boss Battles · Arquetipos de mapa nuevos.
- **PvP gate / ladder**: no habrá ladder; solo "crear sala" + "encontrar rival".
- Colección completa (skins/wishlist/siluetas).
- Personalidades de bot extra (las 5 actuales bastan).
- Conversión inversa duplicados→fragmentos (sin utilidad por ahora).

## ✅ VUELTA 03 CERRADA (2026-07-25)
Todo A–E hecho. Lo que siguió después (legal, modo oscuro, rediseño de Home,
splash/icono, menú de pausa, pestañas, pulido de tema) está en el CHANGELOG.

## ⏳ Sigue pendiente (de antes) → ver `PENDIENTES_Lanzamiento.md`
- Prueba ONLINE en 2 teléfonos (Gojan; server ya en v25 desplegado).
- Assets de Gojan: **AUDIO (el juego está mudo: 0 archivos)**, iconos, Meshy.
- Anuncios reales (plugin AdMob + `UNIT_RELEASE`) y trámites de Play Console.
