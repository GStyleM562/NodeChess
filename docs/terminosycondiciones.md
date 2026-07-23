# NodeChess — Términos y Condiciones, Aviso de Privacidad y Cumplimiento (México)

> **Última actualización: 2026-07-23 · Versión legal: 1.0**
> Documento maestro: investigación legal, textos oficiales (Términos + Aviso de
> Privacidad), qué se cambió en la app para cumplir, checklist de cumplimiento y
> la especificación para el proyecto que administra el **sitio web de NodeChess**.

> ⚠️ **AVISO IMPORTANTE — no es asesoría legal.** Este documento fue redactado con
> investigación pública (fuentes al final) como base sólida y lista para usar,
> pero **NO sustituye la revisión de un abogado** en México. Antes de publicar en
> Google Play, haz que un profesional valide especialmente: (1) el nombre y
> domicilio legal del responsable, (2) el manejo de menores de edad y (3) la
> clasificación por edad. Los campos entre `[corchetes]` DEBES completarlos.

---

## 0. Identificación del responsable (COMPLETAR)

| Campo | Valor |
|---|---|
| Responsable (persona/empresa) | `[Rice Protocol Studio / nombre legal completo]` |
| Domicilio | `[domicilio fiscal en México]` |
| Correo de contacto y privacidad | **riceprotocolstudio@gmail.com** |
| Sitio web | `[https://nodechess.com — dominio del proyecto web]` |
| Nombre de la app | **NodeChess** |
| Plataforma | Android (Google Play) |

---

## 1. Resumen ejecutivo (qué es NodeChess y por qué esto importa)

NodeChess es un juego de mesa táctico **GRATUITO** para Android. Características
relevantes para lo legal:

- **NO tiene compras dentro de la app (sin IAP / in-app purchases).** No se cobra
  dinero real por nada. Las monedas 🪙 y diamantes 💎 son **moneda virtual del
  juego** que se gana jugando o viendo anuncios; **no se pueden comprar con dinero
  real ni canjear por dinero**.
- **Anuncios recompensados OPCIONALES y LIMITADOS por día** (AdMob): ver un
  anuncio da recursos/cajas. Son 100% voluntarios; **no son necesarios para
  jugar ni para ganar** (todo se puede conseguir jugando). Esto evita el
  "pay-to-win".
- **Cajas con contenido ALEATORIO** ("cajas por tipo"): dan piezas al azar. Se
  obtienen **sin dinero real** (ganando partidas, caja gratis diaria, anuncios, o
  con moneda virtual del juego). A mejor rareza, más contenido, pero siempre del
  tipo elegido.
- **Modo en línea 1v1**: envía al servidor relay el **nombre** que el jugador
  escribe y su **mazo** (para emparejar y sincronizar la partida).
- **Datos**: se guardan **localmente** en el dispositivo (progreso, nombre,
  ajustes). El servidor relay procesa nombre + mazo de forma efímera. AdMob
  recibe el **identificador de publicidad** del dispositivo.

**Conclusión de riesgo:** al **no** haber dinero real, NodeChess **no** es
"pay-to-win" ni entra en la Ley de Juegos y Sorteos por las cajas. Los focos de
cumplimiento reales son: **(A) protección de datos personales (LFPDPPP 2025)** por
el nombre + el ID de publicidad de los anuncios, **(B) políticas de Google Play /
AdMob** (política de privacidad, sección de Seguridad de los datos,
consentimiento de anuncios), y **(C) protección de menores**.

---

## 2. Marco legal aplicable en México (investigación)

### 2.1 Protección de datos personales — LFPDPPP (2025)
- Nueva **Ley Federal de Protección de Datos Personales en Posesión de los
  Particulares**, publicada en el DOF el **20 de marzo de 2025**, en vigor el
  **21 de marzo de 2025**. Sustituye a la ley de 2010 y **desaparece el INAI**;
  sus funciones pasan a la **Secretaría Anticorrupción y Buen Gobierno**.
- Obliga a poner a disposición un **Aviso de Privacidad** (integral y, cuando los
  datos se recaban por medios electrónicos, uno **simplificado**) **desde el
  momento en que se recaban** los datos.
