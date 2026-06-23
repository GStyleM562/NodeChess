# Cómo generar el **.aab release** de NodeChess (Google Play)

> Para **publicar en Google Play** se necesita un **.aab** (App Bundle) firmado en
> modo **release** — NO el APK debug. Proyecto **Godot 4.6.3** en `game/`.
> Salida: `game/build/nodechess.aab`. Paquete: `com.riceprotocolstudio.nodechess`.

## ⭐ Requisito clave (igual que el APK)

El renderer **Mobile** exige **ETC2/ASTC** en Android. Debe estar **ON**:
Project Settings → Rendering → Textures → VRAM Compression → **Import ETC2 ASTC = ON**
(`textures/vram_compression/import_etc2_astc=true` en `project.godot`). Sin esto el
export falla con "configuration errors" sin detalle en consola.

## Pre-requisitos (una vez)

- **Plantilla de build Gradle instalada**: editor GUI → **Proyecto → Instalar plantilla
  de compilación de Android…** (crea `game/android/build/`). El AAB **siempre** usa Gradle.
- En el preset **Android**: `gradle_build/use_gradle_build=true` y **Export Format = AAB**
  (`gradle_build/export_format=1`). Para el APK debug es `0`; para el AAB es `1`.
- **Keystore de release propio de NodeChess** (ver siguiente paso). NO uses el debug.

## 1) Crear el keystore release (una sola vez)

Cada app del estudio tiene su propio *upload key*. Crea el de NodeChess en `F:` (NUNCA
en `C:`), elige una **contraseña fuerte y guárdala**:

```powershell
$ks = "F:\GodotProjects\keystores\nodechess-upload.jks"
$pw = "PON-UNA-CONTRASEÑA-FUERTE"   # <-- cámbiala y GUÁRDALA (no la pierdas)
& "F:\Android\jbr\bin\keytool.exe" -genkeypair -v -keystore $ks -alias upload `
  -keyalg RSA -keysize 2048 -validity 10000 -storepass $pw -keypass $pw `
  -dname "CN=Rice Protocol Studio, O=Rice Protocol Studio"
# Guarda la contraseña FUERA del repo, p.ej.:
"storeFile=$ks`nstorePassword=$pw`nkeyPassword=$pw`nkeyAlias=upload" |
  Set-Content "F:\GodotProjects\keystores\nodechess-key.properties" -Encoding utf8
```

> ⚠️ **Respáldalo.** Es la *upload key* de NodeChess en Play. Si la pierdes hay que
> pedirle a Google que la resetee. **NUNCA** la pongas en `docs/` ni en el repo.

## 2) Generar el AAB

```powershell
$proj  = "F:\App Gnosia\claudenodeadventurechess\game"
$godot = "F:\Godot\Godot_v4.6.3-stable_win64_console.exe"
$ks    = "F:\GodotProjects\keystores\nodechess-upload.jks"
$kprop = "F:\GodotProjects\keystores\nodechess-key.properties"
$aab   = "$proj\build\nodechess.aab"

# a) Subir versionCode +1 (Play rechaza versiones repetidas). Sin BOM para que Godot lea bien.
$cfgPath = "$proj\export_presets.cfg"
$content = [System.IO.File]::ReadAllText($cfgPath)
$cur = [int]([regex]::Match($content, 'version/code=(\d+)').Groups[1].Value)
$content = [regex]::Replace($content, 'version/code=\d+', "version/code=$($cur+1)")
[System.IO.File]::WriteAllText($cfgPath, $content)
Write-Host "versionCode $cur -> $($cur+1)"

# b) Keystore release por VARIABLES DE ENTORNO (Godot CLI ignora la clave del preset).
$pw = (Select-String -Path $kprop -Pattern '^storePassword=(.*)$').Matches[0].Groups[1].Value
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $ks
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = "upload"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $pw

# c) Reimportar + exportar AAB release
& $godot --headless --editor --path $proj --quit
& $godot --headless --path $proj --export-release "Android" $aab
```

Si Godot **se cuelga** tras `[ DONE ] export`, el AAB **ya está**: ciérralo y verifica.
```powershell
Get-Process -Name "Godot*" | Stop-Process -Force
```

## 3) Verificar el AAB

```powershell
$aab = "F:\App Gnosia\claudenodeadventurechess\game\build\nodechess.aab"
& "F:\Android\jbr\bin\jarsigner.exe" -verify $aab | Select-String "jar verified"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [System.IO.Compression.ZipFile]::OpenRead($aab)
$e = $z.Entries | Where-Object { $_.FullName -eq "base/manifest/AndroidManifest.xml" }
$ms = New-Object System.IO.MemoryStream; $e.Open().CopyTo($ms)
$txt = [System.Text.Encoding]::GetEncoding(28591).GetString($ms.ToArray()); $z.Dispose()
"paquete nodechess? " + ($txt -match "com\.riceprotocolstudio\.nodechess")
```
Debe decir **`jar verified`** y `True`.

## Errores ya conocidos (no tropezar)

- **`Could not find release keystore`** → Godot CLI **no** lee la clave del preset.
  Solución: las 3 env vars `GODOT_ANDROID_KEYSTORE_RELEASE_*` (paso 2b).
- **`configuration errors`** → ETC2/ASTC apagado (ver arriba) o falta la plantilla Gradle.
- **Godot no cierra tras el export** → el `.aab` ya quedó escrito; mata el proceso.
  Verifica por tamaño/fecha, no por exit code (un 255/-1 al matarlo es normal).
- **No escribir la contraseña del keystore en `docs/` ni en el repo.**
- **`export_presets.cfg` y `android/` suelen estar gitignored** → la versión vive solo local.

## Subir a Google Play

1. Play Console → crea la app **NodeChess** con el paquete `com.riceprotocolstudio.nodechess`
   (ese ID **no se puede cambiar** tras publicar).
2. Acepta **Play App Signing** (Google maneja la clave final; tu `nodechess-upload.jks`
   es solo la *upload key*).
3. Pruebas internas → nueva versión → sube `nodechess.aab`.
4. Avisos de Play (R8/desofuscación, símbolos nativos) son *warnings* inevitables en
   Godot → se ignoran, no bloquean.
