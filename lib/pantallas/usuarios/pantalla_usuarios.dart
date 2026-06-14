import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../nucleo/constantes/colores.dart';
import '../../nucleo/proveedores/usuarios_proveedor.dart';
import '../../nucleo/proveedores/shell_proveedor.dart';

class PantallaUsuarios extends ConsumerWidget {
  const PantallaUsuarios({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarios = ref.watch(usuariosProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(padding: const EdgeInsets.all(8), child: Image.asset('assets/icon/icon.png')),
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(usuariosProvider.future),
        child: usuarios.when(
          data: (lista) => lista.isEmpty
              ? const Center(child: Text('Sin usuarios'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final u = lista[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: u.esAdmin ? kPrimario : kExito,
                          child: Icon(u.esAdmin ? Icons.admin_panel_settings : Icons.shield, color: Colors.white),
                        ),
                        title: Text(u.nombre),
                        subtitle: Text(u.email),
                        trailing: Text(u.rol),
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
