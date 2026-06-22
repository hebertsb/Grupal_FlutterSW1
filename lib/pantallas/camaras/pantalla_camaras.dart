import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../compartido/modelos/camara.modelo.dart';
import '../../nucleo/constantes/colores.dart';
import '../../nucleo/proveedores/auth_proveedor.dart';
import '../../nucleo/proveedores/camaras_proveedor.dart';
import '../../nucleo/proveedores/shell_proveedor.dart';
import '../../nucleo/red/cliente_http.dart';

class PantallaCamaras extends ConsumerStatefulWidget {
  const PantallaCamaras({super.key});

  @override
  ConsumerState<PantallaCamaras> createState() => _PantallaCamarasState();
}

class _PantallaCamarasState extends ConsumerState<PantallaCamaras> {
  int     _columnas    = 2;
  Camara? _camaraFoco;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(camarasProvider);

    return Scaffold(
      backgroundColor: kFondoOscuro,
      appBar: AppBar(
        leading: Padding(padding: const EdgeInsets.all(8), child: Image.asset('assets/icon/icon.png')),
        title: const Text('Panel de Cámaras'),
        actions: [
          if (ref.watch(authProvider).usuario?.esAdmin ?? false)
            IconButton(icon: const Icon(Icons.menu), onPressed: () => ref.read(shellScaffoldKeyProvider).currentState?.openDrawer())
          else
            IconButton(icon: const Icon(Icons.logout), tooltip: 'Cerrar sesión', onPressed: () => ref.read(authProvider.notifier).cerrarSesion()),
          if (_camaraFoco != null)
            IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _camaraFoco = null)),
          _BotonLayout(columnas: 1, actual: _columnas, onTap: () => setState(() { _columnas = 1; _camaraFoco = null; })),
          _BotonLayout(columnas: 2, actual: _columnas, onTap: () => setState(() { _columnas = 2; _camaraFoco = null; })),
          _BotonLayout(columnas: 3, actual: _columnas, onTap: () => setState(() { _columnas = 3; _camaraFoco = null; })),
          const SizedBox(width: 4),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kPrimario)),
        error:   (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: kPeligro))),
        data: (camaras) {
          final lista = _camaraFoco != null ? [_camaraFoco!] : camaras;
          final cols  = _camaraFoco != null ? 1 : _columnas;
          return RefreshIndicator(
            color: kPrimario,
            onRefresh: () => ref.refresh(camarasProvider.future),
            child: GridView.builder(
              padding: const EdgeInsets.all(6),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 16 / 9,
              ),
              itemCount: lista.length,
              itemBuilder: (ctx, i) {
                final cam = lista[i];
                final sel = _camaraFoco?.camaraId == cam.camaraId;
                final onTap = () => setState(() {
                  _camaraFoco = _camaraFoco?.camaraId == cam.camaraId ? null : cam;
                });
                if (cam.rtspUrl.startsWith('local://')) {
                  return _CeldaCamaraLocal(key: ValueKey(cam.camaraId), camara: cam, seleccionada: sel, onTap: onTap);
                }
                return _CeldaCamara(key: ValueKey(cam.camaraId), camara: cam, seleccionada: sel, onTap: onTap);
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Celda cámara IP / RTSP normal ────────────────────────────────────────────

class _CeldaCamara extends StatefulWidget {
  final Camara       camara;
  final bool         seleccionada;
  final VoidCallback onTap;
  const _CeldaCamara({super.key, required this.camara, required this.seleccionada, required this.onTap});

  @override
  State<_CeldaCamara> createState() => _CeldaCamaraState();
}

class _CeldaCamaraState extends State<_CeldaCamara> {
  VideoPlayerController? _ctrl;
  bool _cargando = true;
  bool _error    = false;

  @override
  void initState() {
    super.initState();
    if (!widget.camara.rtspUrl.contains('/video')) {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.camara.rtspUrl))
        ..initialize().then((_) {
          _ctrl!.play();
          _ctrl!.setLooping(true);
          if (mounted) setState(() => _cargando = false);
        }).catchError((_) {
          if (mounted) setState(() { _cargando = false; _error = true; });
        });
    } else {
      _cargando = false;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kSuperficieOscura,
          border: Border.all(color: widget.seleccionada ? kPrimario : kBordeOscuro, width: widget.seleccionada ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_cargando)
                const Center(child: CircularProgressIndicator(color: kPrimario, strokeWidth: 2))
              else if (_error)
                const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.videocam_off, color: kPeligro, size: 32),
                  SizedBox(height: 6),
                  Text('Sin señal', style: TextStyle(color: kPeligro, fontSize: 11)),
                ])
              else if (widget.camara.rtspUrl.contains('/video'))
                Image.network(widget.camara.rtspUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.videocam_off, color: kPeligro))
              else if (_ctrl != null)
                VideoPlayer(_ctrl!),

              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Color(0xBF000000), Colors.transparent]),
                  ),
                  child: Text(widget.camara.nombreUbicacion,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),

              if (!_error && !_cargando)
                Positioned(
                  top: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: kPeligro.withAlpha(210), borderRadius: BorderRadius.circular(4)),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Celda cámara LOCAL (cámara trasera del dispositivo) ───────────────────────

