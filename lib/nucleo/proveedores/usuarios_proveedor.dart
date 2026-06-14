import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_proveedor.dart';
import '../../compartido/modelos/usuario.modelo.dart';

final usuariosProvider = FutureProvider<List<Usuario>>((ref) async {
  final http = ref.read(httpProvider);
  final resp = await http.get('/auth/usuarios/');
  return (resp.data as List).map((e) => Usuario.fromJson(e as Map<String, dynamic>)).toList();
});
