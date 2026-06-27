# Venom Witch → Plague Matron (Rank Up stage 2) — model pending

Rank Up is implemented in data (`Roster.gd`, `venom_witch.ranks[0]` = Plague Matron).
For now the board keeps the base Witch model and shows a **"+1"** on the name tag
when it evolves (after scoring a KO). No separate model is loaded yet.

When the Meshy model is ready:
1. Drop the textured GLB here, e.g. `matron/matron.glb`.
2. Add `"glb"` + `"clips"` to the `ranks[0]` entry in `Roster.gd`, and have the board
   swap the model on Rank Up (hook in `Board3D._show_rankup`). Until then, "+N" is enough.
