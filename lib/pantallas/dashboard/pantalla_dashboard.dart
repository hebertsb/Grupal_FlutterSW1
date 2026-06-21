import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../nucleo/constantes/colores.dart';
import '../../nucleo/proveedores/camaras_proveedor.dart';
import '../../nucleo/proveedores/eventos_proveedor.dart';
import '../../nucleo/proveedores/reglas_proveedor.dart';
import '../../nucleo/proveedores/usuarios_proveedor.dart';
import '../../nucleo/proveedores/shell_proveedor.dart';

String _fmtBolivia(String ts) {
  try {
    final utc = DateTime.parse(ts).toUtc();
    final bolivia = utc.subtract(const Duration(hours: 4));
    return '${bolivia.year}-${bolivia.month.toString().padLeft(2,'0')}-${bolivia.day.toString().padLeft(2,'0')} '
           '${bolivia.hour.toString().padLeft(2,'0')}:${bolivia.minute.toString().padLeft(2,'0')}';
  } catch (_) {
    return ts.length >= 16 ? ts.substring(0, 16).replaceFirst('T', ' ') : ts;
  }
}

class PantallaDashboard extends ConsumerWidget {
  const PantallaDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camaras    = ref.watch(camarasProvider);
    final pendientes = ref.watch(eventosProvider('pendiente'));
    final eventos    = ref.watch(eventosProvider(null));
    final usuarios   = ref.watch(usuariosProvider);
    final reglas     = ref.watch(reglasProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(padding: const EdgeInsets.all(8), child: Image.asset('assets/icon/icon.png')),
        title: const Text('Panel Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.refresh(camarasProvider.future),
          ref.refresh(eventosProvider(null).future),
          ref.refresh(eventosProvider('pendiente').future),
          ref.refresh(usuariosProvider.future),
          ref.refresh(reglasProvider.future),
        ]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _TarjetaStat(titulo: 'Cámaras activas',    valor: camaras.maybeWhen(data: (l) => '${l.length}', orElse: () => '—'),    icono: Icons.videocam,     color: kPrimario),
                _TarjetaStat(titulo: 'Eventos pendientes', valor: pendientes.maybeWhen(data: (l) => '${l.length}', orElse: () => '—'), icono: Icons.warning_amber, color: kAdvertencia),
                _TarjetaStat(titulo: 'Usuarios',           valor: usuarios.maybeWhen(data: (l) => '${l.length}', orElse: () => '—'),   icono: Icons.people,       color: kExito),
                _TarjetaStat(titulo: 'Reglas IA',          valor: reglas.maybeWhen(data: (l) => '${l.length}', orElse: () => '—'),     icono: Icons.rule,         color: kPeligro),
              ],
            ),
            const SizedBox(height: 24),
            Text('Eventos recientes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            eventos.when(
              data: (lista) => lista.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Sin eventos registrados')),
                    )
                  : Column(
                      children: lista.take(5).map((e) => Card(
                        child: ListTile(
                          leading: Icon(_iconoEstado(e.estado), color: _colorEstado(e.estado)),
                          title: Text(e.reglaNombre ?? 'Regla #${e.reglaId}'),
                          subtitle: Text('${e.camaraNombre ?? 'Cámara #${e.camaraId}'} · ${_fmtBolivia(e.timestampDeteccion)}'),
                          trailing: Text(e.estado.replaceAll('_', ' ')),
                          onTap: () => context.go('/eventos'),
                        ),
                      )).toList(),
                    ),
              loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconoEstado(String estado) => switch (estado) {
    'pendiente'    => Icons.warning_amber,
    'en_atencion'  => Icons.hourglass_top,
    'resuelto'     => Icons.check_circle,
    'falsa_alarma' => Icons.block,
    _              => Icons.help_outline,
  };

  Color _colorEstado(String estado) => switch (estado) {
    'pendiente'    => kAdvertencia,
    'en_atencion'  => kPrimario,
    'resuelto'     => kExito,
    _              => kTexto2Oscuro,
  };
}

class _TarjetaStat extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _TarjetaStat({required this.titulo, required this.valor, required this.icono, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icono, color: color, size: 28),
            const Spacer(),
            Text(valor, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(titulo, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
