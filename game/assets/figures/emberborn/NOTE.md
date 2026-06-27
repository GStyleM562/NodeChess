# Emberborn (3 Rank Up stages) — models pending

Placeholder: currently reuses Ironclad's GLB (`Roster.gd`, `emberborn`,
`"placeholder": true`). The 3 stages are implemented in DATA:
- Stage 1 (base): **Ember Squire** — `squire/`
- Stage 2 (rank +1): **Flame Champion** — `champion/`
- Stage 3 (rank +2): **Infernal Warlord** — `warlord/` (unlocks Burning Aura)

Rank Up happens when Emberborn scores a KO; the name tag shows **+1 / +2** and the
attack pool/type/stamina change to the stage's data.

When Meshy models are ready: drop each stage's GLB into its subfolder
(`squire/squire.glb`, `champion/champion.glb`, `warlord/warlord.glb`), then add
`"glb"` + `"clips"` per stage in `Roster.gd` and swap the model on Rank Up.