- El **consentimiento** debe ser **libre, específico e informado**. Los datos
  sensibles y ciertas finalidades requieren consentimiento reforzado.
- Derechos **ARCO** (Acceso, Rectificación, Cancelación, Oposición) y revocación
  del consentimiento; hay que ofrecer un medio para ejercerlos.
- Principios: licitud, consentimiento, información, calidad, finalidad, lealtad,
  proporcionalidad y responsabilidad. Medidas de seguridad razonables.

**Aplicación a NodeChess:** el **nombre del jugador** (dato personal) y el
**identificador de publicidad** (dato personal según criterios de Google y
autoridades) hacen que **SÍ apliquen** estas obligaciones → se requiere Aviso de
Privacidad disponible en la app y en el sitio web, y consentimiento informado
para los anuncios.

### 2.2 Protección al consumidor — LFPC / PROFECO
- La **Ley Federal de Protección al Consumidor** exige información **veraz, clara
  y sin publicidad engañosa**. Aunque la app sea gratis, no debe inducir a error.
- Debe quedar **explícito** que los anuncios son opcionales y que **no** existen
  compras obligatorias ni ventajas de pago necesarias.

**Aplicación:** los Términos declaran claramente "gratis, sin compras, anuncios
opcionales, no pay-to-win". Cumple.

### 2.3 Cajas aleatorias ("loot boxes") — Ley Federal de Juegos y Sorteos
- En México **no hay regulación expresa** de loot boxes. Podrían asimilarse a
  **juegos de azar** de la **Ley Federal de Juegos y Sorteos** **solo si** reúnen:
  azar + **una contraprestación (dinero real)** + un premio de valor.
- NodeChess **rompe ese vínculo**: las cajas **no se compran con dinero real** (no
  hay IAP) y su contenido es de **uso dentro del juego** (no canjeable por
  dinero). Por lo tanto **no constituyen un juego de azar** bajo esa ley.

**Aplicación:** aun así, por transparencia y protección de menores, se **declara
la aleatoriedad** de las cajas en los Términos y se aclara que **no hay compra con
dinero real**. Cumple y queda blindado.

### 2.4 Menores de edad — Ley General de los Derechos de NNA
- Protege el desarrollo sano de niñas, niños y adolescentes. Combinado con las
  **Políticas para Familias de Google Play**, marca la pauta para menores.
- Decisión de diseño recomendada (aplicada): **la app NO está dirigida a menores
  de 13 años**; se fija una **edad mínima de 13 años** y, por prudencia, se
  configuran **anuncios NO personalizados por defecto** (menos datos, apto para
  audiencia amplia).

### 2.5 Google Play (políticas del desarrollador)
- **Política de privacidad** válida y accesible (URL en la ficha + dentro de la
  app) — **obligatoria** porque se muestran anuncios y se maneja el ID de
  publicidad.
- **Sección "Seguridad de los datos" (Data safety)** del Play Console: declarar
  qué datos se recopilan/comparten y para qué (ver §5.3).
- **Anuncios**: los recompensados deben poder **cerrarse tras 5 s**; declarar que
  hay anuncios y qué SDK de anuncios se usa; **sin anuncios personalizados para
  menores de 12**.
- **Clasificación por contenido (IARC)**: completar el cuestionario; declarar
  "contiene anuncios" e "interacción en línea" (chat/emparejamiento).

### 2.6 AdMob / consentimiento de anuncios
- AdMob **exige política de privacidad** (usa el **Advertising ID** = dato
  personal) y, para el EEE/RU/Suiza, **consentimiento** vía una **CMP
  certificada** (SDK **UMP** de Google). Debe poder **revocarse**.
- Para México se aplica el mismo estándar de **consentimiento informado** de la
  LFPDPPP: informar antes de mostrar anuncios y permitir gestionar/retirar el
  consentimiento.

---

## 3. Qué SE CAMBIÓ en la app para cumplir (bitácora)

> Implementado en esta tanda (2026-07-23). Detalle técnico en §6.

