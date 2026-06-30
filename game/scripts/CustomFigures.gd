extends RefCounted
class_name CustomFigures
## Persistence + runtime loading for player-authored figures (Character Creator).
## Custom figures are stored as JSON in user:// and merged into Roster.FIGURES at
## startup (see GameBoot autoload), so they appear in the Dex / Deck Builder and are
## playable. Each saved figure follows the same schema as Roster's built-ins; a real
## 3D model is wired in later (until then it borrows an existing figure's GLB).

const PATH := "user://custom_figures.json"
const DEFAULT_MODEL_REF := "ironclad_knight"   # placeholder model until a GLB is added

## All saved custom figures (raw dicts, in save order). Missing file -> [].
static func load_all() -> Array:
	if not FileAccess.file_exists(PATH):
		return []
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return []
	var txt := f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	return data if data is Array else []

static func save_all(figs: Array) -> bool:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("CustomFigures: cannot write " + PATH)
		return false
	f.store_string(JSON.stringify(figs, "\t"))
	f.close()
	return true

## Append (or replace by id) a figure and persist. Returns the full saved list.
static func add(fig: Dictionary) -> Array:
	var figs := load_all()
	var id := String(fig.get("id", ""))
	var replaced := false
	for i in figs.size():
		if String(figs[i].get("id", "")) == id:
			figs[i] = fig
			replaced = true
			break
	if not replaced:
		figs.append(fig)
	save_all(figs)
	return figs

static func remove(id: String) -> Array:
	var figs := load_all()
	var out := []
	for f in figs:
		if String(f.get("id", "")) != id:
			out.append(f)
	save_all(out)
	return out

static func exists(id: String) -> bool:
	for f in load_all():
		if String(f.get("id", "")) == id:
			return true
	return false

## Merge saved custom figures into Roster.FIGURES (skips ids already present, so it
## is safe to call more than once). Fills in a placeholder model where none is set.
static func merge_into_roster() -> void:
	var present := {}
	for f in Roster.FIGURES:
		present[String(f.get("id", ""))] = true
	for fig in load_all():
		var id := String(fig.get("id", ""))
		if id == "" or present.has(id):
			continue
		_ensure_model(fig)
		fig["custom"] = true
		Roster.FIGURES.append(fig)
		present[id] = true

## Apply a just-saved figure to the in-memory Roster immediately (so a NEW figure
## appears and an EDITED one updates without restarting). merge_into_roster() skips
## ids already present, so editing needs this explicit replace.
static func apply_live(fig: Dictionary) -> void:
	var f := fig.duplicate(true)
	_ensure_model(f)
	f["custom"] = true
	for i in Roster.FIGURES.size():
		if String(Roster.FIGURES[i].get("id", "")) == String(f.get("id", "")):
			Roster.FIGURES[i] = f
			return
	Roster.FIGURES.append(f)

## Find a built-in figure by id (used to borrow a placeholder model).
static func _builtin(id: String) -> Dictionary:
	for f in Roster.FIGURES:
		if String(f.get("id", "")) == id and not bool(f.get("custom", false)):
			return f
	return {}

## Give the figure a renderable model. If it has no GLB, borrow one from an existing
## figure (its "model_ref", or the default) and mark it as a placeholder.
static func _ensure_model(fig: Dictionary) -> void:
	if String(fig.get("glb", "")) != "":
		fig["complete"] = bool(fig.get("complete", true))
		return
	var ref := _builtin(String(fig.get("model_ref", DEFAULT_MODEL_REF)))
	if ref.is_empty():
		ref = _builtin(DEFAULT_MODEL_REF)
	fig["glb"] = ref.get("glb", "")
	fig["clips"] = ref.get("clips", {}).duplicate(true)
	fig["size"] = fig.get("size", ref.get("size", 1.0))
	fig["placeholder"] = true
	fig["complete"] = true
