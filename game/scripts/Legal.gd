extends Node
## Autoload "Legal" — Términos y Aviso de Privacidad EMBEBIDOS en la app +
## pantalla de ACEPTACIÓN del primer inicio + visor desplazable. Cumplimiento
## México (LFPDPPP 2025) y políticas de Google Play / AdMob.
## Documento maestro y bitácora: docs/terminosycondiciones.md.

## Sube esta versión si cambian los textos legales (obliga a re-aceptar).
const LEGAL_VERSION := 1
const CONTACT := "riceprotocolstudio@gmail.com"
const UPDATED := "2026-07-23"

const TERMS := """TÉRMINOS Y CONDICIONES DE USO — NodeChess
Última actualización: 2026-07-23 · Versión 1.0

1. ACEPTACIÓN. Al usar NodeChess (la App) aceptas estos Términos y el Aviso de Privacidad. Si no estás de acuerdo, no uses la App.

2. EDAD. La App está dirigida a personas de 13 años o más. Si eres menor de edad, úsala con el consentimiento de tu madre, padre o tutor. No está dirigida a menores de 13 años.

3. LICENCIA. Se te otorga una licencia personal, limitada, no exclusiva e intransferible para usar la App con fines de entretenimiento. No la copies, modifiques, hagas ingeniería inversa ni la revendas salvo lo permitido por la ley.

4. GRATIS, SIN COMPRAS. La App es gratuita. NO existen compras dentro de la aplicación (no se cobra dinero real por nada). Las monedas (🪙) y diamantes (💎) son moneda virtual del juego, SIN valor monetario real, no reembolsables y no canjeables por dinero.

5. ANUNCIOS OPCIONALES. La App puede ofrecer anuncios recompensados voluntarios y limitados por día que otorgan recursos del juego. Ver anuncios es 100% opcional y NO es necesario para jugar ni para avanzar; todo el contenido puede obtenerse jugando. La App no es "pay-to-win".

6. CAJAS ALEATORIAS. Algunas recompensas ("cajas") entregan contenido AL AZAR. Se obtienen SIN dinero real (jugando, con la caja gratis, con anuncios o con moneda virtual del juego). No constituyen una apuesta ni un juego de azar, pues no media dinero real ni premios canjeables por dinero.

7. JUEGO EN LÍNEA. El modo en línea empareja jugadores y sincroniza la partida por medio de un servidor. Envías el nombre que elijas y tu mazo. Compórtate con respeto; podemos suspender el acceso ante abusos, trampas o intentos de vulnerar el servicio.

8. CONTENIDO QUE CREAS. El Creador de personajes te permite armar figuras. Eres responsable de los nombres/contenidos que introduzcas; no uses material ofensivo, ilegal o que infrinja derechos de terceros.

9. PROPIEDAD INTELECTUAL. La App, su código, arte, marcas y contenidos son propiedad del responsable o de sus licenciantes.

10. DISPONIBILIDAD. La App y el servicio en línea se ofrecen "tal cual" y "según disponibilidad". Podemos actualizar, suspender o descontinuar funciones (incluido el servidor en línea) sin responsabilidad.

11. RESPONSABILIDAD. En la medida permitida por la ley, no somos responsables por daños indirectos o incidentales derivados del uso de la App. Nada limita los derechos irrenunciables del consumidor bajo la Ley Federal de Protección al Consumidor.

12. DATOS PERSONALES. El tratamiento de datos se rige por el Aviso de Privacidad, parte integral de estos Términos.

13. CAMBIOS. Podemos actualizar estos Términos; publicaremos la nueva versión con su fecha. El uso continuado implica aceptación.

14. LEY APLICABLE. Se rigen por las leyes de los Estados Unidos Mexicanos. Para controversias de consumo es competente la PROFECO conforme a la LFPC.

15. CONTACTO. riceprotocolstudio@gmail.com"""

const PRIVACY := """AVISO DE PRIVACIDAD — NodeChess
Última actualización: 2026-07-23 · Versión 1.0

RESPONSABLE. Rice Protocol Studio, contacto riceprotocolstudio@gmail.com, es responsable del tratamiento de tus datos personales.

DATOS QUE TRATAMOS.
• Nombre de jugador (el que tú escribes; puede ser un alias).
• Datos de juego y progreso (nivel, mazos, personajes, monedas/diamantes, estadísticas), almacenados LOCALMENTE en tu dispositivo.
• Identificador de publicidad del dispositivo (Advertising ID) y datos técnicos de los anuncios (los procesa Google AdMob), solo si aceptas ver anuncios.
• Datos del juego en línea: tu nombre y tu mazo, procesados de forma efímera por el servidor para emparejar y sincronizar la partida.
NO recabamos correo, teléfono, ubicación precisa, contactos ni datos sensibles.

FINALIDADES.
• Primarias (necesarias): operar el juego, guardar tu progreso y permitir el juego en línea.
• Secundarias (opcionales): mostrar anuncios (con tu consentimiento) para darte recompensas. Puedes negarte sin afectar el uso del juego.

CONSENTIMIENTO. El tratamiento se basa en tu consentimiento, que otorgas al aceptar este Aviso. Para los anuncios, tu consentimiento es específico y puedes RETIRARLO cuando quieras en Configuración → Legal y privacidad → Anuncios y consentimiento.

ENCARGADOS / TRANSFERENCIAS. Usamos Google AdMob como proveedor de publicidad, que trata el Advertising ID conforme a sus políticas. El servidor procesa nombre/mazo solo para la partida. No vendemos tus datos.

ALMACENAMIENTO Y SEGURIDAD. El progreso se guarda en tu dispositivo. El servidor no almacena la partida de forma permanente. Aplicamos medidas de seguridad razonables (conexión cifrada wss://).

DERECHOS ARCO Y REVOCACIÓN. Puedes Acceder, Rectificar, Cancelar u Oponerte al tratamiento y REVOCAR tu consentimiento escribiendo a riceprotocolstudio@gmail.com. Como el progreso es local, también puedes borrarlo desde la app o desinstalándola.

MENORES. La App no está dirigida a menores de 13 años. Si eres menor, úsala con supervisión de tu madre, padre o tutor.

CAMBIOS. Publicaremos cualquier cambio con su fecha en la app y en el sitio web."""

