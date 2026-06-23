# NodeChess — build del APK debug (Godot 4.6.3, Gradle build, todo en F:).
#
# 1) REIMPORTA assets (toma siempre la version mas reciente).
# 2) EXPORTA el APK debug (firmado con la debug keystore de Gradle).
#
# Uso:  powershell -File tools\build_apk.ps1

$godot = "F:\Godot\Godot_v4.6.3-stable_win64_console.exe"
$proj  = "F:\App Gnosia\claudenodeadventurechess\game"
$apk   = "$proj\build\nodechess.apk"

if (-not (Test-Path "$proj\build")) { New-Item -ItemType Directory -Path "$proj\build" | Out-Null }

Write-Host "[1/2] Reimportando assets..."
& $godot --headless --editor --path $proj --quit | Out-Null

Write-Host "[2/2] Exportando APK debug (Gradle)..."
& $godot --headless --path $proj --export-debug "Android" $apk

if (Test-Path $apk) {
    $mb = [math]::Round((Get-Item $apk).Length / 1MB, 1)
    Write-Host ("OK -> {0}  ({1} MB, {2})" -f $apk, $mb, (Get-Item $apk).LastWriteTime)
} else {
    Write-Host "FALLO: no se genero el APK. Revisa el log de arriba."
}
