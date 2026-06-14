class NotificacionApp {
  final int notificacionId;
  final int? eventoId;
  final String? eventoTipo;
  final int usuarioId;
  final String titulo;
  final String? cuerpo;
  final String estado;
  final String createdAt;

  const NotificacionApp({
    required this.notificacionId,
    this.eventoId,
    this.eventoTipo,
    required this.usuarioId,
    required this.titulo,
    this.cuerpo,
    required this.estado,
    required this.createdAt,
  });

  factory NotificacionApp.fromJson(Map<String, dynamic> json) => NotificacionApp(
    notificacionId: json['notificacion_id'] as int,
    eventoId:       json['evento'] as int?,
    eventoTipo:     json['evento_tipo'] as String?,
    usuarioId:      json['usuario'] as int,
    titulo:         json['titulo'] as String,
    cuerpo:         json['cuerpo'] as String?,
    estado:         json['estado'] as String,
    createdAt:      json['created_at'] as String,
  );

  bool get leida => estado == 'leida';
}
