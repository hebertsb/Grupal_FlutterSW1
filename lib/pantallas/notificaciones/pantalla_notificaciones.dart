import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../nucleo/constantes/colores.dart';
import '../../nucleo/proveedores/notificaciones_proveedor.dart';
import '../../nucleo/proveedores/auth_proveedor.dart';
import '../../nucleo/proveedores/shell_proveedor.dart';

class PantallaNotificaciones extends ConsumerWidget {
  const PantallaNotificaciones({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificacionesProvider);
    final esAdmin = ref.watch(authProvider).usuario?.esAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(padding: const EdgeInsets.all(8), child: Image.asset('assets/icon/icon.png')),
        title: const Text('Notificaciones'),
        actions: [
          if (esAdmin)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () => ref.read(authProvider.notifier).cerrarSesion(),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificacionesProvider.future),
        child: notifs.when(
          data: (lista) => lista.isEmpty
              ? const Center(child: Text('Sin notificaciones'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = lista[i];
                    return Card(
                      color: n.leida ? null : kPrimario.withAlpha(20),
                      child: ListTile(
                        leading: Icon(n.leida ? Icons.notifications_none : Icons.notifications_active, color: n.leida ? null : kPrimario),
                        title: Text(n.titulo, style: TextStyle(fontWeight: n.leida ? FontWeight.normal : FontWeight.w700)),
                        subtitle: Text(n.cuerpo ?? ''),
                        trailing: Text(n.createdAt.substring(0, 16).replaceFirst('T', ' ')),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
