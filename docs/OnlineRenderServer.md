# Online por servidor (Render) — despertar el server + permisos

> Referencia de cómo se resolvió que el **multijugador online funcionara** (en el
> proyecto hermano *Node Racers*), para reusarlo si NodeChess agrega online.
> Servidor: un **relay Node + `ws`** desplegado en **Render (plan free)**; cada cliente
> Godot se conecta por **WebSocket** para crear/unirse a salas por código.

## Síntoma (problema, ya resuelto)

Al pulsar **Crear Sala**, el servidor **nunca despertaba** y **nunca se generaba el
código**; y en el **móvil** el online **caía al instante** aunque en PC funcionara.

Eran **dos problemas distintos** que se juntaban:

---

## Problema 1 — El server (Render free) no despierta con un WebSocket directo

**Causa:** Render en plan **free duerme** la instancia tras ~15 min sin uso. Un
**WebSocket directo** a un servidor dormido **se cae** (close code **−1**): el router
de Render **no aguanta el upgrade a WebSocket** durante el arranque en frío (~50s).

**Solución:** **despertar primero con una petición HTTP GET** normal (a la misma URL con
`https://`), y **solo después** abrir el WebSocket. Un GET normal **sí** lo retiene el
router de Render (~50s) y enciende la instancia. Da igual el resultado del GET: si Render
respondió (aunque sea error/timeout), la instancia **ya está despierta** → abrir el WS.

### Patrón en el cliente (Godot, `net_client.gd`)

```gdscript
func connect_to(url: String) -> void:
    _ensure_http()
    _ws_url = url
    if _ws_url.begins_with("wss://") or _ws_url.begins_with("https://"):
        connecting_status.emit("Despertando servidor... (puede tardar ~50s la primera vez)")
        var http_url := _ws_url.replace("wss://", "https://")
        var err := _http.request(http_url)          # 1) GET para DESPERTAR
        if err != OK:
            _open_ws()                               # si el GET no salió, intenta el WS igual
    else:
        _open_ws()                                   # servidor local (ws://): no duerme

func _on_wake_done(_r, _c, _h, _b) -> void:
    connecting_status.emit("Conectando a la sala...")
    _open_ws()                                       # 2) YA despierto -> abrir WebSocket
```

Detalles que ayudan:
- Un `HTTPRequest` con `timeout ≈ 70s` (el cold start free puede tardar ~50s).
- **Reintentos** del WebSocket (p.ej. 3) por si la primera conexión aún pilla el arranque.
- Mensajes de estado ("Despertando servidor…", "Conectando…") para que el usuario
  entienda la espera de la primera conexión.

### Lado servidor (para que el GET despierte)

El server debe responder **200 en `/`** (cualquier ruta HTTP) además de aceptar el
WebSocket. En Render, el **health check** apunta a `/`. Ese endpoint HTTP es justo lo que
el GET usa para despertar la instancia.

---

## Problema 2 — En el móvil el online cae al instante (en PC va)

**Causa:** el export de **Android no incluía el permiso de INTERNET**. En PC no hace
falta permiso, por eso ahí funcionaba; en el teléfono la app **ni podía abrir la red**.

**Solución:** activar en el **preset de exportación Android** (o en `export_presets.cfg`):
```
permissions/internet=true
permissions/access_network_state=true
```
En el editor: **Proyecto → Exportar → Android → pestaña Options → Permissions →** marca
**Internet** (y *Access Network State*). Reconstruir el APK/AAB después.

> Es un fallo silencioso clásico: "en la PC funciona, en el celular no" casi siempre es
> el permiso de INTERNET faltante en el export.

---

## Checklist para dejar el online funcionando en móvil

1. **Cliente:** despertar con **GET HTTP primero**, luego abrir el **WebSocket**
   (nunca WS directo a un Render free dormido).
2. **Servidor:** responde **200 en `/`** (health check) y acepta WebSocket.
3. **Permisos Android:** `internet` **y** `access_network_state` activados en el export.
4. **URL correcta:** `wss://…onrender.com` (TLS) en producción; `ws://IP:puerto` en LAN.
5. **Primera conexión lenta** (~30–50s por el cold start del plan free): muéstralo en UI.
6. Reconstruir el APK/AAB tras cambiar permisos (los permisos viven en el binario).

## Nota sobre el plan free de Render

Duerme tras ~15 min sin tráfico y despierta en ~30–50s en la primera conexión. Si más
adelante molesta ese arranque en frío, opciones: un "ping" periódico para mantenerlo
despierto, una VM "always free" (p.ej. Oracle Cloud), o un VPS de ~$5/mes para 24/7.
