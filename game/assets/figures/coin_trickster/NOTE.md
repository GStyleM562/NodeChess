# Coin Trickster — model pending

This figure currently uses a **placeholder** model (Nightblade's GLB), see
`Roster.gd` (`coin_trickster`, `"placeholder": true`). The figure shows its name
tag above it on the board so it's identifiable despite the shared model.

When the Meshy model is ready:
1. Drop the textured GLB here, e.g. `coin_trickster/coin_trickster.glb`.
2. In `Roster.gd`, change the `coin_trickster` entry's `"glb"` to
   `res://assets/figures/coin_trickster/coin_trickster.glb` and update `"clips"`
   to the new model's animation names. Remove `"placeholder": true`.

Gameplay data (Double Coin attack pool, coin_a/coin_b faces) is already final.
