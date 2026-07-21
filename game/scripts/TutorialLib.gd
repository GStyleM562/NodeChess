extends RefCounted
class_name TutorialLib
## FULL TUTORIAL por capítulos (modelo NODEHACK: pasos con "gate" — las acciones
## que no corresponden al paso se IGNORAN, el rival está guionado y el MOTOR real
## resuelve con resultados YA marcados). Cada capítulo da XP al superarse por
## primera vez. Completación persistida en Settings.tuts_done.
##
## Tipos de paso de una lección de tablero:
##   {do:"info",   text}                    → botón "Entendido"
##   {do:"deploy", text, node}              → desplegar EN ese nodo
##   {do:"move",   text, node}              → mover/saltar A ese nodo
##   {do:"attack", text, ia, ib}            → atacar (resultado forzado: índices)
##   {do:"mod",    text, mod}               → usar ESE modificador
##   {do:"end",    text}                    → terminar el turno
## La lección también puede completarse al GANAR (lección de portería).

## Guía de menú activa ("menu_craft"/"menu_chest") — la lee InventoryScreen.
static var active_guide := ""
## Bienvenida mostrada ya en esta sesión (no repetir cada vez que vuelves al menú).
static var welcomed := false

const CAT_BOARD := "Tablero"
const CAT_MENU := "Menú"
const CAT_META := "Progreso"   # cómo conseguir/mejorar personajes (no es de partida)

## Roster: 0 = Stone Golem · 1 = Ironclad Knight · 2 = Nightblade.
const CHAPTERS := [
	{"id": "primera", "cat": CAT_BOARD, "icon": "🎮", "xp": 60,
		"title": "Primera partida", "desc": "La partida guiada completa contra un muñeco de práctica."},
	{"id": "deploy", "cat": CAT_BOARD, "icon": "🎴", "xp": 40,
		"title": "Despliega y muévete", "desc": "Pon tu figura en el tablero y gasta su estamina ⚡."},
	{"id": "combat", "cat": CAT_BOARD, "icon": "⚔", "xp": 40,
		"title": "Aprende a combatir", "desc": "Los colores de ataque y tu primer K.O. (guiado)."},
	{"id": "modifier", "cat": CAT_BOARD, "icon": "✨", "xp": 40,
		"title": "Usa tus habilidades", "desc": "Energía ⚡ y modificadores: limpia un Miedo con Cleanse."},
	{"id": "jump", "cat": CAT_BOARD, "icon": "🦘", "xp": 40,
		"title": "Aprende a saltar", "desc": "Brinca POR ENCIMA de un rival que te bloquea."},
	{"id": "surround", "cat": CAT_BOARD, "icon": "💀", "xp": 50,
		"title": "Aprende a rodear", "desc": "El K.O. silencioso: cierra el cerco sin pelear."},
	{"id": "block", "cat": CAT_BOARD, "icon": "🚧", "xp": 40,
		"title": "Tapa una entrada", "desc": "Una entrada ocupada no sirve: asfixia el despliegue rival."},
	{"id": "buff", "cat": CAT_BOARD, "icon": "⚡", "xp": 50,
		"title": "Casillas de buff", "desc": "Aguanta 2 turnos en el nodo ⚡ y quédate POTENCIADO."},
	{"id": "goal", "cat": CAT_BOARD, "icon": "🏰", "xp": 60,
		"title": "Toma la portería", "desc": "La jugada ganadora: entra a la meta dorada rival."},
	{"id": "menu_craft", "cat": CAT_MENU, "icon": "🔨", "xp": 25,
		"title": "Craftea una pieza", "desc": "Convierte 10 fragmentos en una pieza completa."},
	{"id": "menu_chest", "cat": CAT_MENU, "icon": "📦", "xp": 25,
		"title": "Descifra un cofre", "desc": "Pon un cofre ganado a abrir desde tu inventario."},
	# --- PROGRESO (meta): cómo conseguir y mejorar personajes (no es de partida) ---
	{"id": "meta_resources", "cat": CAT_META, "icon": "💎", "xp": 30,
		"title": "Tus recursos", "desc": "Monedas, diamantes y fragmentos: cómo se ganan y para qué."},
	{"id": "meta_boxes", "cat": CAT_META, "icon": "🎁", "xp": 30,
		"title": "Cómo funcionan las cajas", "desc": "Cajas por tipo, rarezas y anuncios diarios."},
	{"id": "meta_inventory", "cat": CAT_META, "icon": "🎒", "xp": 30,
		"title": "Maneja tu inventario", "desc": "Tus piezas, fragmentos y cofres ganados."},
	{"id": "meta_create", "cat": CAT_META, "icon": "🛠", "xp": 50,
		"title": "Crea tu primer personaje", "desc": "Te regalamos las piezas y armas una figura básica paso a paso."},
]

