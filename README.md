# SIVIC Mobile — App de Guardia

App Flutter para guardias del sistema de vigilancia inteligente SIVIC. Muestra cámaras en tiempo real, gestiona eventos de seguridad y recibe alertas instantáneas por WebSocket cuando la IA detecta una infracción.

---

## Requisitos previos

- Flutter >= 3.19 / Dart >= 3.3
- Android SDK (API 21+) o dispositivo físico Android
- Backend SIVIC corriendo con uvicorn (ver README del backend)
- El celular/emulador debe estar en la misma red WiFi que el PC con el backend

---

## Configurar IP del backend

Antes de correr, actualizar la IP de la PC en dos archivos:

**`lib/nucleo/red/cliente_http.dart` — línea 7:**
```dart
const String _urlBase = 'http://192.168.1.X:8000/api';
```

**`lib/nucleo/red/websocket_servicio.dart` — línea 9:**
```dart
const String _wsBase = 'ws://192.168.1.X:8000';
```

Obtener la IP local del PC con `ipconfig` (Windows) o `ip a` (Linux). Ambas constantes deben apuntar a la misma IP.

> Para emulador Android usar `10.0.2.2` en lugar de la IP real (es el alias del localhost del PC).

---

## Correr la app

```bash
flutter pub get
flutter run
```

Para dispositivo físico conectado por USB:
```bash
flutter run -d <device-id>
# Ver dispositivos disponibles: flutter devices
```

---

## Estructura del proyecto

```
lib/
├── main.dart                          # Punto de entrada, ProviderScope, GoRouter
├── nucleo/
│   ├── red/
│   │   ├── cliente_http.dart          # Dio configurado con JWT interceptor
│   │   └── websocket_servicio.dart    # Servicio WS + AlertaWS + EstadoWS + wsProvider
│   ├── proveedores/
│   │   ├── auth_proveedor.dart        # Login, logout, sesión persistente
│   │   ├── camaras_proveedor.dart     # Lista de cámaras del condominio
│   │   ├── eventos_proveedor.dart     # Lista y actualización de eventos
│   │   ├── reglas_proveedor.dart      # Reglas de detección IA
│   │   ├── notificaciones_proveedor.dart
│   │   ├── auditoria_proveedor.dart
│   │   ├── usuarios_proveedor.dart
│   │   ├── tema_proveedor.dart        # Modo oscuro/claro
│   │   └── shell_proveedor.dart       # Índice de navegación activo
│   ├── rutas/
│   │   └── rutas_app.dart             # GoRouter con redirección por rol
│   ├── temas/
│   │   └── tema.dart                  # ThemeData oscuro y claro
│   └── constantes/
│       └── colores.dart
├── pantallas/
│   ├── login/                         # Pantalla de login
│   ├── camaras/                       # Grid de cámaras MJPEG en vivo
│   ├── eventos/                       # Lista de eventos con filtros
│   ├── notificaciones/                # Historial de alertas WS
│   ├── dashboard/                     # Resumen del sistema
│   ├── reglas/                        # Reglas de detección (admin)
│   ├── usuarios/                      # Gestión de usuarios (admin)
│   └── auditoria/                     # Log de acciones (admin)
└── compartido/
    ├── modelos/                       # DTOs: Camara, Evento, Regla, Usuario...
    └── widgets/
        ├── diseno_guardia.dart        # Shell de navegación guardia (bottom nav + badge)
        └── drawer_admin.dart          # Drawer de navegación admin
```

---

## Dependencias principales

| Paquete | Uso |
|---|---|
| `go_router` | Navegación declarativa con redirección por rol |
| `flutter_riverpod` | Estado global reactivo |
| `dio` | HTTP con interceptor JWT automático |
| `web_socket_channel` | Conexión WebSocket al backend |
| `shared_preferences` | Sesión persistente (token JWT) |
| `firebase_messaging` | Push notifications FCM |
| `flutter_local_notifications` | Notificación local al recibir alerta WS |
| `video_player` | Reproducción de streams de cámara |
| `dart_jsonwebtoken` | Decode del JWT para leer rol/expiración |
| `intl` | Formateo de fechas |

---

## Notificaciones WebSocket en tiempo real

### Cómo funciona

```
Backend YOLO detecta infracción
        ↓
POST /api/eventos/inferencia/
        ↓
Django emite WebSocket a grupo "sivic_alertas"
        ↓
wsProvider recibe mensaje JSON
        ↓
Estado EstadoWS actualizado (lista alertas + contador)
        ↓
diseno_guardia.dart → SnackBar banner + badge en nav
flutter_local_notifications → notificación del sistema
```

### Arquitectura del servicio (`websocket_servicio.dart`)

**`AlertaWS`** — modelo de alerta recibida:
- `eventoId`, `camaraNombre`, `reglaNombre`, `confianzaIa`, `timestamp`, `imagenUrl`
- `leida` — marcado de lectura local

**`EstadoWS`** — estado Riverpod:
- `alertas` — lista de hasta 50 alertas recientes
- `conectado` — bool de estado de conexión
- `noLeidas` — getter con conteo de no leídas

**`WebSocketNotifier`** (StateNotifier):
- `conectar(token)` — abre conexión `ws://<host>:8000/ws/alertas/?token=<jwt>`
- `desconectar()` — cierra canal y limpia estado
- `marcarLeida(eventoId)` / `marcarTodasLeidas()`
- Auto-reconexión cada 5s si el canal se cierra

**`wsProvider`** — `StateNotifierProvider` global accesible desde cualquier widget

### Cuándo conecta / desconecta

- **Conecta**: después de login exitoso (`auth_proveedor.dart`) y al restaurar sesión al abrir la app
- **Desconecta**: en logout (token eliminado de `SharedPreferences`)

### Mostrar alertas en la UI

`diseno_guardia.dart` usa `ref.listenManual(wsProvider, ...)` en `initState` para mostrar un `SnackBar` en cada alerta nueva. El icono de la pestaña "Notificaciones" muestra `Badge.count(count: noLeidas)`.

---

## Autenticación

- Login → `POST /api/autenticacion/login/` → JWT almacenado en `SharedPreferences` con clave `sivic_token`
- Interceptor Dio agrega `Authorization: Bearer <token>` a cada request
- GoRouter redirige a `/login` si no hay token; redirige a pantalla por rol (guardia/admin) si ya hay sesión

---

## Pantalla de cámaras

Muestra grid de imágenes MJPEG en tiempo real usando `Image.network()` con stream desde `GET /api/camaras/<id>/stream/`. El backend sirve el stream con `StreamingHttpResponse` (async generator + OpenCV).

---

## Rol del usuario

El JWT contiene el campo `rol` (`guardia` o `admin`). Al decodificarlo con `dart_jsonwebtoken`:

- `guardia` → shell inferior con tabs: Cámaras, Eventos, Notificaciones
- `admin` → drawer lateral con acceso a Usuarios, Reglas, Auditoría además de las pantallas de guardia
