import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../proveedores/auth_proveedor.dart';
import '../../pantallas/login/pantalla_login.dart';
import '../../pantallas/camaras/pantalla_camaras.dart';
import '../../pantallas/eventos/pantalla_eventos.dart';
import '../../pantallas/dashboard/pantalla_dashboard.dart';
import '../../pantallas/reglas/pantalla_reglas.dart';
import '../../pantallas/auditoria/pantalla_auditoria.dart';
import '../../pantallas/usuarios/pantalla_usuarios.dart';
import '../../pantallas/notificaciones/pantalla_notificaciones.dart';
import '../../compartido/widgets/diseno_guardia.dart';

const _rutasAdmin = ['/dashboard', '/reglas', '/auditoria', '/usuarios'];

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  final esAdmin = auth.usuario?.esAdmin ?? false;

  return GoRouter(
    initialLocation: esAdmin ? '/dashboard' : '/camaras',
    redirect: (context, state) {
      final autenticado = auth.autenticado;
      final enLogin     = state.matchedLocation == '/login';
      if (!autenticado && !enLogin) return '/login';
      if (autenticado  &&  enLogin) return esAdmin ? '/dashboard' : '/camaras';
      if (autenticado && !esAdmin && _rutasAdmin.any((r) => state.matchedLocation.startsWith(r))) {
        return '/camaras';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const PantallaLogin()),
      ShellRoute(
        builder: (context, state, child) => DisenoGuardia(child: child),
        routes: [
          GoRoute(path: '/dashboard',      builder: (_, __) => const PantallaDashboard()),
          GoRoute(path: '/camaras',        builder: (_, __) => const PantallaCamaras()),
          GoRoute(path: '/eventos',        builder: (_, __) => const PantallaEventos()),
          GoRoute(path: '/reglas',         builder: (_, __) => const PantallaReglas()),
          GoRoute(path: '/auditoria',      builder: (_, __) => const PantallaAuditoria()),
          GoRoute(path: '/usuarios',       builder: (_, __) => const PantallaUsuarios()),
          GoRoute(path: '/notificaciones', builder: (_, __) => const PantallaNotificaciones()),
        ],
      ),
    ],
  );
});