class _CeldaCamaraLocal extends StatefulWidget {
  final Camara       camara;
  final bool         seleccionada;
  final VoidCallback onTap;
  const _CeldaCamaraLocal({super.key, required this.camara, required this.seleccionada, required this.onTap});

  @override
  State<_CeldaCamaraLocal> createState() => _CeldaCamaraLocalState();
}

class _CeldaCamaraLocalState extends State<_CeldaCamaraLocal> {
  CameraController? _ctrl;
  bool   _listo      = false;
  bool   _analizando = false;
  bool   _disposed   = false;
  Timer? _timer;
  String? _errorCamara;

  int     _conteoPersonas = 0;
  String? _nivel;          // 'normal' | 'sospechoso' | 'critico'
  Set<String> _alertasActivas = <String>{};

  @override
  void initState() {
    super.initState();
    _iniciarCamara();
  }

  Future<void> _iniciarCamara() async {
    try {
      if (mounted) {
        setState(() {
          _errorCamara = null;
          _listo = false;
        });
      }
      final camaras = await availableCameras();
      if (camaras.isEmpty || _disposed) {
        if (mounted && !_disposed) {
          setState(() => _errorCamara = 'No hay cámaras disponibles en el dispositivo');
        }
        return;
      }
      final desc = camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => camaras.first,
      );
      _ctrl = CameraController(desc, ResolutionPreset.medium, enableAudio: false);
      await _ctrl!.initialize();
      if (_disposed || !mounted) return;
      setState(() => _listo = true);
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => _analizarFrame());
    } catch (_) {
      if (mounted && !_disposed) {
        setState(() {
          _errorCamara = 'No se pudo iniciar la cámara local';
        });
      }
    }
  }

  Future<void> _analizarFrame() async {
    if (_disposed || !_listo || _analizando || _ctrl == null || !_ctrl!.value.isInitialized) return;
    _analizando = true;
    try {
      final foto  = await _ctrl!.takePicture();
      final bytes = await foto.readAsBytes();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('sivic_token') ?? '';

      final uri = Uri.parse('$urlDjango/api/camaras/${widget.camara.camaraId}/analizar_local/');
      final req = http.MultipartRequest('POST', uri);
      req.headers['Authorization'] = 'Bearer $token';
      req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'frame.jpg'));
      req.fields['umbral_merodeo'] = '15';

      final resp = await req.send().timeout(const Duration(seconds: 4));
      final bodyStr = await resp.stream.bytesToString();
      if (resp.statusCode == 200) {
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;

        // Django ya calcula conteo_personas y nivel
        final personas = body['conteo_personas'] as int? ?? 0;
        final nivel    = body['nivel']           as String? ?? 'normal';

        // alertas es lista de strings: ["merodeo", "personas_peleando", ...]
        final alertas = (body['alertas'] as List<dynamic>?) ?? [];
        final alertasSet = alertas.map((a) => a.toString()).toSet();

        if (mounted) {
          setState(() {
            _conteoPersonas = personas;
            _nivel          = nivel;
            _alertasActivas  = alertasSet;
          });
        }
      }
    } catch (_) {
      // timeout o servidor IA apagado — ignorar silenciosamente
    } finally {
      _analizando = false;
    }
  }

  Color get _colorNivel {
    switch (_nivel) {
      case 'critico':    return const Color(0xECF85149);
      case 'sospechoso': return const Color(0xECD29922);
      default:           return const Color(0xEC3FB950);
    }
  }

  String get _labelNivel {
    switch (_nivel) {
      case 'critico':    return 'CRÍTICO';
      case 'sospechoso': return 'SOSPECHOSO';
      default:           return 'NORMAL';
    }
  }

  ({String texto, Color color})? _configurarAlerta(String tipo) {
    switch (tipo) {
      case 'zona_restringida_persona':
        return (texto: 'ZONA RESTRINGIDA', color: const Color(0xECD29922));
      case 'merodeo':
        return (texto: 'MERODEO DETECTADO', color: const Color(0xECD29922));
      case 'vehiculo_zona_restringida':
        return (texto: 'VEHÍCULO EN ZONA RESTRINGIDA', color: const Color(0xECD29922));
      case 'personas_peleando':
        return (texto: 'PELEA DETECTADA', color: kPeligro);
      case 'caida_persona':
        return (texto: 'CAÍDA DETECTADA', color: kPeligro);
      case 'intrusion_nocturna':
        return (texto: 'INTRUSIÓN NOCTURNA', color: const Color(0xEC7C3AED));
      case 'acceso_fuera_horario':
        return (texto: 'ACCESO FUERA DE HORARIO', color: const Color(0xEC7C3AED));
      case 'vehiculo_mal_estacionado':
        return (texto: 'VEHÍCULO MAL ESTACIONADO', color: const Color(0xECD29922));
      case 'perro_sin_correa':
        return (texto: 'MASCOTA SUELTA', color: Colors.orange);
      case 'heces_detectadas':
        return (texto: 'HECES DETECTADAS', color: Colors.brown);
      default:
        return null;
    }
  }

  List<Widget> _bannersAlerta() {
    final orden = [
      'personas_peleando',
      'caida_persona',
      'intrusion_nocturna',
      'acceso_fuera_horario',
      'zona_restringida_persona',
      'merodeo',
      'vehiculo_zona_restringida',
      'vehiculo_mal_estacionado',
      'perro_sin_correa',
      'heces_detectadas',
    ];

    var bottom = 30.0;
    final widgets = <Widget>[];
    for (final tipo in orden) {
      if (!_alertasActivas.contains(tipo)) continue;
      final config = _configurarAlerta(tipo);
      if (config == null) continue;
      widgets.add(
        Positioned(
          bottom: bottom,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: config.color.withAlpha(230),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                config.texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
      bottom += 30;
    }
    return widgets;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final peleando = _alertasActivas.contains('personas_peleando');

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kSuperficieOscura,
          border: Border.all(
            color: peleando ? kPeligro : (widget.seleccionada ? kPrimario : kBordeOscuro),
            width: peleando || widget.seleccionada ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Preview cámara trasera
              if (_errorCamara != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam_off, color: kPeligro, size: 34),
                        const SizedBox(height: 8),
                        Text(
                          _errorCamara!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _iniciarCamara,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!_listo)
                const Center(child: CircularProgressIndicator(color: kPrimario, strokeWidth: 2))
              else
                CameraPreview(_ctrl!),

              // Nombre ubicación
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xBF000000), Colors.transparent],
                    ),
                  ),
                  child: Text(widget.camara.nombreUbicacion,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),

              // Badge LIVE
              if (_listo)
                Positioned(
                  top: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: kPeligro.withAlpha(210), borderRadius: BorderRadius.circular(4)),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ),

              // Badge personas + nivel
              if (_listo && _nivel != null)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _colorNivel,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group, color: Colors.white, size: 11),
                        const SizedBox(width: 3),
                        Text('$_conteoPersonas · $_labelNivel',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),

              ..._bannersAlerta(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Botón layout grid ─────────────────────────────────────────────────────────

class _BotonLayout extends StatelessWidget {
  final int          columnas, actual;
  final VoidCallback onTap;
  const _BotonLayout({required this.columnas, required this.actual, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activo = columnas == actual;
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        columnas == 1 ? Icons.crop_square : columnas == 2 ? Icons.grid_view : Icons.apps,
        color: activo ? kPrimario : kTexto2Oscuro,
        size: 20,
      ),
    );
  }
}
