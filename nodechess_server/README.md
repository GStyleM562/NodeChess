# NodeChess — Servidor relay (online por turnos)

Servidor **relay** (Node + `ws`) para el 1v1 online por turnos. Salas por **código de
4 letras**. El motor corre LOCAL en cada cliente (determinista + lockstep); el servidor
solo: crea/une salas, intercambia los **mazos**, deja al **anfitrión** elegir el mapa,
reparte una semilla y **retransmite** la acción del jugador activo al rival.

## Probar en LOCAL (sin desplegar)
1. Instala dependencias y arranca:
   ```powershell
   cd nodechess_server
   npm install
   node server.js        # escucha en :8080
   ```
2. En el app → **🌐 Online** → campo *Servidor*:
   - Emulador Android → `ws://10.0.2.2:8080`
   - Teléfono físico en la misma WiFi → `ws://TU_IP_LAN:8080` (ve tu IP con `ipconfig`)
3. Uno **CREAR SALA** (sale un código) → el otro **UNIRSE** + escribe el código.

## Desplegar en Render (gratis) — lo que TÚ haces
El repo ya trae `render.yaml` en la raíz (apunta a `nodechess_server/`).

1. Sube el repo a GitHub (ya está: `GStyleM562/NodeChess`).
2. En **https://render.com** → **New** → **Blueprint** → conecta el repo `NodeChess`.
   Render detecta `render.yaml` y crea el servicio **`nodechess-server`** solo.
   *(o: New → Web Service → repo → Root Dir `nodechess_server`, Build `npm install`,
   Start `node server.js`).*
3. Cuando quede **Live**, copia su URL (ej. `https://nodechess-server.onrender.com`).
4. En el app, campo *Servidor*, usa la versión **wss**:
   `wss://nodechess-server.onrender.com`
   (el app ya trae ese valor por defecto; cámbialo si tu URL es otra).

> Plan free: el servidor **duerme** tras ~15 min sin uso y despierta en ~30-50 s en la
> primera conexión. El app lo "despierta" con un GET antes del WebSocket, así que la
> primera conexión tras dormir tarda un poco — es normal.

## Protocolo (JSON `{t, ...}`)
`create/join {name, deck, [code], [map]}` · `setmap {map}` (host) · `start` (host) ·
`action {action}` · `leave`. El servidor responde `created/joined/players/room/start/
action/left/error`. El `start` lleva **ambos mazos + asientos** para que cada cliente
arme el mismo roster de partida.
