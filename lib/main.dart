import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nucleo/temas/tema.dart';
import 'nucleo/proveedores/tema_proveedor.dart';
import 'nucleo/proveedores/auth_proveedor.dart';
import 'nucleo/rutas/rutas_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AppSivic()));
}

class AppSivic extends ConsumerStatefulWidget {
  const AppSivic({super.key});

  @override
  ConsumerState<AppSivic> createState() => _AppSivicState();
}

class _AppSivicState extends ConsumerState<AppSivic> {
  @override
  void initState() {
    super.initState();
    // Carga sesión guardada al iniciar (una sola vez)
    Future.microtask(() => ref.read(authProvider.notifier).cargarSesionGuardada());
  }

  @override
  Widget build(BuildContext context) {
    final modoTema = ref.watch(temaProvider);
    final router   = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SIVIC Guardia',
      debugShowCheckedModeBanner: false,
      themeMode:   modoTema,
      theme:       temaClaro(),
      darkTheme:   temaOscuro(),
      routerConfig: router,
    );
  }
}
