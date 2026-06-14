import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../nucleo/constantes/colores.dart';
import '../../nucleo/proveedores/auth_proveedor.dart';
import '../../nucleo/proveedores/tema_proveedor.dart';
import '../modelos/usuario.modelo.dart';

class DrawerAdmin extends ConsumerWidget {
  final Usuario usuario;
  const DrawerAdmin({super.key, required this.usuario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modoTema = ref.watch(temaProvider);
    final esOscuro = modoTema == ThemeMode.dark;
    final location = GoRouterState.of(context).matchedLocation;

    void ir(String ruta) {
      Navigator.of(context).pop();
      context.go(ruta);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  Image.asset('assets/icon/icon.png', width: 48, height: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(usuario.nombre, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                        Text(usuario.email, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _Item(icono: Icons.dashboard_outlined,         etiqueta: 'Panel Principal', ruta: '/dashboard',      actual: location, onTap: ir),
                  _Item(icono: Icons.videocam_outlined,          etiqueta: 'Cámaras',         ruta: '/camaras',        actual: location, onTap: ir),
                  _Item(icono: Icons.notification_important_outlined, etiqueta: 'Eventos',    ruta: '/eventos',        actual: location, onTap: ir),
                  _Item(icono: Icons.rule_outlined,              etiqueta: 'Reglas IA',       ruta: '/reglas',         actual: location, onTap: ir),
                  _Item(icono: Icons.fact_check_outlined,        etiqueta: 'Auditoría',       ruta: '/auditoria',      actual: location, onTap: ir),
                  _Item(icono: Icons.people_outline,             etiqueta: 'Usuarios',        ruta: '/usuarios',       actual: location, onTap: ir),
                  _Item(icono: Icons.mail_outline,               etiqueta: 'Notificaciones',  ruta: '/notificaciones', actual: location, onTap: ir),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(esOscuro ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
              title: Text(esOscuro ? 'Modo oscuro' : 'Modo claro'),
              trailing: Switch(
                value: esOscuro,
                activeThumbColor: kPrimario,
                onChanged: (v) => ref.read(temaProvider.notifier).state = v ? ThemeMode.dark : ThemeMode.light,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: kPeligro),
              title: const Text('Cerrar sesión', style: TextStyle(color: kPeligro)),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).cerrarSesion();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String ruta;
  final String actual;
  final void Function(String) onTap;

  const _Item({required this.icono, required this.etiqueta, required this.ruta, required this.actual, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activo = actual.startsWith(ruta);
    return ListTile(
      leading: Icon(icono, color: activo ? kPrimario : null),
      title: Text(etiqueta, style: activo ? const TextStyle(color: kPrimario, fontWeight: FontWeight.w600) : null),
      selected: activo,
      onTap: () => onTap(ruta),
    );
  }
}
