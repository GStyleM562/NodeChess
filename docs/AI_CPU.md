# IA de la CPU — diseño y comportamientos

> Cómo decide la CPU (`GameState.bot_action`, ejecutada acción por acción).
> Objetivo: que las peleas sean DIFÍCILES sin hacer trampa (GDD §3: el bot ve
> lo mismo que el jugador; la dificultad es profundidad de decisión, no stats).

## Dificultades

| Nivel | Comportamiento |
|---|---|
| 0 | Fácil (legacy): despliega hasta 3 y ataca lo primero adyacente. |
| 1 | Lista completa de prioridades (abajo). |
| 2 | **Actual.** Además gasta modificadores (Power Surge) en ataques ≥60% y afina el cerco. |

## Lista de prioridades (se ejecuta la PRIMERA que aplique)

1. **GANAR YA** — si alguna figura alcanza la meta rival este turno, entra (victoria).
2. **PORTERO** — *"intenta siempre tener un personaje en tu portería"*: si la
   meta propia está vacía, sienta ahí a la figura con el camino más barato; si
   nadie llega, **siembra un guardia desde la banca** por la entrada más cercana
   a la propia meta. Un nodo ocupado no puede pisarse ⇒ el rival no puede ganar
   por la portería. El portero **no abandona** su puesto (excluido de avance,
   cerco y buff; sí ataca a quien se le pare al lado).
3. **CERCO** — *"rodear a los enemigos que les falte 1 nodo"*: si a un rival le
   falta exactamente un vecino libre para quedar rodeado, la CPU ocupa ese
   hueco (KO por rodeo al resolverse el turno). Nunca se mete a un nodo donde
   ELLA quedaría rodeada.
4. **ATAQUE ÚTIL** — *"ataca cuando sea útil y para conseguir espacio"*: puntúa
   cada ataque posible con probabilidades EXACTAS sobre los pools:
   `score = 0.7·P(ganar) + 0.6·P(KO) + 0.5·amenaza + 0.35·espacio`
   - `amenaza`: qué tan cerca está ese rival de MI meta (defensa).
   - `espacio`: bono si el rival está DELANTE de mí rumbo a su meta (quitarlo
     abre el camino). Solo ataca con P(ganar) ≥ 42% o si la amenaza es crítica.
5. **DESPLEGAR TODO** — *"no dejes personajes en la banca"*: mientras haya banca
   y entradas libres, despliega (la figura más fuerte primero) por la entrada
   más cercana a la meta rival. Sin tope de figuras en tablero.
6. **BUFF NODE** — toma el nodo de buff si está libre y no es una trampa.
7. **AVANZAR ESQUIVANDO** — *"ir a la portería enemiga evitando enemigos"*:
   elige el movimiento con mejor `progreso − 0.8·riesgo`, donde `riesgo` = nº de
   rivales adyacentes al destino. Prefiere rutas limpias; nunca termina en un
   nodo donde quedaría rodeada.

## Reglas duras que la CPU respeta (sin trampas)

- 1 acción por turno (desplegar O mover(+atacar) O atacar).
- Solo despliega desde la banca a entradas libres.
- Saltos con las mismas reglas del jugador (coste 2, un rival, aterrizaje libre).
- No ve el mazo del jugador ni sus tiradas: usa probabilidades de los pools
  visibles (lo mismo que un humano experto podría calcular).

## Para hacerla AÚN más difícil (siguientes pasos)

- **Previsión a 2 turnos**: simular la mejor respuesta del jugador al elegir avance.
- **Personalidades** (GDD): Agresiva / Defensiva / Goal Rusher / Rank-Up Lover —
  reponderando los pesos del score (`espacio`, `amenaza`, prioridad 5 vs 7).
- **Uso completo de modificadores**: Adrenaline en fallos, escudos defensivos.
- **Cercos a 2 huecos**: coordinar dos figuras para cerrar en dos turnos.
- **Presión de entradas**: bloquear las entradas rivales cuando va ganando.
