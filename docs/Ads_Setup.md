# Anuncios (AdMob) — cómo activarlos para generar ingresos

NodeChess es **Godot**; el proyecto de referencia (`claudegnosiapp`) es **Flutter**
(`google_mobile_ads`). El código no se copia igual, pero la CUENTA y el patrón sí.
Ya dejé la integración lista en el juego con un wrapper que **funciona sin
anuncios reales** (los simula) y que usa anuncios REALES en cuanto instales el
plugin. Aquí está lo que falta hacer TÚ para que generen dinero.

## Lo que YA está hecho (en el juego)
- `game/scripts/Ads.gd` (autoload `Ads`): rewarded ads con fallback simulado.
  Ya trae tu **App ID**: `ca-app-pub-2708000886889061~5037795173` (tu cuenta,
  el mismo de Gnosia) y el rewarded de **prueba** de Google.
- El popup 🎁 Recompensas del Home ya da recompensa **solo si se completa** el
  anuncio (`Ads.show_rewarded()`), con tope diario por tipo (🪙/💎/caja).

## Lo que falta para anuncios REALES (una vez)

### 1) Crear las unidades de anuncio en AdMob
En [apps.admob.com](https://apps.admob.com) → tu app de NodeChess (o créala) →
**Bloques de anuncios** → nuevo **Recompensado (Rewarded)**. Copia su ID
(`ca-app-pub-2708000886889061/XXXXXXXXXX`).
> Puedes usar UNA sola unidad rewarded para los 3 botones (monedas/diamantes/
> caja): la recompensa la decide el juego, no AdMob. Con una basta.

### 2) Pegar el ID real en el juego
En `game/scripts/Ads.gd`, la constante `UNIT_RELEASE`:
```gdscript
const UNIT_RELEASE := "ca-app-pub-2708000886889061/XXXXXXXXXX"
```
En debug se usa el de prueba; en el `.aab` release se usará el tuyo real.

### 3) Instalar el plugin de AdMob para Godot 4 (Android)
El más usado es **Poing Studios – Godot AdMob** (Godot 4, gratis):
- Descárgalo de su GitHub/Asset Library e instálalo en `game/addons/` +
  `game/android/plugins/` (el `.aar` + `.gdap`).
- En **Proyecto → Exportar → Android**, marca el plugin AdMob como **activado**.
- Añade tu **App ID** al manifiesto (el plugin suele tener un campo para ello;
  si no, se agrega como `<meta-data
  android:name="com.google.android.gms.ads.APPLICATION_ID"
  android:value="ca-app-pub-2708000886889061~5037795173"/>`).

El wrapper `Ads.gd` ya detecta el singleton del plugin (`AdMob`/`AdmobPlugin`/…)
y, si existe, cambia solo a anuncios reales. Puede que haya que ajustar los
nombres de método/señal (`load_rewarded`/`show_rewarded`/`rewarded_user_earned_reward`)
a los EXACTOS del plugin que instales — están marcados en `Ads.gd`.

### 4) Consentimiento (UMP/GDPR) y privacidad
- En AdMob → **Privacidad y mensajes** activa el mensaje **UMP** (obligatorio en
  UE). El plugin de Godot suele exponer un método para pedir consentimiento
  antes de inicializar (equivale a `requestConsentIfNeeded()` de la referencia).
- Declara el uso de anuncios en la ficha de Google Play (Data safety) y añade
  una política de privacidad.

### 5) Cuenta lista para cobrar
En AdMob → **Pagos**: completa datos fiscales y método de cobro. Los ingresos
del rewarded se acreditan a tu cuenta (la misma de Gnosia) automáticamente.

## Prueba
- En debug/PC: los anuncios se **simulan** (recompensa inmediata) — así puedes
  probar el loop sin tocar nada.
- En el teléfono con el plugin + ID de PRUEBA: verás un anuncio real de Google
  de prueba (no paga, pero confirma que funciona).
- Con tu ID real: ya genera ingresos. (No hagas clic tú mismo en tus anuncios
  reales: AdMob lo penaliza.)