1. **Pantalla de aceptación legal en el primer inicio** (`Legal.show_gate`): antes
   de entrar al menú, se muestra un aviso con enlaces a **Términos** y **Aviso de
   Privacidad** y una casilla/boton **"Acepto"**. Sin aceptar no se continúa. Se
   guarda la **versión aceptada** (`Settings.legal_accepted`).
2. **Textos legales EMBEBIDOS en la app** (`Legal.gd`): Términos y Aviso de
   Privacidad completos, visibles en un modal desplazable **en cualquier momento**
   (requisito LFPDPPP: disponible al recabar datos).
3. **Sección "Legal y privacidad" en Configuración ⚙**: botones para leer los
   **Términos**, el **Aviso de Privacidad** y **"Anuncios y consentimiento"**
   (gestionar/retirar el consentimiento; hoy informa y, al activar anuncios
   reales, reabrirá el formulario UMP).
4. **Consentimiento de anuncios**: `Settings.ads_consent` (por defecto
   **anuncios NO personalizados**). El wrapper `Ads.gd` ya está listo para
   solicitar UMP cuando se instale el plugin real (ver `docs/Ads_Setup.md`).
5. **Declaración de aleatoriedad y "no dinero real"** integrada en los Términos.
6. **Edad mínima 13**: se documenta y se refleja en la clasificación y en los
   Términos.

## 4. Checklist de cumplimiento (estado)

| Requisito | Estado | Nota |
|---|---|---|
| Aviso de Privacidad integral | ✅ | Embebido en la app + para el sitio web (§5.2) |
| Aviso de Privacidad simplificado | ✅ | Mostrado en la pantalla de aceptación (§5.2.b) |
| Consentimiento libre/específico/informado | ✅ | Gate de aceptación + toggle de anuncios |
| Medio para derechos ARCO / revocar | ✅ | Correo de contacto + Configuración |
| Términos y Condiciones accesibles | ✅ | App (Config) + sitio web |
| Política de privacidad (Google Play/AdMob) | ⚠️ | Texto listo; **falta subir la URL** al Play Console y a la ficha (necesita el sitio web §7) |
| Sección Data safety (Play Console) | ⚠️ | Mapa de datos en §5.3; **lo llena Gojan** en el Console |
| Anuncios recompensados cerrables 5 s | ✅ | Lo maneja el SDK de AdMob (rewarded estándar) |
| Sin pay-to-win / compras obligatorias | ✅ | Sin IAP; todo se gana jugando |
| Cajas: aleatoriedad declarada, sin dinero real | ✅ | Declarado en Términos |
| Menores: edad mínima + anuncios no personalizados | ✅ | Edad 13; consentimiento por defecto no-personalizado |
| Clasificación IARC | ⚠️ | **Completar cuestionario** en el Play Console |
| CMP/UMP para EEE (si se distribuye allí) | ⚠️ | `Ads.gd` preparado; se activa con el plugin real |

**¿Cumplimos al 100%?** El **contenido y la app** quedan conformes. Los puntos ⚠️
son **acciones administrativas fuera del código** que solo Gojan puede hacer en el
Google Play Console (subir la URL de privacidad, llenar Data safety, contestar
IARC) y publicar el sitio web con los textos. Con eso hecho, **sí se cumple al
100%**. La validación final de un abogado se recomienda pero el marco está cubierto.

---

## 5. TEXTOS OFICIALES (para la app y el sitio web)

### 5.1 TÉRMINOS Y CONDICIONES DE USO — NodeChess

**Última actualización: 2026-07-23.**

1. **Aceptación.** Al descargar, instalar o usar NodeChess (la "App") aceptas
   estos Términos y el Aviso de Privacidad. Si no estás de acuerdo, no uses la App.
2. **Quién puede usarla / edad.** La App está dirigida a personas de **13 años o
   más**. Si eres menor de edad, debes contar con el consentimiento de tu
   madre, padre o tutor. No está dirigida a menores de 13 años.
3. **Licencia.** Se te otorga una licencia personal, limitada, no exclusiva e
   intransferible para usar la App con fines de entretenimiento. No puedes copiar,
   modificar, realizar ingeniería inversa, revender ni explotar la App salvo lo
   permitido por la ley.
