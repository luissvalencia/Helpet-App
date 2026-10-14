import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../domain/metricas.dart';
import 'profile_providers.dart';

class MetricasScreen extends ConsumerWidget {
  const MetricasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricasAsync = ref.watch(metricasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Métricas del modelo')),
      body: metricasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(onRetry: () => ref.invalidate(metricasProvider)),
        data: (metricas) => _MetricasContent(metricas: metricas),
      ),
    );
  }
}

class _MetricasContent extends StatelessWidget {
  const _MetricasContent({required this.metricas});

  final Metricas metricas;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _StatCard(valor: '${metricas.totalEmbeddings}', etiqueta: 'Embeddings generados'),
        _StatCard(valor: '${metricas.totalCoincidencias}', etiqueta: 'Coincidencias detectadas'),
        _StatCard(valor: '${metricas.coincidenciasPendientes}', etiqueta: 'Coincidencias pendientes'),
        _StatCard(
          valor: '${metricas.tasaDescarte.toStringAsFixed(1)}%',
          etiqueta: 'Tasa de descarte',
        ),
        _StatCard(
          valor: '${(metricas.similitudPromedio * 100).toStringAsFixed(1)}%',
          etiqueta: 'Similitud promedio',
        ),
        _StatCard(
          valor: '${(metricas.similitudMinima * 100).toStringAsFixed(1)}% - '
              '${(metricas.similitudMaxima * 100).toStringAsFixed(1)}%',
          etiqueta: 'Rango de similitud',
        ),
        _StatCard(
          valor: '${(metricas.umbralActual * 100).toStringAsFixed(0)}%',
          etiqueta: 'Umbral actual',
        ),
        _StatCard(
          valor: '${metricas.reportesActivos} / ${metricas.reportesCerrados}',
          etiqueta: 'Reportes activos / cerrados',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              valor,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              etiqueta,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
