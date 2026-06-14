import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../nucleo/proveedores/auditoria_proveedor.dart';
import '../../nucleo/proveedores/shell_proveedor.dart';

class PantallaAuditoria extends ConsumerWidget {
  const PantallaAuditoria({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(auditoriaProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(padding: const EdgeInsets.all(8), child: Image.asset('assets/icon/icon.png')),
        title: const Text('Auditoría'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(auditoriaProvider.future),
        child: logs.when(
          data: (lista) => lista.isEmpty
              ? const Center(child: Text('Sin registros de auditoría'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final log = lista[i];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(log.accion),
                      subtitle: Text('${log.usuarioNombre ?? 'Usuario #${log.usuarioId}'} · ${log.tablaAfectada}'),
                      trailing: Text(log.timestampAccion.substring(0, 16).replaceFirst('T', ' ')),
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
