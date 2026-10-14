import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_theme.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/mi_coincidencia.dart';
import 'report_detail_screen.dart';
import 'reportes_providers.dart';

/// Pantalla persistente de todas las coincidencias del usuario (cualquiera
/// de sus reportes, "perdida" o "encontrada"). Solo resume — para
/// confirmar/descartar hay que entrar al reporte, donde vive esa acción
/// (evita tener el mismo botón duplicado en dos pantallas distintas).
class MisCoincidenciasScreen extends ConsumerWidget {
  const MisCoincidenciasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final misCoincidenciasAsync = ref.watch(misCoincidenciasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis coincidencias')),
      body: misCoincidenciasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(
          onRetry: () => ref.invalidate(misCoincidenciasProvider),
        ),
        data: (coincidencias) {
          if (coincidencias.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no tienes coincidencias. Cuando la IA encuentre un '
                  'posible parecido con uno de tus reportes, aparecerá aquí.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(misCoincidenciasProvider);
              await ref.read(misCoincidenciasProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: coincidencias.length,
              itemBuilder: (context, index) {
                final item = coincidencias[index];
                return _CoincidenciaResumenTile(
                  item: item,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportDetailScreen(
                          reporteId: item.miReporte.id,
                          coincidenciaIdDestacada: item.coincidencia.id,
                        ),
                      ),
                    );
                    // Confirmar/descartar pasa en el detalle — al volver,
                    // refrescamos para que el resumen refleje el estado nuevo.
                    ref.invalidate(misCoincidenciasProvider);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CoincidenciaResumenTile extends StatelessWidget {
  const _CoincidenciaResumenTile({required this.item, required this.onTap});

  final MiCoincidencia item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coincidencia = item.coincidencia;
    final reporte = coincidencia.reporte;
    final esperandoAlOtroDueno =
        !coincidencia.confirmada && !item.miReporte.esPerdida && !coincidencia.duenoYaConfirmo;

    // Sin texto de relleno cuando no hay nada que decir aparte de la
    // pastilla de estado (feedback de pruebas de usuario: "toca para
    // revisar" no aportaba nada y hacía ver la fila más apretada).
    String? estadoTexto;
    if (coincidencia.confirmada) {
      estadoTexto = 'Contacto disponible';
    } else if (coincidencia.yoConfirme) {
      estadoTexto = 'Esperando al otro lado';
    } else if (esperandoAlOtroDueno) {
      estadoTexto = 'Esperando al dueño';
    }

    Widget foto(String url) => SizedBox(
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, fit: BoxFit.cover),
          ),
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              foto(item.miReporte.fotoUrl),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
              ),
              foto(reporte.fotoUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reporte.mascota.nombre,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        coincidencia.confirmada
                            ? const AppBadge(texto: 'Confirmada', color: AppColors.green)
                            : AppBadge(
                                texto: coincidencia.etiqueta,
                                color:
                                    coincidencia.esAlta ? AppColors.green : Colors.grey,
                              ),
                        if (estadoTexto != null)
                          Text(
                            estadoTexto,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
