import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../nucleo/constantes/colores.dart';
import '../../nucleo/proveedores/auth_proveedor.dart';
import '../../nucleo/proveedores/shell_proveedor.dart';
import 'drawer_admin.dart';

class DisenoGuardia extends ConsumerWidget {
  final Widget child;
  const DisenoGuardia({super.key, required this.child});

  int _indiceActual(BuildContext context, bool esAdmin) {
    final location = GoRouterState.of(context).matchedLocation;
    if (esAdmin) {
      if (location.startsWith('/dashboard')) return 0;
      if (location.startsWith('/camaras'))   return 1;
      if (location.startsWith('/eventos'))   return 2;
      return 0;
    }
    if (location.startsWith('/camaras'))        return 0;
    if (location.startsWith('/eventos'))        return 1;
    if (location.startsWith('/notificaciones')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authProvider).usuario;
    final esAdmin = usuario?.esAdmin ?? false;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorFondoNav = esOscuro ? kSuperficieOscura : kSuperficieClara;
    final colorTexto2   = esOscuro ? kTexto2Oscuro : kTexto2Claro;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final scaffold = ref.read(shellScaffoldKeyProvider).currentState;
        if (scaffold?.isDrawerOpen ?? false) {
          scaffold!.closeDrawer();
          return;
        }
        final salir = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Salir'),
            content: const Text('¿Deseas salir de la aplicación?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
            ],
          ),
        );
        if (salir ?? false) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: ref.watch(shellScaffoldKeyProvider),
        drawer: (esAdmin && usuario != null) ? DrawerAdmin(usuario: usuario) : null,
        body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: colorFondoNav,
        indicatorColor: kPrimario.withAlpha(50),
        selectedIndex: _indiceActual(context, esAdmin),
        onDestinationSelected: (i) {
          if (esAdmin) {
            switch (i) {
              case 0: context.go('/dashboard'); break;
              case 1: context.go('/camaras');   break;
              case 2: context.go('/eventos');   break;
            }
          } else {
            switch (i) {
              case 0: context.go('/camaras');        break;
              case 1: context.go('/eventos');        break;
              case 2: context.go('/notificaciones'); break;
            }
          }
        },
        destinations: esAdmin
            ? [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined, color: colorTexto2),
                  selectedIcon: const Icon(Icons.dashboard, color: kPrimario),
                  label: 'Panel',
                ),
                NavigationDestination(
                  icon: Icon(Icons.videocam_outlined, color: colorTexto2),
                  selectedIcon: const Icon(Icons.videocam, color: kPrimario),
                  label: 'Cámaras',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined, color: colorTexto2),
                  selectedIcon: const Icon(Icons.notifications, color: kPrimario),
                  label: 'Eventos',
                ),
              ]
            : [
                NavigationDestination(
                  icon: Icon(Icons.videocam_outlined, color: colorTexto2),
                  selectedIcon: const Icon(Icons.videocam, color: kPrimario),
                  label: 'Cámaras',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined, color: colorTexto2),
                  selectedIcon: const Icon(Icons.notifications, color: kPrimario),
                  label: 'Eventos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.mail_outline, color: colorTexto2),
                  selectedIcon: const Icon(Icons.mail, color: kPrimario),
                  label: 'Avisos',
                ),
              ],
        ),
      ),
    );
  }
}
