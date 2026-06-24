import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'nucleo/temas/tema.dart';
import 'nucleo/proveedores/tema_proveedor.dart';
import 'nucleo/proveedores/auth_proveedor.dart';
import 'nucleo/rutas/rutas_app.dart';

@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // FCM muestra la notificación del sistema automáticamente en background/killed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
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
    Future.microtask(() async {
      await ref.read(authProvider.notifier).cargarSesionGuardada();
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    });
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
