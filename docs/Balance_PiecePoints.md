# NodeChess — Construcción y balance de personajes (Piece Points v2)

> Plan exhaustivo del sistema de **Puntos de Construcción (PC)**: qué te DA
> presupuesto, qué te lo GASTA, cómo las CLASES cambian al personaje (buffs y
> debuffs reales), qué aportan las FIGURAS/modelos (PC + pasivas/resistencias
> ocultas gratis), y cómo funciona la mecánica de **EVOLUCIÓN** (bono de
> presupuesto + castigo por usarla sin evolucionar). Escrito para revisar el
> DISEÑO antes de codificar. Los números son SEMILLA — se calibran en la Fase 1
> contra las 8 figuras integradas (que ya se sienten bien en mesa).
>
> Estado del inventario base y reglas de consumo por color: ver el CHANGELOG y
> `Inventory.required_pieces`. Este doc añade la CAPA de PODER encima de eso.

---

## 0. La idea en una frase

Hoy el límite creativo es *poseer las piezas*. El PC añade un segundo eje:
**cada cosa que le pones a tu figura cuesta puntos, y tu figura tiene un
presupuesto**. Poseer la pieza te deja usarla; el presupuesto decide si CABE.
Así una figura no puede ser "todo a la vez" y cada decisión (clase, rareza,
evolución, modelo) importa.

---

## 1. El libro mayor: FUENTES vs COSTOS

```
PC_disponible  =  ( Rareza  +  Clase  +  Modelo_innato )  × ( 1.30 si Es Evolución )
PC_gastado     =  Σ segmentos_de_ataque  +  Estamina  +  Tipo_de_ataque
                  +  Σ pasivas_construidas  +  Σ resistencias_construidas
REGLA DURA:  PC_gastado ≤ PC_disponible   (si no, la figura es INVÁLIDA)
```

Lo que la figura/modelo trae de fábrica (pasivas y resistencias OCULTAS) **no
gasta PC ni piezas** y **no cuenta contra los topes** (§4).

---

## 2. FUENTES de presupuesto

### 2.1 Rareza (la fuente principal)
La pieza `rarity:` deja de ser cosmética: **compra techo de poder**.

| Rareza | Presupuesto base |
|---|---|
| Común | **100** |
| Rara | **135** |
| Épica | **175** |
| Legendaria | **220** |
| Mítica | **280** |

> **Calibrados (2026-07-13) contra los integrados**: costo máximo medido por
> rareza — común 75 (Ironclad) · rara 79 (Storm Valkyrie) · épica 145
> (Nightblade, el más fuerte) · legendaria 103 (Coin Trickster). Todos CABEN,
> con margen creciente por rareza (mejores piezas → más techo). Implementado en
> `PiecePoints.gd`; test `test_piecepoints`.

### 2.2 Clase (§3 detalla buffs/debuffs)
Algunas clases dan +PC en vez de stats:

| Clase | +PC |
|---|---|
| Balanced | +20 |
| Especialista | +30 |
| Controlador | +5 |
| (las demás) | +0 (su valor está en los stats) |

### 2.3 Modelo / figura (innato)
Cada MODELO 3D tiene un perfil innato: **+PC** + pasivas ocultas + resistencias
ocultas (§4). Los modelos con identidad fuerte (Stone Golem = muralla) dan más
PC/rasgos; el modelo placeholder da 0. Es lo que hace que ELEGIR modelo importe.

### 2.4 Evolución (checkbox "Es Evolución")
Multiplica TODO el presupuesto por **1.30**. Razón: una figura marcada como
evolución solo entrega sus stats COMPLETOS si de verdad evolucionó en partida
(más difícil de lograr) → se le permite ser más fuerte. El castigo por usarla
sin evolucionar está en §5.

---

## 3. COSTOS de presupuesto (qué gasta PC)

### 3.1 Segmentos de ataque (el grueso del costo)
```
CostoSegmento = [ V(color) + V(daño ó estrellas) + V(efecto) ] × M(prob)
M(prob) = prob / 50      # 50% = costo nominal ·1.0 · 70% = ·1.4 · 10% = ·0.2
```

