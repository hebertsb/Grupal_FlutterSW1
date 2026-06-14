class Regla {
  final int reglaId;
  final String nombreRegla;
  final String? descripcion;

  const Regla({required this.reglaId, required this.nombreRegla, this.descripcion});

  factory Regla.fromJson(Map<String, dynamic> json) => Regla(
    reglaId:     json['regla_id'] as int,
    nombreRegla: json['nombre_regla'] as String,
    descripcion: json['descripcion'] as String?,
  );
}