4. **Gratuidad y ausencia de compras.** La App es **gratuita**. **No existen
   compras dentro de la aplicación (sin cargos con dinero real).** Las **monedas
   (🪙) y diamantes (💎)** son **moneda virtual** exclusiva del juego, **sin valor
   monetario real**, **no reembolsables** y **no canjeables por dinero**.
5. **Anuncios opcionales.** La App puede ofrecer **anuncios recompensados
   voluntarios y limitados por día** que otorgan recursos del juego. **Ver
   anuncios es 100% opcional y NO es necesario para jugar ni para avanzar**; todo
   el contenido puede obtenerse jugando. La App **no es "pay-to-win"**.
6. **Cajas y recompensas aleatorias.** Algunas recompensas ("cajas") entregan
   contenido **al azar**. Las cajas se obtienen **sin dinero real** (jugando, con
   la caja gratis, con anuncios o con moneda virtual del juego). A mejor rareza
   corresponde más contenido, siempre del tipo de caja elegido. **No constituyen
   una apuesta ni un juego de azar**, pues no media dinero real ni premios
   canjeables por dinero.
7. **Juego en línea.** El modo en línea empareja jugadores y sincroniza la partida
   a través de un servidor relay. Envías el **nombre** que elijas y tu **mazo**.
   Debes comportarte con respeto; nos reservamos suspender el acceso ante abusos,
   trampas o intentos de vulnerar el servicio.
8. **Contenido creado por el usuario.** El "Creador de personajes" te permite armar
   figuras. Eres responsable de los nombres/contenidos que introduzcas; no uses
   material ofensivo, ilegal o que infrinja derechos de terceros.
9. **Propiedad intelectual.** La App, su código, arte, marcas y contenidos son
   propiedad del responsable o de sus licenciantes y están protegidos por la ley.
10. **Disponibilidad.** La App y el servicio en línea se ofrecen "tal cual" y
    "según disponibilidad". Podemos actualizar, suspender o descontinuar funciones
    (incluido el servidor en línea) sin responsabilidad.
11. **Limitación de responsabilidad.** En la medida permitida por la ley, el
    responsable no será responsable por daños indirectos o incidentales derivados
    del uso de la App. Nada limita derechos irrenunciables del consumidor bajo la
    **LFPC**.
12. **Datos personales.** El tratamiento de datos se rige por el **Aviso de
    Privacidad** (§5.2), parte integral de estos Términos.
13. **Cambios.** Podemos actualizar estos Términos; publicaremos la nueva versión
    con su fecha. El uso continuado implica aceptación de los cambios.
14. **Ley aplicable.** Estos Términos se rigen por las leyes de los **Estados
    Unidos Mexicanos**. Para cualquier controversia sobre consumo, la **PROFECO**
    es competente conforme a la LFPC.
15. **Contacto.** riceprotocolstudio@gmail.com

### 5.2 AVISO DE PRIVACIDAD

#### 5.2.a — Aviso de Privacidad INTEGRAL

**Responsable.** `[Rice Protocol Studio / nombre y domicilio]`, contacto
**riceprotocolstudio@gmail.com** ("Responsable"), es responsable del tratamiento
de tus datos personales.

**Datos que tratamos.**
- **Nombre de jugador** (el que tú escribes; puede ser un alias).
- **Datos de juego y progreso** (nivel, mazos, personajes, monedas/diamantes,
  estadísticas) — **almacenados localmente en tu dispositivo**.
- **Identificador de publicidad del dispositivo (Advertising ID)** y datos
  técnicos asociados a los anuncios (los procesa **Google AdMob**).
- **Datos técnicos del juego en línea**: tu nombre y tu mazo, procesados de forma
  **efímera** por el servidor relay para emparejar y sincronizar la partida.
- **NO** recabamos: correo, teléfono, ubicación precisa, contactos, ni datos
  sensibles.

**Finalidades.**
- *Primarias (necesarias):* operar el juego, guardar tu progreso, permitir el
  juego en línea y el emparejamiento.
- *Secundarias (opcionales):* mostrar **anuncios** (con tu consentimiento) para
  ofrecer recompensas. Puedes negarte sin afectar el uso del juego.