| Componente | Valor semilla |
|---|---|
| color Blanco | 0 (daño puro, referencia) |
| color Oro | +5 (además vence a Púrpura, inmune a sus efectos) |
| color Púrpura | +8 (aplica efecto) |
| color Azul | +22 (bloqueo: vence a todo lo ofensivo) |
| color Rojo | **−6** (Fallo: pagas MENOS por meter una debilidad) |
| Daño (Blanco/Oro) | `pow × 0.35` (60 daño → 21) |
| Estrellas ★1/★2/★3 (Púrpura) | 10 / 22 / 40 (no lineal: ★3 gana a casi todo) |
| Efecto leve (Debilitado, Marcado, Escudo Roto…) | +8 |
| Efecto de control duro (Miedo, Paralizado, Congelado, Sueño) | +20 |
| Desplazamiento (Empuje/Jalón/Dash/Retirada/Teleport) | +12 |

### 3.2 Estamina (la movilidad escala fuerte)
| Estamina | 0 | 1 | 2 | 3 | 4 | 5 | 6 |
|---|---|---|---|---|---|---|---|
| Costo | 0 | 3 | 8 | 16 | 28 | 44 | 64 |

### 3.3 Tipo de ataque (consistencia = costo)
Ruleta 0 (base) · Dado D4/D6 +4 · Dado D8/D10/D12 +10 · Moneda +6 ·
Doble Moneda +12 · Suma 2d6 +15.

### 3.4 Pasivas y resistencias construidas
- Pasiva: tabla por pasiva (semilla 8–25; default 15). Las auras y las
  "once-per-match" fuertes cuestan más.
- Resistencia: 10 cada una.

> Las pasivas/resistencias que vienen del MODELO (ocultas) **no** entran aquí.

---

## 4. FIGURAS con rasgos OCULTOS (gratis y por encima de los topes)

Cada modelo declara un perfil innato, **visible** al inspeccionar la figura
("Este modelo YA trae: 🛡 Resiste Miedo · ✨ Bedrock"):

```gdscript
# en Roster.FIGURES[i]:
"innate": { "pc": 10, "passives": ["bedrock"], "resists": ["fear"] }
```

Reglas:
- **Gratis**: no gastan PC ni piezas.
- **Superan los topes**: hoy máx 3 pasivas / 2 resistencias CONSTRUIDAS. Las
  ocultas se SUMAN encima (p. ej. 3 construidas + 1 oculta = 4 activas). Así una
  figura "de raza" puede tener más rasgos que una genérica — recompensa elegir
  bien el modelo.
- **Visibles siempre**: en el Creador (aviso "ahorras esta pasiva, ya la trae")
  y en la Dex.
- Beneficio de diseño: te **ahorra** PC y piezas si el rasgo que ibas a poner ya
  lo trae el modelo → premia la sinergia modelo↔build.

---

## 5. CLASES — buffs y debuffs que CAMBIAN al personaje

Hoy las 8 clases están inventariadas pero vacías. Propuesta: cada clase aplica
modificadores **EN PARTIDA** sobre los stats construidos (como el ejemplo del
Ágil: construyes estamina 2, pero JUEGA con 3). Mantengo las 8 (mapean 1:1 con
las actuales), redefinidas con identidad afilada. **Cada una es un trueque.**

| Clase | +PC | BUFF (en partida) | DEBUFF (en partida) |
|---|---|---|---|
| **Balanced** | +20 | — | — |
| **Ágil** | 0 | +1 estamina | Blanco/Oro −10 · Púrpura −1★ |
| **Tanque** | 0 | +1 resistencia innata · su Azul ignora "Escudo Roto" | −1 estamina |
| **Atacante** | 0 | Blanco/Oro +15 | −1 estamina |
| **Debilitador** | 0 | Púrpura +1★ · sus estados duran +2 turnos | Blanco/Oro −15 |
| **Potenciador** | 0 | +1 energía por turno | Blanco/Oro −10 · −1 estamina |
| **Controlador** | +5 | desplazamientos +1 nodo · inmune a ser desplazado | Blanco/Oro −10 |
| **Especialista** | +30 | — (presupuesto puro) | NO hereda las pasivas ocultas del modelo |

