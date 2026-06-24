import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../nucleo/constantes/colores.dart';
import '../../nucleo/proveedores/auth_proveedor.dart';
import '../../nucleo/proveedores/shell_proveedor.dart';
import '../../nucleo/red/websocket_servicio.dart';
import 'drawer_admin.dart';

class DisenoGuardia extends ConsumerStatefulWidget {
  final Widget child;
  const DisenoGuardia({super.key, required this.child});

  @override
  ConsumerState<DisenoGuardia> createState() => _DisenoGuardiaState();
}

class _DisenoGuardiaState extends ConsumerState<DisenoGuardia> {

  @override
  void initState() {
    super.initState();
    // Escuchar nuevas alertas para mostrar banner in-app
    ref.listenManual(wsProvider, (prev, next) {
      if (next.alertas.isEmpty) return;
      final ultima = next.alertas.first;
      if (prev != null && prev.alertas.isNotEmpty && prev.alertas.first.eventoId == ultima.eventoId) return;
      if (!ultima.leida) _mostrarBanner(ultima);
    });
  }

  static const _etiquetas = {
    'mascota_suelta':           'Mascota Suelta',
    'heces_detectadas':         'Heces Detectadas',
    'persona_zona_restringida': 'Zona Restringida',
    'merodeo':                  'Merodeo Detectado',
    'vehiculo_no_autorizado':   'Vehículo No Autorizado',
    'bloqueo_vehicular':        'Vehículo Mal Estacionado',
    'personas_peleando':        'Pelea Detectada',
    'caida_persona':            'Caída de Persona',
    'intrusion_nocturna':       'Intrusión Nocturna',
    'acceso_fuera_horario':     'Acceso Fuera de Horario',
    'acceso_no_autorizado':     'Acceso No Autorizado',
  };

  void _mostrarBanner(AlertaWS alerta) {
    if (!mounted) return;
    final etiqueta = _etiquetas[alerta.reglaNombre] ?? alerta.reglaNombre;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: kPeligro,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(alerta.camaraNombre,
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            Text('${(alerta.confianzaIa * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            ref.read(wsProvider.notifier).marcarLeida(alerta.eventoId);
            context.go('/eventos');
          },
        ),
      ),
    );
  }

  int _indiceActual(BuildContext context, bool esAdmin) {
    final location = GoRouterState.of(context).matchedLocation;
    if (esAdmin) {
      if (location.startsWith('/dashboard'))      return 0;
      if (location.startsWith('/camaras'))        return 1;
      if (location.startsWith('/eventos'))        return 2;
      if (location.startsWith('/notificaciones')) return 3;
      return 0;
    }
    if (location.startsWith('/camaras'))        return 0;
    if (location.startsWith('/eventos'))        return 1;
    if (location.startsWith('/notificaciones')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final usuario   = ref.watch(authProvider).usuario;
    final esAdmin   = usuario?.esAdmin ?? false;
    final wsEstado  = ref.watch(wsProvider);
    final noLeidas  = wsEstado.noLeidas;
    final esOscuro  = Theme.of(context).brightness == Brightness.dark;
    final colorFondoNav = esOscuro ? kSuperficieOscura : kSuperficieClara;
    final colorTexto2   = esOscuro ? kTexto2Oscuro : kTexto2Claro;

    Widget iconoAlertas(bool seleccionado) => Badge.count(
      count: noLeidas,
      isLabelVisible: noLeidas > 0,
      backgroundColor: kPeligro,
      child: Icon(
        seleccionado ? Icons.notifications : Icons.notifications_outlined,
        color: seleccionado ? kPrimario : colorTexto2,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final scaffold = ref.read(shellScaffoldKeyProvider).currentState;
        if (scaffold?.isDrawerOpen ?? false) {
          scaffold!.closeDrawer();
          return;
        }
        final accion = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Salir'),
            content: const Text('¿Qué deseas hacer?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, null),        child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, 'salir'),     child: const Text('Salir')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'logout'),
                child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (accion == 'logout') {
          await ref.read(authProvider.notifier).cerrarSesion();
        } else if (accion == 'salir') {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: ref.watch(shellScaffoldKeyProvider),
        drawer: (esAdmin && usuario != null) ? DrawerAdmin(usuario: usuario) : null,
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          backgroundColor: colorFondoNav,
          indicatorColor: kPrimario.withAlpha(50),
          selectedIndex: _indiceActual(context, esAdmin),
          onDestinationSelected: (i) {
            if (esAdmin) {
              switch (i) {
                case 0: context.go('/dashboard');      break;
                case 1: context.go('/camaras');        break;
                case 2: context.go('/eventos');        break;
                case 3: context.go('/notificaciones'); break;
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
                    icon:         Icon(Icons.dashboard_outlined, color: colorTexto2),
                    selectedIcon: const Icon(Icons.dashboard, color: kPrimario),
                    label: 'Panel',
                  ),
                  NavigationDestination(
                    icon:         Icon(Icons.videocam_outlined, color: colorTexto2),
                    selectedIcon: const Icon(Icons.videocam, color: kPrimario),
                    label: 'Cámaras',
                  ),
                  NavigationDestination(
                    icon:         iconoAlertas(false),
                    selectedIcon: iconoAlertas(true),
                    label: 'Eventos',
                  ),
                  NavigationDestination(
                    icon:         Icon(Icons.mail_outline, color: colorTexto2),
                    selectedIcon: const Icon(Icons.mail, color: kPrimario),
                    label: 'Avisos',
                  ),
                ]
              : [
                  NavigationDestination(
                    icon:         Icon(Icons.videocam_outlined, color: colorTexto2),
                    selectedIcon: const Icon(Icons.videocam, color: kPrimario),
                    label: 'Cámaras',
                  ),
                  NavigationDestination(
                    icon:         iconoAlertas(false),
                    selectedIcon: iconoAlertas(true),
                    label: 'Eventos',
                  ),
                  NavigationDestination(
                    icon:         Icon(Icons.mail_outline, color: colorTexto2),
                    selectedIcon: const Icon(Icons.mail, color: kPrimario),
                    label: 'Avisos',
                  ),
                ],
        ),
      ),
    );
  }
}
