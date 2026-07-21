# PENDIENTES — Vuelta 03 (petición de Gojan, 2026-07-20)

> Lote nuevo de trabajo. Orden de ejecución por DEPENDENCIA: bugs/verificación
> rápidos → rediseño de cajas → anuncios → tutorial META → matchmaking online.
> Las cajas son la base del tutorial-meta y de los anuncios, por eso van antes.

## 🎯 EN ESTA VUELTA (hacer)

### A. Bugs / verificación (rápidos)
- [x] **Salto**: a veces atravesaba rivales. Arreglado (move_path respeta el
      candado; arco Bézier por encima). test_jump reforzado. (commit 4c66707)
- [ ] **Tutoriales de gameplay**: verificar que las 11 lecciones cargan y
      avanzan sin crash EN VIVO (Board3D), no solo la data.

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

## ⏳ Sigue pendiente (de antes)
- Prueba ONLINE en 2 teléfonos (Gojan; server ya en v24).
- Assets de Gojan (SFX, iconos, Meshy).
