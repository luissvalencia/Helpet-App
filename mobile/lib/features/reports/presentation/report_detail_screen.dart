import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/config/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/info_tile.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/coincidencia.dart';
import 'edit_report_screen.dart';
import 'reportes_providers.dart';
import 'widgets/coincidencia_card.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen({
    super.key,
    required this.reporteId,
    this.coincidenciaIdDestacada,
  });

  final String reporteId;

  // Id de la coincidencia que se venía viendo antes de entrar aquí (desde
  // una notificación o desde "Mis coincidencias"). Si viene, la vista hace
  // auto-scroll y la resalta en vez de dejar al usuario en el tope del
  // listado completo de "Posibles coincidencias".
  final String? coincidenciaIdDestacada;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  // Copia local para poder remover/actualizar una coincidencia al instante
  // (descartar/confirmar) sin esperar a que se recargue el provider — igual
  // que antes en _CoincidenciasSectionState (US-24).
  List<Coincidencia>? _coincidencias;
  final Map<String, GlobalKey> _coincidenciaKeys = {};
  String? _resaltadaId;
  bool _scrollInicialPendiente = true;

  GlobalKey _keyPara(String id) => _coincidenciaKeys.putIfAbsent(id, () => GlobalKey());

  void _remover(String id) {
    setState(() {
      _coincidencias?.removeWhere((c) => c.id == id);
      _coincidenciaKeys.remove(id);
    });
  }

  void _actualizar(Coincidencia actualizada) {
    setState(() {
      final lista = _coincidencias;
      if (lista == null) return;
      final index = lista.indexWhere((c) => c.id == actualizada.id);
      if (index != -1) lista[index] = actualizada;
    });
  }

  Future<void> _resaltarYScrollear(String id) async {
    setState(() => _resaltadaId = id);
    final ctx = _coincidenciaKeys[id]?.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
    await Future.delayed(const Duration(seconds: 2));
    if (mounted && _resaltadaId == id) setState(() => _resaltadaId = null);
  }

  Future<void> _cerrar(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          '¿Confirmas que quieres cerrar este reporte? Esto lo marca como '
          'resuelto, no lo borra — el reporte no se elimina, solo deja de '
          'aparecer como activo. No podrás reabrirlo, pero si quieres podrás '
          'borrarlo después.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      await ref.read(reportesRepositoryProvider).cerrarReporte(widget.reporteId);
      ref.invalidate(reporteDetalleProvider(widget.reporteId));
      ref.invalidate(reportesCercanosProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Reporte cerrado')));
        await _preguntarBorrarTrasCerrar(context, ref);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _preguntarBorrarTrasCerrar(BuildContext context, WidgetRef ref) async {
    final borrarAhora = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          '¿Quieres borrar este reporte también? Si no lo haces ahora, puedes '
          'borrarlo después desde este mismo reporte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar ahora'),
          ),
        ],
      ),
    );
    if (borrarAhora == true && context.mounted) {
      await _ejecutarBorrado(context, ref);
    }
  }

  Future<void> _borrarConConfirmacion(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          '¿Seguro que quieres borrar este reporte? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmado == true && context.mounted) {
      await _ejecutarBorrado(context, ref);
    }
  }

  Future<void> _ejecutarBorrado(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(reportesRepositoryProvider).eliminarReporte(widget.reporteId);
      ref.invalidate(reportesCercanosProvider);
      ref.invalidate(misReportesPerdidosProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Reporte borrado')));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  // El FAB es el paso final del flujo de confirmación, no un atajo de
  // navegación: solo aparece cuando ya hay una coincidencia CONFIRMADA por
  // ambas partes (contacto liberado — `Coincidencia.confirmada`, no basta
  // con que yo haya confirmado de mi lado) y el reporte sigue activo. Al
  // tocarlo, cierra el reporte como caso exitoso reusando el mismo flujo
  // (con sus mismos diálogos) que el botón "Marcar como resuelto".
  Widget? _buildFab(BuildContext context) {
    final coincidencias = _coincidencias;
    if (coincidencias == null) return null;
    if (!coincidencias.any((c) => c.confirmada)) return null;

    final reporteActivo =
        ref.watch(reporteDetalleProvider(widget.reporteId)).valueOrNull?.activo ?? false;
    if (!reporteActivo) return null;

    return FloatingActionButton.extended(
      onPressed: () => _cerrar(context, ref),
      icon: const Icon(Icons.check_circle_outline),
      label: const Text('Marcar como resuelto'),
    );
  }

  Widget _buildCoincidencias(BuildContext context, String tipoPropio, String miFotoUrl) {
    final coincidenciasAsync = ref.watch(coincidenciasProvider(widget.reporteId));

    return coincidenciasAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        _coincidencias ??= List.of(data);
        final coincidencias = _coincidencias!;
        if (coincidencias.isEmpty) return const SizedBox.shrink();

        if (_scrollInicialPendiente) {
          _scrollInicialPendiente = false;
          final destacada = widget.coincidenciaIdDestacada;
          if (destacada != null && coincidencias.any((c) => c.id == destacada)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _resaltarYScrollear(destacada);
            });
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Posibles coincidencias',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Nuestra IA compara la foto de este reporte con otras usando '
              'reconocimiento de imágenes — así encontramos estos parecidos.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            for (final coincidencia in coincidencias) ...[
              AnimatedContainer(
                key: _keyPara(coincidencia.id),
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: coincidencia.id == _resaltadaId
                        ? AppColors.green
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CoincidenciaCard(
                  coincidencia: coincidencia,
                  tipoPropio: tipoPropio,
                  miFotoUrl: miFotoUrl,
                  onDescartada: () => _remover(coincidencia.id),
                  onActualizada: _actualizar,
                  onTapReporte: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportDetailScreen(reporteId: coincidencia.reporte.id),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reporteAsync = ref.watch(reporteDetalleProvider(widget.reporteId));
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del reporte')),
      floatingActionButton: _buildFab(context),
      body: reporteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(
          onRetry: () => ref.invalidate(reporteDetalleProvider(widget.reporteId)),
        ),
        data: (reporte) {
          final esCreador = reporte.creadoPor == uid;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _FotoCompletaScreen(fotoUrl: reporte.fotoUrl),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(reporte.fotoUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  AppBadge(
                    texto: reporte.esPerdida ? 'Perdida' : 'Avistamiento',
                    color: reporte.esPerdida ? Colors.deepOrange : AppColors.green,
                  ),
                  const SizedBox(width: 8),
                  AppBadge(
                    texto: reporte.activo ? 'Activo' : 'Cerrado',
                    color: reporte.activo ? AppColors.green : Colors.grey,
                  ),
                  if (!esCreador && reporte.nombreCreador != null) ...[
                    const SizedBox(width: 8),
                    AppBadge(
                      texto: 'Reporte de ${reporte.nombreCreador}',
                      color: Colors.grey,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                reporte.mascota.nombre,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place_outlined, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reporte.ubicacion.direccionTexto ??
                          '${reporte.ubicacion.lat}, ${reporte.ubicacion.lng}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionCard(
                titulo: 'Información',
                icono: Icons.pets_outlined,
                child: Column(
                  children: [
                    InfoTile(
                      icono: Icons.pets_outlined,
                      label: 'Especie',
                      valor: reporte.mascota.especie,
                    ),
                    const Divider(height: 20),
                    InfoTile(
                      icono: Icons.category_outlined,
                      label: 'Raza',
                      valor: reporte.mascota.raza,
                    ),
                    const Divider(height: 20),
                    InfoTile(
                      icono: Icons.palette_outlined,
                      label: 'Color',
                      valor: reporte.mascota.color,
                    ),
                  ],
                ),
              ),
              if (reporte.mascota.descripcion.isNotEmpty) ...[
                const SizedBox(height: 16),
                SectionCard(
                  titulo: 'Descripción',
                  icono: Icons.notes_outlined,
                  child: Text(
                    reporte.mascota.descripcion,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SectionCard(
                titulo: 'Ubicación',
                icono: Icons.map_outlined,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 180,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(reporte.ubicacion.lat, reporte.ubicacion.lng),
                        zoom: 15,
                      ),
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      liteModeEnabled: true,
                      markers: {
                        Marker(
                          markerId: const MarkerId('ubicacion-reporte'),
                          position: LatLng(reporte.ubicacion.lat, reporte.ubicacion.lng),
                        ),
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (esCreador)
                _buildCoincidencias(context, reporte.tipo, reporte.fotoUrl),
              if (esCreador && reporte.activo) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditReportScreen(reporte: reporte),
                    ),
                  ),
                  child: const Text('Editar reporte'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _cerrar(context, ref),
                  child: const Text('Marcar como resuelto (cerrar reporte)'),
                ),
                const SizedBox(height: 4),
                Text(
                  'No borra el reporte, solo lo marca como resuelto.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
              if (esCreador && !reporte.activo) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => _borrarConConfirmacion(context, ref),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Borrar reporte'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FotoCompletaScreen extends StatelessWidget {
  const _FotoCompletaScreen({required this.fotoUrl});

  final String fotoUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(fotoUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

