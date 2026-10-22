import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../reports/presentation/report_detail_screen.dart';
import '../domain/notificacion_app.dart';
import 'notificaciones_providers.dart';

class NotificacionesScreen extends ConsumerStatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  List<NotificacionApp>? _notificaciones;

  Future<void> _abrir(NotificacionApp notificacion) async {
    if (!notificacion.leida) {
      setState(() {
        final lista = _notificaciones;
        if (lista == null) return;
        final index = lista.indexWhere((n) => n.id == notificacion.id);
        if (index != -1) lista[index] = notificacion.copyWith(leida: true);
      });
      try {
        await ref.read(notificacionesRepositoryProvider).marcarLeida(notificacion.id);
        // El contador de la campanita (reports_list_screen) mira
        // notificacionesProvider, no este estado local — sin invalidar se
        // queda marcando pendientes que ya se leyeron.
        ref.invalidate(notificacionesProvider);
      } catch (_) {
        // Best-effort: si falla, se sigue viendo como leída localmente hasta
        // el próximo refresh — no bloquea la navegación al reporte.
      }
    }

    final reporteId = notificacion.reporteId;
    if (reporteId != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReportDetailScreen(
            reporteId: reporteId,
            coincidenciaIdDestacada: notificacion.coincidenciaId,
          ),
        ),
      );
    }
  }

  Future<void> _borrarTodas() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar todas las notificaciones?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final anteriores = _notificaciones;
    setState(() => _notificaciones = []);
    try {
      await ref.read(notificacionesRepositoryProvider).eliminarTodas();
      ref.invalidate(notificacionesProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron borrar, intenta de nuevo.')),
        );
        setState(() => _notificaciones = anteriores);
      }
    }
  }

  Future<void> _eliminar(NotificacionApp notificacion) async {
    setState(() => _notificaciones?.removeWhere((n) => n.id == notificacion.id));
    try {
      await ref.read(notificacionesRepositoryProvider).eliminar(notificacion.id);
      ref.invalidate(notificacionesProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo borrar, intenta de nuevo.')),
        );
        setState(() => _notificaciones?.add(notificacion));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificacionesAsync = ref.watch(notificacionesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if ((_notificaciones ?? const []).isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Borrar todas',
              onPressed: _borrarTodas,
            ),
        ],
      ),
      body: notificacionesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(onRetry: () => ref.invalidate(notificacionesProvider)),
        data: (data) {
          _notificaciones ??= List.of(data);
          final notificaciones = _notificaciones!;
          if (notificaciones.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no tienes notificaciones. Aquí verás avisos de '
                  'coincidencias y reportes cercanos, aunque no los veas en '
                  'el momento en que llegan.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificacionesProvider);
              final actualizadas = await ref.read(notificacionesProvider.future);
              setState(() => _notificaciones = List.of(actualizadas));
            },
            child: ListView.separated(
              itemCount: notificaciones.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notificacion = notificaciones[index];
                return Dismissible(
                  key: ValueKey(notificacion.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _eliminar(notificacion),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: Container(
                    color: notificacion.leida ? null : AppColors.green.withValues(alpha: 0.06),
                    child: ListTile(
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: notificacion.leida ? Colors.grey : AppColors.green,
                          ),
                          if (!notificacion.leida)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        notificacion.titulo,
                        style: TextStyle(
                          fontWeight: notificacion.leida ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(notificacion.cuerpo),
                      trailing: Text(
                        _tiempoRelativo(notificacion.creadoEn),
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      onTap: () => _abrir(notificacion),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

String _tiempoRelativo(DateTime? fecha) {
  if (fecha == null) return '';
  final diferencia = DateTime.now().difference(fecha);
  if (diferencia.inMinutes < 1) return 'ahora';
  if (diferencia.inMinutes < 60) return '${diferencia.inMinutes} min';
  if (diferencia.inHours < 24) return '${diferencia.inHours} h';
  return '${diferencia.inDays} d';
}
