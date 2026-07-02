extends RefCounted
class_name CustomFigures
## Persistence + runtime loading for player-authored figures (Character Creator).
## Custom figures are stored as JSON in user:// and merged into Roster.FIGURES at
## startup (see GameBoot autoload), so they appear in the Dex / Deck Builder and are
## playable. Each saved figure follows the same schema as Roster's built-ins; a real
## 3D model is wired in later (until then it borrows an existing figure's GLB).

const PATH := "user://custom_figures.json"
const DEFAULT_MODEL_REF := "ironclad_knight"   # placeholder model until a GLB is added

# Share/backup codes: gzip(JSON) -> base64 with a prefix. NCFIG = one figure,
# NCPACK = every saved figure (full backup). Survives reinstalls: the player
# copies the code (WhatsApp, notes, etc.) and imports it on any device/version.
const CODE_PREFIX := "NCFIG1."
const PACK_PREFIX := "NCPACK1."

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

# ---------------------------------------------------------------- share codes
## Compact shareable code for ONE figure.
static func export_code(fig: Dictionary) -> String:
	var bytes := JSON.stringify(_strip_runtime(fig)).to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
	return CODE_PREFIX + Marshalls.raw_to_base64(bytes)

## One code with EVERY saved figure (full backup before updating/reinstalling).
static func export_all_code() -> String:
	var arr: Array = []
	for f in load_all():
		arr.append(_strip_runtime(f))
	var bytes := JSON.stringify(arr).to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
	return PACK_PREFIX + Marshalls.raw_to_base64(bytes)

## Decode a code WITHOUT saving (pure). -> {ok, figs: Array, error: String}
static func decode_code(code: String) -> Dictionary:
	# tolerate whitespace/newlines picked up while copying through chat apps
	var c := code.strip_edges().replace("\n", "").replace("\r", "").replace(" ", "").replace("\t", "")
	var prefix := ""
	if c.begins_with(PACK_PREFIX):
		prefix = PACK_PREFIX
	elif c.begins_with(CODE_PREFIX):
		prefix = CODE_PREFIX
	else:
		return {"ok": false, "figs": [], "error": "No es un código de NodeChess (debe empezar con NCFIG1. o NCPACK1.)"}
	var bytes := Marshalls.base64_to_raw(c.substr(prefix.length()))
	if bytes.is_empty():
		return {"ok": false, "figs": [], "error": "Código incompleto o dañado."}
	var raw := bytes.decompress_dynamic(4 << 20, FileAccess.COMPRESSION_GZIP)
	if raw.is_empty():
		return {"ok": false, "figs": [], "error": "No se pudo descomprimir el código."}
	var data = JSON.parse_string(raw.get_string_from_utf8())
	var figs: Array = []
	for f in (data if data is Array else [data]):
		if f is Dictionary and String(f.get("id", "")) != "":
			figs.append(f)
	if figs.is_empty():
		return {"ok": false, "figs": [], "error": "El código no contiene personajes."}
	return {"ok": true, "figs": figs, "error": ""}

## Decode + validate + SAVE. Same custom id = overwrite (restoring twice does not
## duplicate); an id clashing with a built-in gets a numeric suffix.
## -> {ok, names: Array, skipped: int, error: String}
static func import_code(code: String) -> Dictionary:
	var d := decode_code(code)
	if not bool(d["ok"]):
		return {"ok": false, "names": [], "skipped": 0, "error": String(d["error"])}
	var names: Array = []
	var skipped := 0
	for f in d["figs"]:
		var fig: Dictionary = f
		if String(FigureValidator.validate(fig).get("state", "INVALID")) == "INVALID":
			skipped += 1
			continue
		var id := String(fig["id"])
		var n := 2
		while not _builtin(id).is_empty():   # never shadow a built-in figure
			id = "%s_%d" % [String(fig["id"]), n]
			n += 1
		fig["id"] = id
		_refresh_stage_models(fig)
		add(fig)
		apply_live(fig)
		names.append(String(fig.get("name", id)))
	if names.is_empty():
		return {"ok": false, "names": [], "skipped": skipped, "error": "Ningún personaje del código pasó la validación."}
	return {"ok": true, "names": names, "skipped": skipped, "error": ""}

## Remove fields that are rebuilt on import (borrowed placeholder model, runtime
## flags) so codes stay short and survive asset renames between versions.
static func _strip_runtime(fig: Dictionary) -> Dictionary:
	var f := fig.duplicate(true)
	var was_placeholder := bool(f.get("placeholder", false))
	for k in ["custom", "placeholder", "complete"]:
		f.erase(k)
	if was_placeholder or String(f.get("model_ref", "")) != "":
		f.erase("glb")
		f.erase("clips")
	return f

## Re-point each evolution stage's model at the CURRENT build's figure (stages
## embed glb/clips copied at creation time; the target may have moved since).
static func _refresh_stage_models(fig: Dictionary) -> void:
	for st in fig.get("ranks", []):
		var src := _builtin(String(st.get("evolves_id", "")))
		if not src.is_empty():
			st["glb"] = src.get("glb", "")
			st["clips"] = (src.get("clips", {}) as Dictionary).duplicate(true)
			st["size"] = src.get("size", 1.0)

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
