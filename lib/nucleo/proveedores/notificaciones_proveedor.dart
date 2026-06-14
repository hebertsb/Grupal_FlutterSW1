import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_proveedor.dart';
import '../../compartido/modelos/notificacion.modelo.dart';

final notificacionesProvider = FutureProvider<List<NotificacionApp>>((ref) async {
  final http = ref.read(httpProvider);
  final resp = await http.get('/notificaciones/historial/');
  return (resp.data as List).map((e) => NotificacionApp.fromJson(e as Map<String, dynamic>)).toList();
});