**Fundamento y consentimiento.** El tratamiento se basa en tu **consentimiento**,
que otorgas al aceptar este Aviso. Para los anuncios, tu consentimiento es
**específico** y **puedes retirarlo** en cualquier momento en *Configuración →
Legal y privacidad → Anuncios y consentimiento*.

**Transferencias / encargados.** Usamos **Google AdMob** (Google) como proveedor
de publicidad; trata el Advertising ID conforme a sus propias políticas. El
**servidor relay** (alojado en Render) procesa el nombre/mazo solo para la
partida. No vendemos tus datos.

**Almacenamiento y seguridad.** El progreso se guarda **en tu dispositivo**. El
servidor no almacena la partida de forma permanente. Aplicamos medidas de
seguridad razonables.

**Derechos ARCO y revocación.** Puedes **Acceder, Rectificar, Cancelar u
Oponerte** al tratamiento, y **revocar** tu consentimiento, escribiendo a
**riceprotocolstudio@gmail.com**. Como el progreso es local, también puedes
borrar datos desde la app o desinstalándola.

**Menores.** La App no está dirigida a menores de 13 años. Si eres menor, usa la
App con supervisión de tu madre, padre o tutor.

**Cambios al Aviso.** Publicaremos cualquier cambio con su fecha en la app y en el
sitio web.

**Fecha de última actualización:** 2026-07-23.

#### 5.2.b — Aviso de Privacidad SIMPLIFICADO (pantalla de aceptación)

> NodeChess guarda tu progreso **en tu dispositivo** y usa tu **nombre de
> jugador** y tu **mazo** para el juego en línea. Si aceptas ver **anuncios**
> (opcionales), Google AdMob usa el **identificador de publicidad** de tu
> teléfono. No pedimos correo, teléfono ni ubicación. Puedes ejercer tus derechos
> o retirar el consentimiento de anuncios cuando quieras. Consulta el **Aviso de
> Privacidad completo** y los **Términos** desde esta pantalla o en Configuración.

### 5.3 Mapa de datos para "Seguridad de los datos" de Google Play

| Tipo de dato | ¿Se recopila? | ¿Se comparte? | Propósito | Opcional |
|---|---|---|---|---|
| Nombre de usuario/alias | Sí (local; en línea se envía al relay) | Con el rival en la partida | Funcionalidad del juego | No (necesario para jugar) |
| Progreso/estado del juego | Sí (local) | No | Funcionalidad | No |
| ID de publicidad (Advertising ID) | Sí (vía AdMob) | Con Google/anunciantes | Publicidad | **Sí** (anuncios opcionales) |
| Diagnóstico/registro online | Efímero (relay) | No | Funcionalidad/soporte | No |

- **Cifrado en tránsito:** Sí (el relay usa `wss://`).
- **El usuario puede pedir borrado:** Sí (progreso local; correo de contacto).
- **Sin datos sensibles, sin ubicación, sin contactos.**

---

## 6. Implementación en la app (referencia técnica)

- **`game/scripts/Legal.gd`** (autoload `Legal`): constante `LEGAL_VERSION`, textos
  `TERMS` y `PRIVACY`, `accepted()` (compara con `Settings.legal_accepted`),
  `show_document(host, which)` (modal desplazable) y `show_gate(host, on_accept)`
  (pantalla de aceptación del primer inicio con Aviso simplificado + enlaces +
  botón "Acepto").
- **`Settings`**: `legal_accepted` (versión aceptada, persistida) y `ads_consent`
  (`"non_personalized"` por defecto | `"personalized"` | `"denied"`).
- **Arranque**: tras el splash, si `not Legal.accepted()` se muestra `show_gate`
  antes del menú.
- **Configuración ⚙**: sección "Legal y privacidad" → Términos · Aviso de
  Privacidad · Anuncios y consentimiento.
- **Anuncios**: `Ads.gd` respeta `Settings.ads_consent`; con el plugin real de
  AdMob se solicitará el formulario **UMP** (ver `docs/Ads_Setup.md`).

---

## 7. Especificación para el PROYECTO DEL SITIO WEB de NodeChess

