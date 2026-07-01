// NodeChess — servidor RELAY de salas (Node + ws). Turnos ALTERNOS 1v1.
//
// Filosofia (como NODE RACERS / NODEHACK relay): el motor corre LOCAL en cada
// cliente (determinista). Este servidor solo: gestiona salas por codigo, intercambia
// los MAZOS de ambos, deja al ANFITRION elegir el mapa, reparte una semilla, y
// RETRANSMITE la ACCION del jugador activo al rival. El jugador activo resuelve su
// ataque (tira los dados) y manda el resultado ya resuelto -> cero divergencia.
//
// Escucha en $PORT (Render) y responde 200 en cualquier ruta HTTP (health check).

const http = require("http");
const { WebSocketServer } = require("ws");

const PORT = process.env.PORT || 8080;
const rooms = new Map(); // code -> room
let nextId = 1;

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("NodeChess relay OK\n");
});
const wss = new WebSocketServer({ server });

function genCode() {
  const A = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // sin 0/O, 1/I
  let c;
  do {
    c = Array.from({ length: 4 }, () => A[(Math.random() * A.length) | 0]).join("");
  } while (rooms.has(c));
  return c;
}
function send(ws, obj) {
  if (ws.readyState === ws.OPEN) ws.send(JSON.stringify(obj));
}
function broadcast(room, obj, exceptId = null) {
  for (const p of room.players) if (p.id !== exceptId) send(p.ws, obj);
}
function playerList(room) {
  return room.players.map((p) => ({ id: p.id, name: p.name, seat: p.seat, ready: p.ready, host: p.id === room.hostId }));
}
function mkPlayer(ws, msg, seat) {
  return { ws, id: ws.nc.id, name: String(msg.name || "P").slice(0, 16), seat, ready: false, deck: Array.isArray(msg.deck) ? msg.deck : [] };
}

wss.on("connection", (ws) => {
  ws.nc = { id: nextId++, room: null };
  ws.isAlive = true;
  ws.on("pong", () => (ws.isAlive = true));
  ws.on("message", (data) => {
    let m;
    try { m = JSON.parse(data.toString()); } catch { return; }
    handle(ws, m);
  });
  ws.on("close", () => leave(ws));
  ws.on("error", () => {});
});

function handle(ws, msg) {
  switch (msg.t) {
    case "create": {
      const code = genCode();
      const p = mkPlayer(ws, msg, 0);
      const room = { code, players: [p], started: false, seed: 0, map: msg.map | 0, hostId: p.id };
      rooms.set(code, room);
      ws.nc.room = code;
      send(ws, { t: "created", code, you: 0, map: room.map, players: playerList(room) });
      console.log(`[${code}] creada por ${p.name}`);
      break;
    }
    case "join": {
      const room = rooms.get((msg.code || "").toUpperCase());
      if (!room) return send(ws, { t: "error", msg: "Sala no encontrada" });
      if (room.started) return send(ws, { t: "error", msg: "La partida ya empezo" });
      if (room.players.length >= 2) return send(ws, { t: "error", msg: "Sala llena" });
      const p = mkPlayer(ws, msg, 1);
      room.players.push(p);
      ws.nc.room = room.code;
      send(ws, { t: "joined", code: room.code, you: 1, map: room.map, players: playerList(room) });
      broadcast(room, { t: "players", players: playerList(room) }, p.id);
      console.log(`[${room.code}] ${p.name} se unio`);
      break;
    }
    case "setmap": {
      const room = rooms.get(ws.nc.room);
      if (!room || room.hostId !== ws.nc.id) return;
      room.map = msg.map | 0;
      broadcast(room, { t: "room", map: room.map });
      break;
    }
    case "start": {
      const room = rooms.get(ws.nc.room);
      if (!room || room.hostId !== ws.nc.id || room.started) return;
      if (room.players.length < 2) return send(ws, { t: "error", msg: "Falta el segundo jugador" });
      room.started = true;
      room.seed = (Math.random() * 2147483646 + 1) | 0;
      // ambos mazos + asientos -> cada cliente construye el MISMO roster de partida
      const decks = room.players.map((p) => ({ seat: p.seat, name: p.name, deck: p.deck }));
      broadcast(room, { t: "start", seed: room.seed, map: room.map, decks });
      console.log(`[${room.code}] START seed=${room.seed}`);
      break;
    }
    case "action": {
      const room = rooms.get(ws.nc.room);
      if (!room) return;
      broadcast(room, { t: "action", action: msg.action }, ws.nc.id); // al rival
      break;
    }
    case "leave":
      leave(ws);
      break;
  }
}

function leave(ws) {
  const code = ws.nc && ws.nc.room;
  ws.nc.room = null;
  if (!code) return;
  const room = rooms.get(code);
  if (!room) return;
  room.players = room.players.filter((p) => p.id !== ws.nc.id);
  if (room.players.length === 0) {
    rooms.delete(code);
    console.log(`[${code}] vacia, eliminada`);
    return;
  }
  if (room.hostId === ws.nc.id) room.hostId = room.players[0].id;
  broadcast(room, { t: "left", id: ws.nc.id });
  broadcast(room, { t: "players", players: playerList(room) });
}

const HEARTBEAT = setInterval(() => {
  for (const ws of wss.clients) {
    if (ws.isAlive === false) { ws.terminate(); continue; }
    ws.isAlive = false;
    try { ws.ping(); } catch {}
  }
}, 25000);
wss.on("close", () => clearInterval(HEARTBEAT));

server.listen(PORT, () => console.log(`NodeChess relay escuchando en :${PORT}`));
