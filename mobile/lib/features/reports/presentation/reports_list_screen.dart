import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/error_view.dart';
import '../../notifications/presentation/notificaciones_providers.dart';
import '../../notifications/presentation/notificaciones_screen.dart';
import 'create_report_screen.dart';
import 'report_detail_screen.dart';
import 'reportes_providers.dart';

enum _FiltroTipo { todos, perdidas, avistamientos, tuyos }

class ReportsListScreen extends ConsumerWidget {
  const ReportsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noLeidas = ref.watch(notificacionesNoLeidasProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes'),
          actions: [
            IconButton(
              icon: Badge(
                label: Text('$noLeidas'),
                isLabelVisible: noLeidas > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
              tooltip: 'Notificaciones',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificacionesScreen()),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reportes cercanos'),
              Tab(text: 'Mis mascotas perdidas'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateReportScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Reportar'),
        ),
        body: const TabBarView(
          children: [
            _AvistamientosTab(),
            _MisMascotasPerdidasTab(),
          ],
        ),
      ),
    );
  }
}

class _AvistamientosTab extends ConsumerStatefulWidget {
  const _AvistamientosTab();

  @override
  ConsumerState<_AvistamientosTab> createState() => _AvistamientosTabState();
}

class _AvistamientosTabState extends ConsumerState<_AvistamientosTab> {
  bool _locating = false;
  _FiltroTipo _filtro = _FiltroTipo.todos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _usarUbicacionActual());
  }

  Future<void> _usarUbicacionActual() async {
    setState(() => _locating = true);
    try {
      final position = await ref.read(locationServiceProvider).obtenerUbicacionActual();
      ref.read(busquedaCercaniaProvider.notifier).state = BusquedaCercania(
        lat: position.latitude,
        lng: position.longitude,
      );
    } on LocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportesAsync = ref.watch(reportesCercanosProvider);
    final miUid = ref.watch(firebaseAuthProvider).currentUser?.uid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _locating ? null : _usarUbicacionActual,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Usar mi ubicación actual'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _filtro == _FiltroTipo.todos,
                  onSelected: (_) => setState(() => _filtro = _FiltroTipo.todos),
                ),
                ChoiceChip(
                  label: const Text('Perdidas'),
                  selected: _filtro == _FiltroTipo.perdidas,
                  onSelected: (_) => setState(() => _filtro = _FiltroTipo.perdidas),
                ),
                ChoiceChip(
                  label: const Text('Avistamientos'),
                  selected: _filtro == _FiltroTipo.avistamientos,
                  onSelected: (_) => setState(() => _filtro = _FiltroTipo.avistamientos),
                ),
                ChoiceChip(
                  label: const Text('Tuyos'),
                  selected: _filtro == _FiltroTipo.tuyos,
                  onSelected: (_) => setState(() => _filtro = _FiltroTipo.tuyos),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: reportesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorView(
              onRetry: () => ref.invalidate(reportesCercanosProvider),
            ),
            data: (reportes) {
              // Las mascotas perdidas propias ya se ven en la pestaña "Mis
              // mascotas perdidas" (con su conteo de coincidencias) — se
              // excluyen aquí para no duplicarlas.
              final cercanos = reportes
                  .where((r) => !(r.esPerdida && r.creadoPor == miUid))
                  .where((r) => switch (_filtro) {
                        _FiltroTipo.todos => true,
                        _FiltroTipo.perdidas => r.esPerdida,
                        _FiltroTipo.avistamientos => !r.esPerdida,
                        _FiltroTipo.tuyos => r.creadoPor == miUid,
                      })
                  .toList();
              if (cercanos.isEmpty) {
                return Center(
                  child: Text(
                    _filtro == _FiltroTipo.tuyos
                        ? 'No tienes avistamientos reportados por aquí'
                        : 'Ingresa una ubicación y busca reportes cerca',
                  ),
                );
              }
              return ListView.builder(
                itemCount: cercanos.length,
                itemBuilder: (context, index) {
                  final reporte = cercanos[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(reporte.fotoUrl),
                    ),
                    title: Text(
                      reporte.mascota.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${reporte.mascota.especie} · ${reporte.mascota.color} · '
                      '${reporte.distanciaKm?.toStringAsFixed(1) ?? "?"} km',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: _BadgeTipoReporte(esPerdida: reporte.esPerdida),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportDetailScreen(reporteId: reporte.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BadgeTipoReporte extends StatelessWidget {
  const _BadgeTipoReporte({required this.esPerdida});

  final bool esPerdida;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      texto: esPerdida ? 'Perdida' : 'Avistamiento',
      color: esPerdida ? Colors.red : Theme.of(context).colorScheme.primary,
    );
  }
}

class _MisMascotasPerdidasTab extends ConsumerWidget {
  const _MisMascotasPerdidasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportesAsync = ref.watch(misReportesPerdidosProvider);

    return reportesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorView(
        onRetry: () => ref.invalidate(misReportesPerdidosProvider),
      ),
      data: (reportes) {
        if (reportes.isEmpty) {
          return const Center(
            child: Text('Aún no has reportado ninguna mascota perdida'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(misReportesPerdidosProvider),
          child: ListView.builder(
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              final reporte = reportes[index];
              final coincidencias = reporte.coincidenciasCount ?? 0;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(reporte.fotoUrl),
                ),
                title: Text(reporte.mascota.nombre),
                subtitle: Text(
                    '${reporte.mascota.especie} · ${reporte.mascota.color} · ${reporte.estado}'),
                trailing: coincidencias > 0
                    ? Chip(
                        label: Text(
                          coincidencias == 1
                              ? '1 coincidencia'
                              : '$coincidencias coincidencias',
                        ),
                        backgroundColor: Colors.amber.shade100,
                      )
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(reporteId: reporte.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
