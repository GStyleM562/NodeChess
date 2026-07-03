# Audio — dónde van los .mp3

Suelta **UN archivo** (.mp3, .ogg o .wav) en cada carpeta. El juego toma el
PRIMER archivo de la carpeta; si está vacía simplemente no suena nada (no crashea).
No hace falta renombrar el archivo — la carpeta decide cuándo suena.

## Música (`audio/music/`) — con loop y crossfade automáticos

| Carpeta | Cuándo suena |
|---|---|
| `menu/` | Menú principal y pantallas fuera de partida |
| `battle/` | Partida normal |
| `advantage/` | POSITIVA: TU figura está a ≤3 nodos de la meta rival |
| `danger/` | PELIGRO: una figura RIVAL está a ≤3 nodos de tu meta |

La situación se recalcula tras CADA acción: si el peligro/ventaja desaparece
(se alejan o la figura cae) vuelve sola la música de partida; si reaparece,
vuelve a sonar la que toque. Si hay peligro y ventaja a la vez, manda el peligro.

## SFX (`audio/sfx/`) — un disparo por evento

| Carpeta | Evento |
|---|---|
| `ui_click/` | Cualquier botón de la interfaz |
| `end_turn/` | Terminar turno |
| `deploy/` | Desplegar una figura |
| `attack_hit/` | Golpe ganador Blanco/Oro |
| `attack_block/` | Bloqueo Azul |
| `attack_effect/` | Efecto Púrpura aplicado |
| `attack_miss/` | Empate / fallo |
| `ko/` | Figura noqueada |
| `rankup/` | Evolución en partida |
| `victory/` | Ganaste la partida |
| `defeat/` | Perdiste la partida |
