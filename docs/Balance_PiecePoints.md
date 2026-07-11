# NodeChess — Piezas, fórmulas de creación y el futuro sistema "Piece Points"

> NodeChess es un ajedrez dinámico **y** un "construye tus piezas": el jugador
> desbloquea PIEZAS (stats, ataques, clases…) y las combina con creatividad en
> el Creador. Este documento explica (1) qué es pieza HOY y sus reglas de
> consumo, y (2) cómo evolucionar esto hacia un sistema de **Piece Points (PP)**
> para darle razón y movimiento a las fórmulas de creación y balance.

---

## 1. El inventario HOY: todo lo creable es una pieza

Cada atributo del Creador es una pieza coleccionable (`prefijo:valor`), que se
consigue en cofres/tienda/crafteo y **se consume 1 vez al guardar la figura**
(editar cobra solo el delta y reembolsa lo retirado):

| Pieza | Rango | La consume… |
|---|---|---|
| `model:<id>` | 1 por figura integrada | el modelo/figura elegida |
| `rarity:<r>` | común/rara/épica/legendaria/mítica | la rareza de la figura |
| `class:<c>` | 8 clases (Balanced, Agile, Tank…) | la clase elegida¹ |
| `atype:<t>` | Ruleta, Dados, Monedas, Suma 2d6 | el tipo de ataque |
| `stamina:<n>` | 0–6 | la estamina de la figura |
| `color:<c>` | blanco/oro/púrpura/azul/rojo | cada color usado en el pool |
| `pow:<n>` | **5–100, de 5 en 5** | el daño del segmento — **solo Blanco/Oro** |
| `stars:<n>` | **1–3** | las estrellas — **solo Púrpura** |
| `prob:<n>` | **5–70%, de 5 en 5** | el peso de **cada** segmento |
| `fx:<estado>` | 13 estados + desplazamientos | el efecto del segmento |
| `passive:<id>` | catálogo de pasivas | cada pasiva equipada (máx 3) |
| `resist:<id>` | 13 estados | cada resistencia (máx 2) |

¹ Las clases aún no otorgan pasivas ocultas ni bonos; ya están inventariadas
para que cuando definan su contenido no haya migración.

**Reglas de consumo por color** (en `Inventory.required_pieces`):
- Blanco/Oro consumen su `pow:` — van con 0 estrellas (no consumen `stars:`).
- Púrpura consume sus `stars:` — no lleva daño (no consume `pow:`).
- Azul/Rojo no consumen ni daño ni estrellas.
- TODO segmento consume su `prob:` (pesos legados fuera de 5–70/paso 5 no cobran).

**Fuentes y sumideros** (economía cerrada):
- Fuentes: cofres ganados por VICTORIA (60/30/10), cofre de nivel, caja gratis
  (fragmentos; 10 = 1 pieza), tienda (🪙 por nivel, 💎 cada 5 niveles y % en cajas).
- Sumideros: crear figuras (consume piezas), comprar (consume 🪙/💎).
- Blindaje: precios canónicos en el motor, transacciones atómicas con recibo,
  🧾 log persistente (evidencia para soporte).

---

## 2. El futuro: Piece Points (PP) — presupuesto de poder por figura

**Problema a resolver**: hoy el límite creativo es *poseer las piezas*. Cuando
la colección crece, un jugador con todo podría armar "la figura perfecta"
(daño 100 al 70%, estamina 6, 3 pasivas top). El PP añade un segundo eje:
**cada pieza cuesta puntos y cada figura tiene un presupuesto**.

### 2.1 La fórmula base

```
PP(figura) = PP(stamina) + PP(clase) + Σ PP(segmento_i) + Σ PP(pasiva) + Σ PP(resist)
PP(segmento) = [ V(color) + V(pow ó stars) + V(fx) ] × M(prob)
```

- `M(prob)` = multiplicador por peso: un ataque fuerte al 70% debe costar mucho
  más que al 10%. Propuesta: `M = prob / 25` (25% = costo "nominal").
- El **presupuesto** lo fija la RAREZA de la figura (la pieza `rarity:` compra
  techo de poder, no cosmética):

| Rareza | Presupuesto PP (propuesta) |
|---|---|
| Común | 90 |
| Rara | 120 |
| Épica | 150 |
| Legendaria | 190 |
| Mítica | 240 |

### 2.2 Valores semilla (V) — punto de partida para calibrar

| Componente | V propuesto |
|---|---|
| `pow:n` | `n × 0.5` (daño 60 → 30 PP) |
| `stars:1/2/3` | 15 / 32 / 55 (no lineal: ★3 gana a casi todo) |
| color Azul (bloqueo) | 22 plano |
| color Rojo (fallo) | **−8** (descuento: pagas por fiabilidad, cobras por riesgo) |
| `fx:` estado leve (Debilitado, Marcado…) | 8–12 |
| `fx:` control duro (Miedo, Paralizado, Congelado, Sueño) | 20–28 |
| desplazamientos (empuje/dash/teleport…) | 10–18 |
| `stamina:n` | `n² × 3` (2→12, 4→48, 6→108: la movilidad escala brutal) |
| pasiva | 15–35 según catálogo (tabla propia) |
| resistencia | 12 c/u |
| clase | 0 hoy; cuando den bonos, su V = valor del bono |

### 2.3 Cómo calibrar: los 8 integrados son la regla de medir

Los integrados YA se sienten bien en mesa → calcula su PP con las tablas y
ajusta los V hasta que caigan cerca del presupuesto de su rareza:

```
Nightblade (épica, ST3, Moneda):
  Killing Edge  blanco 100 al 49.5% → (100×0.5) × (50/25) ≈ 100
  Fear Gas      púrpura ★2 + Miedo al 49.5% → (32+24) × 2 ≈ 112 → ¡se pasa!
  → o el presupuesto épico sube, o V(Miedo)/M(prob) bajan: ITERAR AQUÍ.
```

Ese "se pasa" es la señal de calibración: repetir con los 8 hasta que la regla
de medir cuadre, y SOLO entonces aplicárselo a las customs.

### 2.4 Proceso de balance vivo (cuando haya jugadores)

1. **Telemetría mínima**: por figura custom → winrate, pick-rate; por pieza →
   presencia en mazos ganadores. (Local primero: el 🧾 log ya registra creación.)
2. **Regla 55/45**: pieza presente en >55% de mazos ganadores → sube su V un
   paso (+10–15%); <45% → baja. Ajustar V de PIEZAS, no nerfear figuras a mano.
3. **Cadencia**: revisar por "vueltas" (como Vuelta01/02), no en caliente.
4. **Techos duros que ya existen** (mantener siempre): prob ≤ 70%, daño ≤ 100,
   ★ ≤ 3, pasivas ≤ 3, resist ≤ 2, mazo de 6, validador de suma 100%.

### 2.5 Roadmap de implementación

- **F1 — Medidor (sin bloquear)**: `FigureValidator.pp_of(fig)` + barra
  "PP usados / presupuesto" en el Creador y la Dex. Solo informa.
- **F2 — Presupuesto real**: guardar figura exige PP ≤ presupuesto de su rareza
  (modo usuario; admin ilimitado). Las figuras viejas se marcan "legado".
- **F3 — Rarezas con dientes**: subir de rareza una figura (fusión de piezas
  `rarity:`) amplía su presupuesto → progresión de colección con propósito.
- **F4 — Telemetría y ajuste por temporada** (§2.4).

> **Regla de oro**: los valores de este doc son SEMILLA, no ley. La única
> verdad es la mesa: calibrar contra los integrados primero, contra datos después.