## Páginas informativas de un capítulo META (título + cuerpo). Se muestran como
## un modal paginado en la pantalla de tutoriales. El capítulo "meta_create"
## además REGALA el kit de piezas y abre el Creador.
static func meta_pages(id: String) -> Array:
	match id:
		"meta_resources":
			return [
				{"t": "💰 Tus recursos", "b": "En NodeChess mejoras a tus personajes con PIEZAS. Para conseguirlas usas tres recursos:\n\n🪙 MONEDAS · 💎 DIAMANTES · 🧩 FRAGMENTOS"},
				{"t": "🪙 Monedas", "b": "Se ganan subiendo de NIVEL (jugando partidas) y viendo ANUNCIOS. Sirven para comprar en la 🛍 Tienda las piezas comunes y las Cajas Variadas."},
				{"t": "💎 Diamantes", "b": "Más valiosos: cada 5 niveles, en cofres y por anuncios. Compran las piezas y cajas de mejor rareza (figuras, pasivas, estados)."},
				{"t": "🧩 Fragmentos", "b": "Trozos de pieza. Junta 10 del mismo tipo y los CONVIERTES en 1 pieza completa (botón «Convertir» en el Inventario). La Caja Gratis da fragmentos."},
				{"t": "🎯 ¿Para qué?", "b": "Con las piezas construyes y evolucionas personajes más fuertes en el 🛠 Creador. Mejores piezas → mejores figuras → mejor mazo."},
			]
		"meta_boxes":
			return [
				{"t": "🎁 Las cajas", "b": "Las cajas te dan PIEZAS. Ahora vienen POR TIPO para que consigas justo lo que buscas, sin depender de la suerte."},
				{"t": "📦 Tipos", "b": "🧍 Figuras · 🎲 Ataques (colores, daño, estados) · ✨ Pasivas · 📦 Variada (de todo).\n\n¿Quieres una figura nueva? Abre una Caja de Figuras."},
				{"t": "⭐ Rareza", "b": "Cada caja tiene rareza: a MEJOR rareza, MÁS y mejores piezas — pero siempre del tipo de esa caja. Una Variada legendaria da de todo."},
				{"t": "📺 Anuncios y cofres", "b": "En 🎁 Recompensas: ve un ANUNCIO al día para 🪙/💎/caja gratis, compra Cajas por tipo, y DESCIFRA los cofres que ganas jugando."},
			]
		"meta_inventory":
			return [
				{"t": "🎒 Tu inventario", "b": "Aquí vive todo lo que tienes: tus PIEZAS completas, tus FRAGMENTOS y tus COFRES ganados."},
				{"t": "🧩 Convertir", "b": "Cuando tengas 10 fragmentos de una pieza, el inventario te deja CONVERTIRLOS en la pieza completa, lista para usar en el Creador."},
				{"t": "📦 Cofres ganados", "b": "Al ganar partidas consigues cofres (hasta 4). En el inventario los pones a DESCIFRAR (tardan un rato real); al abrirlos, sueltan piezas y a veces 💎."},
				{"t": "🛠 Úsalas", "b": "Todas las piezas que posees aparecen en el 🛠 Creador (botón 📦). Con ellas construyes o editas a tus personajes."},
			]
		"meta_create":
			return [
				{"t": "🛠 Crea tu personaje", "b": "Te vamos a REGALAR las piezas necesarias para armar una figura básica. Cada vez que repitas este tutorial, te las damos de nuevo."},
				{"t": "1 · Identidad", "b": "En el Creador eliges: NOMBRE, CLASE (Balanced para empezar) y RAREZA (Común). Arriba verás los «Puntos de Construcción»: no te pases del presupuesto."},
				{"t": "2 · Combate", "b": "Elige la ESTAMINA (2), el TIPO de ataque (Ruleta) y el MODELO 3D. Luego arma la RULETA de ataque con colores (Blanco = daño) y sus probabilidades."},
				{"t": "3 · Guarda", "b": "Cuando el medidor esté en verde («✓ Válido»), pulsa GUARDAR. ¡Tu figura queda en tu Colección y lista para tu mazo!\n\nToca «Ir al Creador» para empezar."},
			]
	return []