const PRIVACY_SHORT := "NodeChess guarda tu progreso EN TU DISPOSITIVO y usa tu NOMBRE de jugador y tu MAZO para el juego en línea. Si aceptas ver ANUNCIOS (opcionales), Google AdMob usa el identificador de publicidad de tu teléfono. No pedimos correo, teléfono ni ubicación. Puedes ejercer tus derechos o retirar el consentimiento cuando quieras."

func accepted() -> bool:
	return int(Settings.legal_accepted) >= LEGAL_VERSION

func mark_accepted() -> void:
	Settings.set_legal_accepted(LEGAL_VERSION)

# --------------------------------------------------------------- visor
## Modal desplazable con un documento legal. `which`: "terms" | "privacy".
func show_document(host: Node, which: String) -> void:
	var title := "Términos y Condiciones" if which == "terms" else "Aviso de Privacidad"
	var body := TERMS if which == "terms" else PRIVACY
	var modal := _modal(host)
	var panel := _panel(modal, 460)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	vb.add_child(_title(title))
	var scr := ScrollContainer.new()
	scr.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scr.custom_minimum_size = Vector2(0, minf(host.get_viewport().get_visible_rect().size.y * 0.62, 560.0))
	vb.add_child(scr)
	var txt := Label.new()
	txt.text = body
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.custom_minimum_size = Vector2(minf(420.0, host.get_viewport().get_visible_rect().size.x - 60.0), 0)
	UITheme.label(txt, 13, UITheme.TEXT, false, 600)
	scr.add_child(txt)
	vb.add_child(_btn("Cerrar", UITheme.PRIMARY, func(): modal.queue_free()))

## Pantalla de ACEPTACIÓN del primer inicio. Llama `on_accept` al aceptar.
func show_gate(host: Node, on_accept: Callable) -> void:
	var modal := _modal(host, false)   # NO se cierra tocando el fondo
	var panel := _panel(modal, 440)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	vb.add_child(_title("Antes de jugar"))
	var short := Label.new()
	short.text = PRIVACY_SHORT
	short.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	short.custom_minimum_size = Vector2(minf(400.0, host.get_viewport().get_visible_rect().size.x - 60.0), 0)
	UITheme.label(short, 13, UITheme.TEXT, false, 600)
	vb.add_child(short)
	var links := HBoxContainer.new()
	links.add_theme_constant_override("separation", 8)
	vb.add_child(links)
	var t := _btn("Ver Términos", UITheme.SURFACE2, func(): show_document(host, "terms"))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var p := _btn("Aviso de Privacidad", UITheme.SURFACE2, func(): show_document(host, "privacy"))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	links.add_child(t)
	links.add_child(p)
	var note := Label.new()
	note.text = "Al continuar aceptas los Términos y el Aviso de Privacidad. Apto para 13+."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(note, 11, UITheme.MUTED, false, 600)
	vb.add_child(note)
	vb.add_child(_btn("Acepto y continúo", UITheme.SUCCESS, func():
		mark_accepted()
		modal.queue_free()
		if on_accept.is_valid():
			on_accept.call()))

# --------------------------------------------------------------- widgets
func _modal(host: Node, close_on_dim := true) -> CanvasLayer:
	var m := CanvasLayer.new()
	m.layer = 60
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	if close_on_dim:
		dim.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed:
				m.queue_free())
	m.add_child(dim)
	host.add_child(m)
	return m

func _panel(modal: CanvasLayer, w: float) -> PanelContainer:
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(cc)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(w, 500.0), 0)
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, UITheme.GOLD, 22, 2, 18))
	cc.add_child(panel)
	return panel

func _title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(l, 20, UITheme.GOLD, true, 800)
	return l

func _btn(text: String, accent: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	var fg: Color = Color.WHITE if accent != UITheme.SURFACE2 else UITheme.TEXT
	UITheme.button_font(b, 14, fg, true, 700)
	if accent == UITheme.SURFACE2:
		UITheme.style_surface(b, UITheme.SURFACE2, UITheme.BORDER, 12)
	else:
		UITheme.style_primary(b, accent, 12)
	b.pressed.connect(cb)
	return b