Notas de diseño:
- Los buffs/debuffs de daño son **aditivos** (−10 sobre un ataque de 60 = 50) y
  **con piso 0** (nunca negativo). Las estrellas nunca bajan de 1.
- El debuff hace que armar un Ágil con ataques de daño sea mala idea (pega
  flojo) y empuja a jugarlo con Púrpura/Azul/movilidad → **la clase moldea el
  arquetipo**, justo lo que pediste.
- ¿Añadir/quitar clases? Recomiendo **mantener 8**: cubren los arquetipos del
  GDD (agro, muralla, control, apoyo, movilidad, generalista, min-maxer) sin
  solaparse. Si en pruebas dos se sienten iguales, se fusionan; no antes.
- Todo esto ya encaja en el motor: los buffs/debuffs se aplican como una capa
  al calcular `effective_stamina`, el daño en `_roll_full` y las estrellas —
  los mismos puntos donde hoy se aplican aura/haste/buff-node.

---

## 6. EVOLUCIÓN — el checkbox y su castigo

### 6.1 "Es Evolución" (marca en el Creador)
- **Sube el presupuesto ×1.30** (§2.4): puedes meterle más poder.
- Pensada para figuras que son el DESTINO de un Rank-Up (otra figura evoluciona
  EN ésta y hereda sus stats completos).

### 6.2 Castigo por usarla SIN evolucionar (todo la partida)
Si una figura marcada "Es Evolución" se **despliega directamente** (va en el
mazo como forma base, no se alcanza por Rank-Up), arranca con un debuff que dura
**toda la partida** — para enseñar que NO debes usar tu evolución sin evolucionarla:

- **Estamina** → a la mitad, redondeando abajo (4→2, 3→1).
- **Daño Blanco/Oro** → a la mitad (100→50).
- **Estrellas Púrpura** → −1 (si ya es 1, se queda en 1).
- **Se le quitan TODAS**: pasivas construidas, pasivas ocultas del modelo, y los
  buffs de clase.
- **Resistencias ocultas** del modelo → también se retiran. Las resistencias que
  CONSTRUISTE (pagaste piezas) se conservan.
- El debuff de clase se **neutraliza** junto con el buff (no se doble-castiga):
  la figura juega como una versión "a medio hacer", floja y sin trucos.

Marcado visual en el tablero: nombre con "⧗ sin evolucionar" y tinte apagado.
Cuando SÍ llega por Rank-Up, entra con todos sus stats completos (el motor ya
cambia la figura en el Rank-Up; aquí solo NO se aplica el castigo).

### 6.3 Cómo lo sabe el motor
- El dict de figura lleva `is_evolution: true`.
- Al desplegar desde banca: si `is_evolution` y la unidad **no** provino de un
  Rank-Up → aplicar el transform del castigo (una función `_deform_unevolved`
  sobre la copia de combate, no sobre la figura guardada).
- Rank-Up hacia esta figura → sin castigo (stats completos).

---

## 7. VALIDACIÓN — imposible guardar una figura errónea

El PC entra en el `FigureValidator` como una regla DURA:

- `PC_gastado > PC_disponible` → **INVÁLIDO** (no solo aviso). El Creador YA
  bloquea el guardado en INVÁLIDO (candado airtight, arreglado 2026-07-13), así
  que una figura sobre-presupuesto **no se puede guardar** → jamás entra a una
  partida y no puede romper el balance ni desincronizar el online.
- El banner del Creador muestra en vivo **"PC 138/120 — te pasas por 18"** con
  el ⓘ desglosando de dónde sale cada punto (segmentos, estamina, pasivas…).
- Una barra "PC usados / presupuesto" (verde→ámbar→rojo) da feedback inmediato.

---

## 8. CALIBRACIÓN — los 8 integrados son la regla de medir

Las figuras integradas YA se sienten bien → calcula su PC y ajusta las CONSTANTES
(no las figuras) hasta que cada una caiga cerca del presupuesto de su rareza.

