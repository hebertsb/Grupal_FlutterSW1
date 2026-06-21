# SIVIC Flutter — Guía técnica: Cámaras y Detección IA

> Autor: Hebert Suarez Burgos  
> Última actualización: 2026-06-21

---

## 1. Cómo funciona el panel de cámaras en Flutter

El panel de cámaras (`PantallaCamaras`) obtiene la lista de cámaras registradas en la BD via el proveedor `camarasProvider` y muestra cada una en un grid.

### ¿Cómo sabe Flutter si una cámara es local o IP?

```dart
// pantalla_camaras.dart
if (cam.rtspUrl.startsWith('local://')) {
  return _CeldaCamaraLocal(...);  // usa cámara trasera del celular
}
return _CeldaCamara(...);  // reproduce stream RTSP/MJPEG
```

El campo `rtsp_url` en la BD determina el tipo:
- `local://celular-1` → cámara local (celular con Flutter)
- `rtsp://192.168.1.10:554/...` → cámara IP fija
- `http://192.168.1.5:8080/video` → IP Webcam (app de Android)

---

## 2. Cámara IP / RTSP (`_CeldaCamara`)

### ¿Qué muestra?
- Si `rtsp_url` contiene `/video` → usa `Image.network()` (stream MJPEG directo)
- Cualquier otra URL → usa `VideoPlayerController.networkUrl()` (reproduce stream de video)

### No llama al modelo IA
Esta celda solo muestra el video. La detección IA para cámaras IP la dispara el **panel web Angular**, no Flutter.

---

## 3. Cámara Local (`_CeldaCamaraLocal`) — El corazón del sistema móvil

Esta celda usa la **cámara trasera del propio celular** para vigilar y detectar personas en tiempo real.

### Flujo completo

```
Cada 2 segundos:
    1. _ctrl.takePicture()         ← captura foto con cámara trasera
    2. foto.readAsBytes()          ← convierte a bytes JPEG
    3. HTTP POST multipart         ← envía al backend Django
       URL: $urlDjango/api/camaras/<id>/analizar_local/
       Headers: Authorization: Bearer <token JWT>
       Body: file=frame.jpg, umbral_merodeo=15
    4. Recibe JSON:
       { conteo_personas, nivel, alertas: [...] }
    5. Actualiza UI con badges de estado
```

### Código clave

```dart
// Inicializa la cámara trasera
final desc = camaras.firstWhere(
    (c) => c.lensDirection == CameraLensDirection.back,
    orElse: () => camaras.first,
);
_ctrl = CameraController(desc, ResolutionPreset.medium, enableAudio: false);

// Timer: analiza cada 2 segundos
_timer = Timer.periodic(const Duration(seconds: 2), (_) => _analizarFrame());
```

### Qué devuelve Django

```json
{
  "conteo_personas": 3,
  "nivel": "sospechoso",
  "alertas": ["merodeo", "personas_peleando"],
  "detecciones": [...],
  "modo": "personas"
}
```

### Cómo se muestra en pantalla

| Campo | Badge | Color |
|-------|-------|-------|
| `nivel = normal` | `0 · NORMAL` | Verde |
| `nivel = sospechoso` | `3 · SOSPECHOSO` | Amarillo |
| `nivel = critico` | `6 · CRÍTICO` | Rojo |
| `alertas` contiene `personas_peleando` | `⚠ PELEA DETECTADA` | Borde rojo |

---

## 4. Autenticación en las peticiones

Flutter guarda el token JWT en `SharedPreferences` bajo la clave `sivic_token`:

```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('sivic_token') ?? '';

req.headers['Authorization'] = 'Bearer $token';
```

El token lo obtiene el proveedor `authProvider` al hacer login y lo persiste localmente.

---

## 5. URL base del backend

Definida en `lib/nucleo/red/cliente_http.dart`:
```dart
const String urlDjango = 'http://192.168.X.X:8001';  // IP local del servidor
```

**Importante:** Si el backend cambia de IP, actualizar esta constante. En producción apunta a la URL de Render/Railway.

---

## 6. Umbral de merodeo

El valor `umbral_merodeo=15` en el body del POST indica cuántos análisis consecutivos debe acumular el backend antes de generar alerta de merodeo. Con análisis cada 2 segundos:

| Valor | Tiempo aproximado |
|-------|-------------------|
| 15 (demo) | ~30 segundos |
| 90 (producción) | ~3 minutos |

Para cambiar: modificar `req.fields['umbral_merodeo'] = '15';` en `_analizarFrame()`.

---

## 7. Archivos clave

| Archivo | Qué hace |
|---------|----------|
| `lib/pantallas/camaras/pantalla_camaras.dart` | Panel completo de cámaras |
| `_CeldaCamaraLocal` (en mismo archivo) | Captura frames y llama al modelo |
| `_CeldaCamara` (en mismo archivo) | Muestra stream RTSP/MJPEG |
| `lib/nucleo/red/cliente_http.dart` | URL base del backend |
| `lib/nucleo/proveedores/camaras_proveedor.dart` | Carga lista de cámaras desde la API |
| `lib/nucleo/proveedores/auth_proveedor.dart` | Login, token JWT, cierre de sesión |

---

## 8. Cómo agregar soporte para un nuevo modelo (ejemplo: perros)

El microservicio IA devuelve las alertas en el campo `alertas` del JSON. Si el backend agrega `"perro_detectado"` a las alertas, Flutter puede reaccionar así:

```dart
// En _analizarFrame(), después de parsear el JSON:
final alertas = (body['alertas'] as List<dynamic>?) ?? [];
final perroDetectado = alertas.contains('perro_detectado');

// En el build():
if (perroDetectado)
  Positioned(
    bottom: 30, left: 0, right: 0,
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(230),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('🐕 PERRO DETECTADO',
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
      ),
    ),
  ),
```

El único cambio en Flutter es leer el nuevo valor de `alertas`. La lógica de detección vive entera en el microservicio Python, no en Flutter.

---

## 9. Qué NO tocar

| Qué | Por qué |
|-----|---------|
| `CameraController` con `ResolutionPreset.medium` | Mayor resolución aumenta el tamaño del frame y puede exceder los 4s de timeout |
| `Timer.periodic(Duration(seconds: 2))` | Intervalo mínimo viable con el modelo actual. Menos tiempo satura el backend |
| `umbral_merodeo=15` | Solo cambiar con el equipo backend. Afecta cuándo se generan alertas reales |
| `urlDjango` | Solo cambiar si el servidor cambia de IP/dominio |
| `Authorization: Bearer $token` | El backend rechaza peticiones sin este header con 401 |

---

## 10. Troubleshooting

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| Badge nunca aparece | Backend caído o IP incorrecta | Verificar `urlDjango` y que Django corra |
| `timeout` silencioso cada 2s | Microservicio IA apagado (puerto 8002) | Iniciar `uvicorn api:app --port 8002` |
| Cámara negra | Permiso de cámara denegado | Conceder permiso en configuración del Android |
| Error 401 | Token expirado | Hacer logout y login de nuevo |
| Cámara no en lista | `rtsp_url` no empieza con `local://` | Verificar el campo en BD o panel admin |
