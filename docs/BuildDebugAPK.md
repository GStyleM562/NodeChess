# Cómo generar el APK **debug** de NodeChess

> Proyecto **Godot 4.6.3**. El proyecto real está en la subcarpeta **`game/`**.
> Salida: `game/build/nodechess.apk`. Paquete: `com.riceprotocolstudio.nodechess`.
> Todo el toolchain vive en `F:`.

## ⭐ REQUISITO CLAVE (esto bloqueaba el export)

Este proyecto usa el **renderer "Mobile"**, y en Android **Godot exige compresión de
texturas ETC2/ASTC**. Si NO está activada, el export por consola falla con un error
**opaco** (`Cannot export project ... due to configuration errors`) que **headless NO
detalla** — solo se ve en la GUI.

**Solución (ya aplicada):** Project Settings → **Rendering → Textures → VRAM Compression
→ Import ETC2 ASTC = ON**. En `project.godot` queda:
```
[rendering]
textures/vram_compression/import_etc2_astc=true
```
> Si algún día el export vuelve a fallar con "configuration errors", **esto es lo primero
> que hay que revisar.** El detalle del error solo aparece abriendo el editor GUI →
> **Proyecto → Exportar → preset Android** (texto en rojo abajo).

## Datos del entorno (ya configurados)

| Cosa | Valor |
|---|---|
| Godot (consola) | `F:\Godot\Godot_v4.6.3-stable_win64_console.exe` |
| Godot (GUI, para ver errores) | `F:\Godot\Godot_v4.6.3-stable_win64.exe` |
| Proyecto Godot | `F:\App Gnosia\claudenodeadventurechess\game` |
| Android SDK / JDK | `F:\AndroidSDK` / `F:\Android\jbr` (ya en Editor Settings) |
| Salida | `game/build/nodechess.apk` |

La firma **debug** es automática (no necesitas keystore ni variables de entorno).

## Comando (copiar y pegar en PowerShell)

```powershell
$godot = "F:\Godot\Godot_v4.6.3-stable_win64_console.exe"
$proj  = "F:\App Gnosia\claudenodeadventurechess\game"
$apk   = "$proj\build\nodechess.apk"
New-Item -ItemType Directory -Force -Path "$proj\build" | Out-Null

# 1) Reimportar (IMPRESCINDIBLE si cambiaste la compresión de texturas)
& $godot --headless --editor --path $proj --quit

# 2) Exportar el APK debug
& $godot --headless --path $proj --export-debug "Android" $apk

if (Test-Path $apk) {
  $mb = [math]::Round((Get-Item $apk).Length / 1MB, 1)
  Write-Host "OK -> $apk  ($mb MB)"
} else {
  Write-Host "No se generó el APK (revisa el log de arriba)."
}
```

Instálalo: `adb install -r game\build\nodechess.apk` (o pásalo al teléfono).

## ⚠️ Godot se cuelga tras `[ DONE ] export`

Es normal: el `.apk` **YA está escrito**. Solo cierra el proceso. NO es un fallo (un
exit 255/-1 al matarlo es esperado). Verifica por **tamaño/fecha del .apk**:
```powershell
Get-Process -Name "Godot*" | Stop-Process -Force
```

## Errores típicos (checklist)

1. **`configuration errors`** → ETC2/ASTC apagado (ver arriba). Es la causa #1 en este proyecto.
2. **Usar el binario equivocado** → tiene que ser el `_console.exe` con `--headless`.
3. **Olvidar que el proyecto está en `game/`** → pasar `--path ...\game`, no la raíz.
4. **No reimportar** tras cambiar texturas/recursos → corre el paso 1 primero.

## Qué decirle al Claude de VS Code (pégale esto)

> Genera el APK **debug** de este proyecto Godot (está en `game/`). Antes que nada
> confirma que **ETC2/ASTC** esté activado (Project Settings → Rendering → Textures →
> VRAM Compression → Import ETC2 ASTC = ON); el renderer Mobile lo exige y sin eso el
> export por consola falla con "configuration errors" sin decir por qué.
> Usa `F:\Godot\Godot_v4.6.3-stable_win64_console.exe` en `--headless`:
> 1) `--headless --editor --path "F:\App Gnosia\claudenodeadventurechess\game" --quit`
> 2) `--headless --path "F:\App Gnosia\claudenodeadventurechess\game" --export-debug "Android" "...\game\build\nodechess.apk"`
> Si Godot se cuelga tras `[ DONE ] export`, el APK ya está: ciérralo con
> `Get-Process Godot* | Stop-Process -Force` y verifica que exista el `.apk`.

> Para subirlo a Google Play necesitas un **.aab release**, no este APK debug → ver `docs/BuildReleaseAAB.md`.