**Ejemplo trabajado — Nightblade (hoy épica, tipo Moneda, ST3):**
```
Estamina 3 ............................. 16
Tipo Moneda ............................ +6
Killing Edge  Blanco 100 @ 49.5% ....... (0 + 100×0.35) × (49.5/50) ≈ 35
Fear Gas  Púrpura ★2 + Miedo @ 49.5% ... (8 + 22 + 20) × 0.99 ≈ 50
Rojo @ 1% .............................. ≈ 0
Pasivas lunge+bloodthirst+parkour ...... 15+18+12 = 45
                                          ─────
TOTAL ≈ 152      vs      presupuesto ÉPICO 120
```
Sale **+32 sobre presupuesto** → señal de calibración. Opciones (elige en F1):
(a) Nightblade en realidad es **Legendaria** (155) y cuadra; o (b) baja el costo
de pasivas / el multiplicador M(prob). Repetir con las 8 hasta que la regla de
medir cuadre, y SOLO entonces aplicarla a las figuras custom.

**Balance vivo (cuando haya jugadores):** telemetría de winrate/pick por pieza →
regla 55/45 (pieza en >55% de mazos ganadores sube su V un paso; <45% baja).
Ajustar V de PIEZAS, no nerfear figuras a mano. Revisar por "vueltas", no en caliente.

**Techos duros que se mantienen SIEMPRE** (además del PC): prob ≤ 70%, daño ≤ 100,
★ ≤ 3, pasivas construidas ≤ 3, resistencias construidas ≤ 2, mazo de 6,
suma de ruleta = 100%.

---

## 9. Roadmap de implementación (tras aprobar este diseño)

| Fase | Qué | Estado |
|---|---|---|
| **F1 — Medidor** | `PiecePoints.cost/budget/breakdown` + barra "PC usado/presupuesto" + ⓘ desglose en el Creador. Calibrado vs los 8 integrados. | ✅ HECHO (2026-07-13). |
| **F2 — Presupuesto real** | Pasarse de PC bloquea el guardado (modo usuario; admin bypass, herramienta de dev). El aviso de evolución (destino ya tiene esa resistencia/pasiva) también entra aquí. | ✅ HECHO. |
| **F3 — Clases con efectos** | Buffs/debuffs de §5 aplicados en partida (estamina, daño Blanco/Oro, estrellas Púrpura, duración de estados, energía de equipo, desplazamiento e inmunidad; Tanque: Azul indestructible + resiste Debilitado). Efecto visible en el Creador. `class_off` anula todo (hook para F5). | ✅ HECHO (2026-07-13). |
| **F4 — Modelo innato** | `innate` poblado en los 12 modelos (pasivas/resistencias ocultas + PC); el motor las OTORGA en combate (has_passive/resists_status, gratis + superan topes 3/2). Especialista no hereda las pasivas; `class_off` pierde ambas. Visible en el Creador bajo el modelo. | ✅ HECHO (2026-07-13). |
| **F5 — Evolución** | Checkbox "Es Evolución" (+30% budget) + castigo al desplegar directo: mitad de estamina/daño, −1★, sin pasivas (construidas+ocultas) ni clase, resistencias construidas SÍ sobreviven; marca ⧗ en tablero. | ✅ HECHO (2026-07-14). |
| **F6 — Telemetría** | Datos anónimos de winrate por pieza para el ajuste 55/45. | Post-lanzamiento. |

> **Regla de oro**: los valores de este doc son SEMILLA, no ley. La única verdad
> es la mesa: calibrar contra los integrados primero, contra datos después.

---

## 10. Decisiones que necesito de TI antes de codificar F1

1. **Presupuestos por rareza** (§2.1): ¿te cuadran 70/95/120/155/200, o quieres
   más/menos separación entre rarezas?
2. **Bono de evolución** (§2.4): ¿+30% te parece "medianamente más", o prefieres
   +20% / +40%?
3. **Clases** (§5): ¿apruebas las 8 propuestas y sus trueques? ¿Alguna te sobra
   o falta un arquetipo que imaginabas?
4. **Castigo de evolución sin evolucionar** (§6.2): confirmé "mitad de todo +
   sin pasivas/buffs". ¿Las resistencias CONSTRUIDAS se conservan (mi propuesta)
   o también caen?
5. **Modelo innato** (§4): ¿los rasgos ocultos SÍ superan los topes de 3/2, o
   prefieres que cuenten dentro del tope?
