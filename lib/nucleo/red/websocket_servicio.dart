import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const String _wsBase = 'ws://98.93.156.209';

// ── Modelo de alerta recibida por WS ─────────────────────────────────────────

class AlertaWS {
  final int    eventoId;
  final String camaraNombre;
  final String reglaNombre;
  final double confianzaIa;
  final String timestamp;
  final String imagenUrl;
  bool leida;

  AlertaWS({
    required this.eventoId,
    required this.camaraNombre,
    required this.reglaNombre,
    required this.confianzaIa,
    required this.timestamp,
    this.imagenUrl = '',
    this.leida = false,
  });

  factory AlertaWS.fromJson(Map<String, dynamic> j) => AlertaWS(
    eventoId:     j['evento_id'] as int,
    camaraNombre: j['camara_nombre'] as String? ?? '',
    reglaNombre:  j['regla_nombre']  as String? ?? '',
    confianzaIa:  (j['confianza_ia'] as num).toDouble(),
    timestamp:    j['timestamp']     as String? ?? '',
    imagenUrl:    j['imagen_url']    as String? ?? '',
  );
}

// ── Estado ───────────────────────────────────────────────────────────────────

class EstadoWS {
  final List<AlertaWS> alertas;
  final bool           conectado;

  const EstadoWS({this.alertas = const [], this.conectado = false});

  int get noLeidas => alertas.where((a) => !a.leida).length;

  EstadoWS copyWith({List<AlertaWS>? alertas, bool? conectado}) => EstadoWS(
    alertas:   alertas   ?? this.alertas,
    conectado: conectado ?? this.conectado,
  );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class WebSocketNotifier extends StateNotifier<EstadoWS> {
  WebSocketChannel?          _channel;
  StreamSubscription<dynamic>? _sub;
  Timer?                     _reconectar;
  String                     _token = '';

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  WebSocketNotifier() : super(const EstadoWS()) {
    _initLocalNotif();
  }

  void _initLocalNotif() {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    _localNotif.initialize(const InitializationSettings(android: android));
  }

  void conectar(String token) {
    if (token.isEmpty || _channel != null) return;
    _token = token;
    _abrir();
  }

  void _abrir() {
    try {
      final uri = Uri.parse('$_wsBase/ws/alertas/?token=$_token');
      _channel = WebSocketChannel.connect(uri);
      state = state.copyWith(conectado: true);

      _sub = _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            if (json['tipo'] == 'alerta') {
              final alerta = AlertaWS.fromJson(json);
              state = state.copyWith(
                alertas: [alerta, ...state.alertas].take(50).toList(),
              );
              _mostrarNotifLocal(alerta);
            }
          } catch (_) {}
        },
        onError: (_) => _programarReconexion(),
        onDone:  ()  => _programarReconexion(),
      );
    } catch (_) {
      _programarReconexion();
    }
  }

  void _programarReconexion() {
    _cerrarCanal();
    state = state.copyWith(conectado: false);
    _reconectar = Timer(const Duration(seconds: 5), () {
      if (_token.isNotEmpty) _abrir();
    });
  }

  void _cerrarCanal() {
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  void desconectar() {
    _reconectar?.cancel();
    _cerrarCanal();
    state = const EstadoWS();
    _token = '';
  }

  void marcarLeida(int eventoId) {
    state = state.copyWith(
      alertas: state.alertas.map((a) {
        if (a.eventoId == eventoId) a.leida = true;
        return a;
      }).toList(),
    );
  }

  void marcarTodasLeidas() {
    for (final a in state.alertas) { a.leida = true; }
    state = state.copyWith(alertas: List.from(state.alertas));
  }

  static const _etiquetas = {
    'mascota_suelta':           'Mascota Suelta',
    'heces_detectadas':         'Heces Detectadas',
    'persona_zona_restringida': 'Zona Restringida',
    'merodeo':                  'Merodeo Detectado',
    'vehiculo_no_autorizado':   'Vehículo No Autorizado',
    'bloqueo_vehicular':        'Vehículo Mal Estacionado',
    'personas_peleando':        'Pelea Detectada',
    'caida_persona':            'Caída de Persona',
    'intrusion_nocturna':       'Intrusión Nocturna',
    'acceso_fuera_horario':     'Acceso Fuera de Horario',
    'acceso_no_autorizado':     'Acceso No Autorizado',
  };

  void _mostrarNotifLocal(AlertaWS alerta) {
    final etiqueta = _etiquetas[alerta.reglaNombre] ?? alerta.reglaNombre;
    _localNotif.show(
      alerta.eventoId,
      '⚠ $etiqueta',
      '${alerta.camaraNombre} • ${(alerta.confianzaIa * 100).toStringAsFixed(0)}% confianza',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sivic_alertas',
          'Alertas SIVIC',
          channelDescription: 'Notificaciones de detección IA',
          importance: Importance.high,
          priority:   Priority.high,
          playSound:  true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    desconectar();
    super.dispose();
  }
}

// ── Provider global ───────────────────────────────────────────────────────────

final wsProvider = StateNotifierProvider<WebSocketNotifier, EstadoWS>(
  (ref) => WebSocketNotifier(),
);