## Lecciones de TABLERO guionadas (mapa Rieles: metas 0/19, entradas 1-2/17-18,
## buff 8, candados 20-21 abren en turn_no 6, riel L: 1-4-6-20-12-14-17).
static func lesson(id: String) -> Dictionary:
	match id:
		"deploy":
			return {"map": 0,
				"player": [{"ri": 1}],                              # ironclad en banca
				"enemy": [{"ri": 0, "node": 16}],                   # golem lejos (estatua)
				"steps": [
					{"do": "info", "text": "🎓 ¡Bienvenido, estratega! Tu misión en NodeChess: llegar a la META dorada del rival. Lo primero: poner una figura en el tablero."},
					{"do": "deploy", "node": 1, "text": "ARRASTRA tu carta de la banca (abajo) a la entrada marcada 👉."},
					{"do": "info", "text": "¡Desplegada! Desplegar cuesta 1 de estamina ⚡ — la estamina son los pasos de tu figura en el turno."},
					{"do": "move", "node": 4, "text": "Ahora MUÉVETE: toca tu figura y luego el nodo marcado 👉."},
					{"do": "info", "text": "¡Eso es! Cada figura tiene su propia estamina: las rápidas cruzan el tablero, las lentas aguantan. ¡Capítulo superado!"},
				]}
		"combat":
			return {"map": 0,
				"player": [{"ri": 1, "node": 4}],
				"enemy": [{"ri": 0, "node": 6}],
				"steps": [
					{"do": "info", "text": "Los ataques tienen COLOR: ⚪ Blanco y 🟡 Oro hacen daño · 🟣 Púrpura aplica efectos · 🔵 Azul bloquea · 🔴 Rojo falla."},
					{"do": "attack", "ia": 1, "ib": 4, "text": "¡ATACA! Toca al rival marcado en ROJO. (Este combate está guiado — fíjate en los colores que salen.)"},
					{"do": "info", "text": "Tu ⚪ Blanco 80 contra su 🔴 Fallo: ¡K.O. directo! El perdedor va a la banca de K.O. unas rondas. Sin puntos de vida: cada duelo es una moneda cargada."},
				]}
		"modifier":
			return {"map": 0, "energy": 4, "mods": ["cleanse"],
				"player": [{"ri": 1, "node": 4}],
				"enemy": [{"ri": 0, "node": 16}],
				"statuses": [{"team": "player", "i": 0, "id": "fear"}],
				"steps": [
					{"do": "info", "text": "Tu figura tiene MIEDO 😱 y no puede atacar. Para esto existen los MODIFICADORES: cartas de apoyo que se pagan con energía ⚡ (ganas 1 por turno, máx 10)."},
					{"do": "mod", "mod": "cleanse", "text": "Usa CLEANSE — el botón naranja de abajo 👉 — para limpiar los estados malos de tus figuras."},
					{"do": "info", "text": "¡Limpio! Llevas 3 modificadores por partida (los eliges al armar tu mazo). Gasta la energía con cabeza: es tu recurso más escaso."},
				]}
		"jump":
			return {"map": 0, "turn_no": 6,
				"player": [{"ri": 2, "node": 4}],                   # nightblade (ST 3)
				"enemy": [{"ri": 0, "node": 6}],
				"steps": [
					{"do": "info", "text": "¿Un rival te BLOQUEA el camino? ¡SÁLTALO! El salto gasta tu estamina restante y aterriza en una casilla libre pegada al rival."},
					{"do": "move", "node": 20, "text": "Toca el nodo DORADO al otro lado del rival 👉 para saltar por encima."},
					{"do": "info", "text": "¡Salto perfecto! Ojo: si todas las casillas tras el rival están ocupadas, no hay salto. Los muros de figuras funcionan… hasta que no."},
				]}
		"surround":
			return {"map": 0, "turn_no": 6,
				"player": [{"ri": 1, "node": 4}, {"ri": 2, "node": 12}],
				"enemy": [{"ri": 0, "node": 6}],
				"steps": [
					{"do": "info", "text": "El K.O. por RODEO: si TODOS los vecinos de una figura son enemigos, cae SIN pelear. Este golem solo tiene 2 salidas… y una ya es tuya."},
					{"do": "move", "node": 20, "text": "Cierra el cerco: mueve tu segunda figura al nodo marcado 👉."},
					{"do": "end", "text": "Termina tu turno (botón verde) y mira cómo se cierra la trampa."},
					{"do": "info", "text": "💀 ¡K.O. por rodeo! Sin tirar un solo dado. Arma silenciosa… que también puede usarse CONTRA ti. Cuida tus salidas."},
				]}
		"block":
			return {"map": 0,
				"player": [{"ri": 1, "node": 14}],
				"enemy": [{"ri": 0}],                               # golem en banca (sin desplegar)
				"steps": [
					{"do": "info", "text": "Las ENTRADAS rivales (arriba) son sus puntos de despliegue. Una entrada OCUPADA no le sirve a NADIE."},
					{"do": "move", "node": 17, "text": "Párate SOBRE la entrada rival marcada 👉."},
					{"do": "info", "text": "¡Entrada tapada! Si tapas TODAS sus entradas y no tiene figuras en el tablero… GANAS por asfixia. Una victoria de estratega."},
				]}
		"buff":
			return {"map": 0,
				"player": [{"ri": 0, "node": 3}],                   # golem (tanque lento)
				"enemy": [{"ri": 0, "node": 16}],
				"steps": [
					{"do": "info", "text": "Los nodos ⚡ POTENCIAN a quien aguante: párate encima y sobrevive 2 finales de turno TUYOS (si te mueves, se reinicia)."},
					{"do": "move", "node": 8, "text": "Ve al nodo ⚡ marcado 👉."},
					{"do": "end", "text": "Termina tu turno (carga 1/2)."},
					{"do": "end", "text": "Aguanta: termina OTRA vez sin moverte (carga 2/2)."},
					{"do": "info", "text": "🔥 ¡POTENCIADA para siempre! +20 daño / +1★ hasta caer. El nodo queda en enfriamiento — el buff se GANA, no se regala."},
				]}
		"goal":
			return {"map": 0,
				"player": [{"ri": 2, "node": 16}],
				"enemy": [{"ri": 0, "node": 12}],
				"steps": [
					{"do": "info", "text": "La jugada que gana partidas: ENTRAR a la META dorada del rival. No hace falta aniquilar a nadie — esto es ajedrez, no demolición."},
					{"do": "move", "node": 19, "text": "¡Toma la portería marcada 👉!"},
				]}
	return {}

