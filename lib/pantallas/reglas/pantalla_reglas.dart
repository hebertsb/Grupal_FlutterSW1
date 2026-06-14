import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../nucleo/constantes/colores.dart';
import '../../nucleo/proveedores/reglas_proveedor.dart';
import '../../nucleo/proveedores/auth_proveedor.dart';
import '../../nucleo/proveedores/shell_proveedor.dart';
import '../../compartido/modelos/regla.modelo.dart';

class PantallaReglas extends ConsumerWidget {
  const PantallaReglas({super.key});

  String _mensajeError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        return data.values.expand((v) => v is List ? v : [v]).join(', ');
      }
    }
    return 'Error: $e';
  }

  Future<void> _abrirFormulario(BuildContext context, WidgetRef ref, {Regla? regla}) async {
    final nombreCtrl = TextEditingController(text: regla?.nombreRegla ?? '');
    final descCtrl   = TextEditingController(text: regla?.descripcion ?? '');
    final formKey    = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(regla == null ? 'Nueva regla' : 'Editar regla'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) Navigator.pop(ctx, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardar != true) return;

    final datos = {
      'nombre_regla': nombreCtrl.text.trim(),
      'descripcion':  descCtrl.text.trim(),
    };

    try {
      final http = ref.read(httpProvider);
      if (regla == null) {
        await http.post('/reglas/', data: datos);
      } else {
        await http.patch('/reglas/${regla.reglaId}/', data: datos);
      }
      ref.invalidate(reglasProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_mensajeError(e))));
      }
    }
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref, Regla regla) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar regla'),
        content: Text('¿Eliminar "${regla.nombreRegla}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await ref.read(httpProvider).delete('/reglas/${regla.reglaId}/');
      ref.invalidate(reglasProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_mensajeError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reglas = ref.watch(reglasProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(padding: const EdgeInsets.all(8), child: Image.asset('assets/icon/icon.png')),
        title: const Text('Reglas IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(reglasProvider.future),
        child: reglas.when(
          data: (lista) => lista.isEmpty
              ? const Center(child: Text('Sin reglas configuradas'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = lista[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.rule),
                        title: Text(r.nombreRegla),
                        subtitle: (r.descripcion != null && r.descripcion!.isNotEmpty) ? Text(r.descripcion!) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Editar',
                              onPressed: () => _abrirFormulario(context, ref, regla: r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: kPeligro),
                              tooltip: 'Eliminar',
                              onPressed: () => _eliminar(context, ref, r),
                            ),
                          ],
                        ),
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