> El sitio web debe alojar los mismos textos (Google Play exige una **URL pública**
> de política de privacidad). Entrega esta especificación al proyecto que
> administra la página.

**Páginas a publicar (español, públicas, sin login):**
1. `/terminos` — **Términos y Condiciones** (texto de §5.1, íntegro).
2. `/privacidad` — **Aviso de Privacidad integral** (texto de §5.2.a, íntegro).
   Esta es la **URL que se pega en el Google Play Console** y en la ficha de la
   app (campo "Política de privacidad").
3. (Opcional) `/legal` — índice con enlaces a ambas.

**Requisitos:**
- Deben coincidir **palabra por palabra** con los textos embebidos en la app
  (misma **Versión legal** y **fecha**). Si cambia uno, cambia el otro y súbelo.
- Mostrar visiblemente la **fecha de última actualización** y la **versión (1.0)**.
- Incluir el **correo de contacto** (riceprotocolstudio@gmail.com) para derechos
  ARCO y revocación de consentimiento.
- Enlazar `/privacidad` y `/terminos` desde el **pie de página** del sitio.
- Cuando se actualice la ley o la app, versionar (1.1, 1.2…) y conservar el
  historial de fechas.

**Datos a completar en el sitio (los mismos `[corchetes]` del §0):** nombre/domicilio
legal del responsable y dominio final.

---

## 8. Acciones administrativas pendientes para Gojan (fuera del código)

1. Completar los campos `[corchetes]` (§0) con datos legales reales.
2. Publicar `/terminos` y `/privacidad` en el sitio web (§7) y copiar la **URL de
   privacidad** en el **Google Play Console** (ficha + sección de privacidad).
3. Llenar la sección **"Seguridad de los datos"** con el mapa de §5.3.
4. Completar el **cuestionario de clasificación IARC** (declarar anuncios +
   interacción en línea; edad objetivo 13+).
5. Al activar anuncios reales, verificar el **consentimiento UMP** (§2.6 y
   `docs/Ads_Setup.md`).
6. **Revisión por un abogado** en México (recomendada).

---

## 9. Fuentes consultadas

- Garrigues — *Nueva LFPDPPP (2025), aviso de privacidad, elimina el INAI*:
  https://www.garrigues.com/es_ES/noticia/mexico-nueva-ley-federal-proteccion-datos-personales-posesion-particulares-introduce
- BASHAM — *Nueva LFPDPPP publicada en el DOF*:
  https://basham.com.mx/en/nueva-ley-federal-de-proteccion-de-datos-personales-en-posesion-de-los-particulares-publicada-en-el-diario-oficial-de-la-federacion/
- IAPP — *Entendiendo la LFPDPPP en México*:
  https://iapp.org/news/a/entendiendo-la-ley-federal-de-protecci-n-de-datos-personales-en-posesi-n-de-los-particulares-en-mexico
- DOF / SCJN — *Texto de la ley (20-mar-2025)*:
  https://datos-personales.scjn.gob.mx/sites/default/files/normativa-materia/LGPDPPSO-DOF-20Mar2025.pdf
- Justia México — *Preguntas y respuestas sobre el Aviso de Privacidad*:
  https://mexico.justia.com/derecho-corporativo/aviso-de-privacidad/preguntas-y-respuestas-sobre-aviso-de-privacidad
- Lexology — *El futuro de los loot boxes en videojuegos para México*:
  https://www.lexology.com/library/detail.aspx?g=4e71e76a-9581-4154-b911-32789ea4c892
- Justia México — *Ley Federal de Juegos y Sorteos*:
  https://mexico.justia.com/federales/leyes/ley-federal-de-juegos-y-sorteos/
- Google Play — *Preview: Families Policies*:
  https://support.google.com/googleplay/android-developer/answer/17122218
- Google Play — *Seguridad de los datos (Data safety)*:
  https://support.google.com/googleplay/android-developer/answer/10787469
- Google AdMob — *Consent Management Platform (CMP/UMP)*:
  https://support.google.com/admob/answer/7666519
- Google AdMob — *Disclose to EEA users (GDPR)*:
  https://developers.google.com/admob/android/privacy/gdpr
