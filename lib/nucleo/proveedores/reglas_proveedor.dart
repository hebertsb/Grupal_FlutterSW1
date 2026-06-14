import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_proveedor.dart';
import '../../compartido/modelos/regla.modelo.dart';

final reglasProvider = FutureProvider<List<Regla>>((ref) async {
  final http = ref.read(httpProvider);
  final resp = await http.get('/reglas/');
  return (resp.data as List).map((e) => Regla.fromJson(e as Map<String, dynamic>)).toList();
});
