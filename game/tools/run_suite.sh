#!/bin/bash
# NodeChess — corre TODA la suite headless y resume PASS/FAIL (Capa 1 del plan).
# Uso (desde la raíz del repo):  bash game/tools/run_suite.sh [ruta_godot] [--live]
GODOT="${1:-F:/Godot/Godot_v4.6.3-stable_win64_console.exe}"
INCLUDE_LIVE="$2"
DIR="$(cd "$(dirname "$0")/.." && pwd)"     # .../game
REPO="$(dirname "$DIR")"

NODE_PID=""
if command -v node >/dev/null 2>&1; then
  node "$REPO/nodechess_server/server.js" >/dev/null 2>&1 &
  NODE_PID=$!
  sleep 2
else
  echo "(sin Node: test_net se saltara)"
fi

FAILS=0
for t in "$DIR"/tools/test_*.gd; do
  name=$(basename "$t" .gd)
  [ "$name" = "test_net_live" ] && [ "$INCLUDE_LIVE" != "--live" ] && continue
  if [ -z "$NODE_PID" ] && [ "$name" = "test_net" ]; then
    printf "%-24s SALTADO (sin Node)\n" "$name"
    continue
  fi
  out=$(timeout 120 "$GODOT" --headless --path "$DIR" --script "res://tools/$name.gd" 2>&1)
  marker=$(echo "$out" | grep -Eo '[A-Za-z0-9_]+_(OK|FAIL)' | tail -1)
  [ -z "$marker" ] && marker=$(echo "$out" | grep -Ex '(OK|FAIL)' | tail -1)
  [ -z "$marker" ] && marker="SIN_MARCADOR"
  printf "%-24s %s\n" "$name" "$marker"
  case "$marker" in *OK) ;; *) FAILS=$((FAILS+1));; esac
done

[ -n "$NODE_PID" ] && kill $NODE_PID 2>/dev/null
echo "---"
echo "FALLOS: $FAILS"
[ "$FAILS" -gt 0 ] && echo "NO hacer .aab hasta dejar esto en 0."
exit $FAILS
