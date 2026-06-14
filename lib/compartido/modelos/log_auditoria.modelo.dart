class LogAuditoria {
  final int logId;
  final int usuarioId;
  final String? usuarioNombre;
  final String accion;
  final String tablaAfectada;
  final String timestampAccion;

  const LogAuditoria({
    required this.logId,
    required this.usuarioId,
    this.usuarioNombre,
    required this.accion,
    required this.tablaAfectada,
    required this.timestampAccion,
  });

  factory LogAuditoria.fromJson(Map<String, dynamic> json) => LogAuditoria(
    logId:           json['log_id'] as int,
    usuarioId:       json['usuario'] as int,
    usuarioNombre:   json['usuario_nombre'] as String?,
    accion:          json['accion'] as String,
    tablaAfectada:   json['tabla_afectada'] as String,
    timestampAccion: json['timestamp_accion'] as String,
  );
}