# ---------------------------------------------------------------- progreso
static func chapter(id: String) -> Dictionary:
	for c in CHAPTERS:
		if String(c["id"]) == id:
			return c
	return {}

static func _settings() -> Node:
	var ml := Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null("Settings") if ml is SceneTree else null

static func is_done(id: String) -> bool:
	var s := _settings()
	if s == null:
		return false
	if id == "primera" and bool(s.get("tutorial_done")):
		return true
	return id in (s.get("tuts_done") as Array)

static func pending_in(cat: String) -> int:
	var n := 0
	for c in CHAPTERS:
		if String(c["cat"]) == cat and not is_done(String(c["id"])):
			n += 1
	return n

static func pending_total() -> int:
	return pending_in(CAT_BOARD) + pending_in(CAT_META) + pending_in(CAT_MENU)

static func done_count() -> int:
	return CHAPTERS.size() - pending_total()

static func xp_pending() -> int:
	var n := 0
	for c in CHAPTERS:
		if not is_done(String(c["id"])):
			n += int(c["xp"])
	return n

## Marca el capítulo superado y otorga su XP (SOLO la primera vez).
## -> {"first": bool, "xp": int, "leveled": int, "level": int}
static func complete(id: String) -> Dictionary:
	var s := _settings()
	var first := not is_done(id)
	if s != null and first:
		s.call("mark_tut", id)
	var ch := chapter(id)
	var xp := int(ch.get("xp", 0))
	if first and xp > 0:
		var ml := Engine.get_main_loop()
		var inv := (ml as SceneTree).root.get_node_or_null("Inventory") if ml is SceneTree else null
		if inv != null:
			var r: Dictionary = inv.grant_xp(xp, "tutorial:" + id)
			return {"first": true, "xp": xp, "leveled": int(r.get("leveled", 0)), "level": int(r.get("level", 1))}
	return {"first": first, "xp": xp if first else 0, "leveled": 0, "level": 1}
