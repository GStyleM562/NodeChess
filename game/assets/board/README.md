# Assets del TABLERO — Meshy → Godot

Igual que las figuras pero **SIN animaciones**: modelos **estáticos**, sin rig.
El giro/flotado (cristal del buff, etc.) lo hago yo por código.

## Formato de exportación en Meshy

- **GLB** con texturas incrustadas ("one file").
- **Low-poly / mobile**: ~2–5k triángulos por loseta/camino; hasta ~10k el portal.
- Centrado en el origen y **apoyado en el suelo** (base en y=0). La escala exacta
  no importa (la normalizo en código), pero usa una escala consistente entre piezas.

## Dónde va cada pieza (un GLB por carpeta, slug = minúsculas_con_guiones)

```
game/assets/board/
  node_tile/node_tile.glb                  <- loseta de nodo NORMAL (runa apagada)
  goal_player/goal_player.glb              <- META ALIADA (tu meta, lado de abajo)
  goal_enemy/goal_enemy.glb                <- META ENEMIGA (lado de arriba)
  entrance_player/entrance_player.glb      <- ENTRADA ALIADA (donde despliegas tú)
  entrance_enemy/entrance_enemy.glb        <- ENTRADA ENEMIGA
  path_stone/path_stone.glb                <- tramo de CAMINO recto (repetible)
  buff_crystal/buff_crystal.glb            <- cristal del buff node
  rock_small/rock_small.glb                <- decoración de borde
  rock_big/rock_big.glb
  tree_small/tree_small.glb
  island_platform/island_platform.glb      <- [opcional] la isla base como asset
  <slug>/source/                           <- opcional: referencias, .blend, renders
```

> Si un modelo es el MISMO para ambos lados y solo cambia el color, ponlo solo
> en la carpeta `_player` y yo tiño la versión enemiga por código.

Con `node_tile` + `path_stone` + `buff_crystal` ya puedo armar la primera
versión con assets; el resto suma. Cuando estén en su carpeta, avísame y los
cableo en Board3D (reemplazan los discos/pasarelas procedurales).
