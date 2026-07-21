# NodeChess — corre TODA la suite headless y resume PASS/FAIL (Capa 1 del plan).
# Uso (desde la raíz del repo):  .\game\tools\run_suite.ps1
#   -Godot <ruta>   ruta al ejecutable de consola de Godot (default F:\Godot\...)
#   -IncludeLive    incluye test_net_live (pega al Render DESPLEGADO, tarda por el frío)
param(
    [string]$Godot = "F:\Godot\Godot_v4.6.3-stable_win64_console.exe",
    [switch]$IncludeLive
)

$gameDir = Split-Path -Parent $PSScriptRoot          # ...\game
$repo = Split-Path -Parent $gameDir

if (-not (Test-Path $Godot)) {
    Write-Host "No encuentro Godot en: $Godot  (pasa -Godot <ruta>)"
    exit 2
}

# Relay local para test_net (si hay Node instalado)
$node = $null
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    # comillas: la ruta del repo puede llevar espacios
    $srv = '"' + (Join-Path $repo "nodechess_server\server.js") + '"'
    $node = Start-Process node -ArgumentList $srv -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds 2
} else {
    Write-Host "(sin Node: test_net se saltara)"
}

$fails = 0
$tests = Get-ChildItem (Join-Path $gameDir "tools") -Filter "test_*.gd" | Sort-Object Name
foreach ($t in $tests) {
    if (-not $IncludeLive -and $t.BaseName -eq "test_net_live") { continue }
    if (-not $nodeCmd -and ($t.BaseName -eq "test_net" -or $t.BaseName -eq "test_matchmaking")) {
        "{0,-24} SALTADO (sin Node)" -f $t.BaseName
        continue
    }
    $out = & $Godot --headless --path $gameDir --script ("res://tools/" + $t.Name)
    $marker = ($out | Select-String -Pattern "[A-Za-z0-9_]+_(OK|FAIL)\b" -AllMatches |
        ForEach-Object { $_.Matches } | ForEach-Object { $_.Value }) | Select-Object -Last 1
    if (-not $marker) {
        $solo = $out | Where-Object { ("" + $_).Trim() -in @("OK", "FAIL") } | Select-Object -Last 1
        if ($solo) { $marker = ("" + $solo).Trim() }
    }
    if (-not $marker) { $marker = "SIN_MARCADOR" }
    "{0,-24} {1}" -f $t.BaseName, $marker
    if ($marker -notmatch "OK$") { $fails++ }
}

if ($node) { try { Stop-Process -Id $node.Id -Force -ErrorAction Stop } catch {} }
"---"
"FALLOS: $fails"
if ($fails -gt 0) { "NO hacer .aab hasta dejar esto en 0." }
exit $fails
