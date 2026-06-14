import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_proveedor.dart';
import '../../compartido/modelos/log_auditoria.modelo.dart';

final auditoriaProvider = FutureProvider<List<LogAuditoria>>((ref) async {
  final http = ref.read(httpProvider);
  final resp = await http.get('/auditoria/logs/');
  return (resp.data as List).map((e) => LogAuditoria.fromJson(e as Map<String, dynamic>)).toList();
});
