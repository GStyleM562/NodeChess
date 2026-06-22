# Assets Guide — Meshy → Godot

How to export from Meshy, where to drop the files, and how to hand them to me.

---

## 1. Where to put things (folder map)

Everything lives under `game/assets/figures/<slug>/`:

```
game/assets/figures/
  ironclad_knight/            (aka "Iron Bastion")
    ironclad_knight.glb       <- base RIGGED model (textures embedded)
    animations/               <- one GLB per animation clip
    source/                   <- optional: .blend, hi-res, reference renders
  stone_golem/
  shadowfang/
  sky_falcon/
  venom_spider/
    spider/   broodmother/    <- one folder per evolution stage
  ember_dragon/
    baby/   young/   adult/   <- one folder per stage (each: model + animations/)
  arcane_wisp/
  coin_trickster/
```

**Slug = lowercase_with_underscores.** Drop the model `.glb` directly in the figure folder
(or the stage folder for evolving figures), and animation clips inside its `animations/`.

> Note: Meshy named the knight **"Iron Bastion"**. Our GDD name is **"Ironclad Knight"** —
> keep whichever you prefer; tell me and I'll align the character sheet. Folder slug stays
> `ironclad_knight` either way.

---

## 2. Meshy export settings (the download dialog)

- **Format: `GLB`** ✅ (you already picked it). Best for Godot 4 — self-contained, textures embedded.
  - `fbx` also works but GLB is cleaner. Avoid obj/stl/usdz/3mf/dxf (those are for printing/other tools).
- **Origin: `Bottom`** ✅ (you already picked it). Correct — the figure sits *on* the node/ground.
- **Resize:** not critical — we set the final scale in Godot. Just keep **relative** sizes sensible
  (Adult Dragon & Golem bigger; Wisp & Spider smaller; Knight = baseline). You can leave Resize off.
- Keep textures **embedded** (GLB does this by default).

---

## 3. Animations — yes, request them now ✅

Use Meshy's **Animate / rig** on the model, then get the **Tier 1** clips (per Part 5B). For the
Knight, the target set is:

| Our clip name | What it is | Meshy/Mixamo equivalent |
| ------------- | ---------- | ----------------------- |
| `idle` | breathing, shield set | "Idle" |
| `move_walk` | walk between nodes | "Walking" |
| `attack` | shield bash / sword chop | "Sword attack" / "Melee" |
| `attack_heavy` | shoulder charge (Gold) | "Charge" / a second attack |
| `defend` | guard / block (Blue win) | "Blocking" |
| `hit` | flinch, survives | "Hit reaction" / "Damage" |
| `ko` | armor shatters, kneels | "Death" / "Knockout" |
| `deploy` | spawn-in *(optional)* | reuse idle / a "stand up" |

**Rules:**
- **Animate the SAME rigged model** for every clip — all clips must share one skeleton (Godot blends
  them via an AnimationLibrary).
- **Best export:** one GLB containing the rig **+ all clips**. If Meshy exports one clip per file,
  that's fine too — just name each file `ironclad_knight_<clip>.glb` (e.g. `ironclad_knight_idle.glb`).
- If Meshy's library is missing some (e.g. `attack_heavy`, `defend`, `deploy`): the Knight is
  **humanoid**, so **Mixamo** has all of these for free (upload the GLB, pick the animation, download).
  We can also retime/blend in Godot. Don't block on the missing ones — grab idle + walk + attack +
  hit + ko now; we fill the rest later.

**So for THIS message: yes, ask Meshy for the animations** (start with idle, walk, attack, hit, ko).

---

## 4. How you hand it to me

The files are in **this same project folder** on your PC, so I can read them directly. Just:

1. Drop the exported files into the right `game/assets/figures/<slug>/` folder.
2. Tell me **"listo, el Knight ya está"** (or which figure).
3. I'll **verify** it (parse the GLB to confirm the rig + list the animation clip names), set up the
   Godot import, and wire it onto the board when we build the project (Phase B).

Optional but recommended: commit + push so it's backed up on GitHub (I can do this for you).

> I can't *visually* render a GLB, but I **can** read its structure (meshes, skeleton, animation
> names) to confirm everything exported correctly before we build on it.

---

## 5. Quick checklist per figure

```
☐ Base model exported as GLB (Origin: Bottom, textures embedded)
☐ Rigged + animated (same skeleton for all clips)
☐ Tier 1 clips: idle, move_walk, attack, attack_heavy, defend, hit, ko (+ deploy optional)
☐ Files dropped in game/assets/figures/<slug>/ (+ /animations/)
☐ Told Claude which figure is ready
```

Evolving figures (Ember Dragon ×3, Venom Spider ×2): repeat per stage, plus a visible difference
between stages. The `rankup` transition we handle in Godot (swap model + a transform VFX).
