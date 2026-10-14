import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/coincidencia.dart';
import '../reportes_providers.dart';

/// Tarjeta de una coincidencia, reutilizada tanto en el detalle de un
/// reporte propio como en la pantalla "Mis coincidencias". `tipoPropio` es
/// el tipo del reporte PROPIO desde el que se ve esta coincidencia (no el
/// del otro lado, que vive en `coincidencia.reporte`) — determina si el
/// texto de confirmación habla de "mi mascota" (dueño que perdió) o de "lo
/// que vi" (quien reportó un avistamiento).
class CoincidenciaCard extends ConsumerWidget {
  const CoincidenciaCard({
    super.key,
    required this.coincidencia,
    required this.tipoPropio,
    required this.miFotoUrl,
    required this.onDescartada,
    required this.onActualizada,
    this.onTapReporte,
  });

  final Coincidencia coincidencia;
  final String tipoPropio;
  // Foto del reporte PROPIO (no la de coincidencia.reporte, que es la del
  // otro lado) — se muestra junto a la otra en el encabezado para que se
  // note a simple vista cuál es cuál, en vez de un solo texto largo
  // (feedback de pruebas de usuario: con una sola foto no quedaba claro
  // qué se estaba comparando contra qué).
  final String miFotoUrl;
  final VoidCallback onDescartada;
  final void Function(Coincidencia) onActualizada;
  final VoidCallback? onTapReporte;

  bool get _esPropioPerdida => tipoPropio == 'perdida';

  // Feedback de pruebas de usuario: quien reportó el avistamiento no tiene
  // forma real de juzgar si la coincidencia es incorrecta (solo vio *un*
  // animal, no sabe si es o no la mascota perdida de alguien más) — esa
  // decisión le corresponde al dueño. Se deja descartar solo del lado
  // "perdida".
  bool get _puedeDescartar => _esPropioPerdida;

  bool get _puedeConfirmar =>
      !coincidencia.yoConfirme && (_esPropioPerdida || coincidencia.duenoYaConfirmo);

  Future<void> _confirmarDescarte(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('¿Confirmas que esta coincidencia es incorrecta?'),
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
      await ref.read(reportesRepositoryProvider).descartarCoincidencia(coincidencia.id);
      onDescartada();
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmarMatch(BuildContext context, WidgetRef ref) async {
    final mensaje = _esPropioPerdida
        ? '¿Confirmas que esta coincidencia sí es tu mascota? Cuando el otro '
            'dueño también confirme, podrán verse los datos de contacto.'
        : 'El dueño de esta mascota perdida podría estar buscando al animal '
            'que viste. ¿Aceptas que te contacte para verificarlo? Cuando '
            'ambos confirmen, podrán verse los datos de contacto.';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(mensaje),
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
      final resultado =
          await ref.read(reportesRepositoryProvider).confirmarCoincidencia(coincidencia.id);
      onActualizada(coincidencia.copyWith(
        estado: resultado.estado,
        yoConfirme: true,
        duenoYaConfirmo: _esPropioPerdida ? true : coincidencia.duenoYaConfirmo,
        contacto: resultado.contacto,
      ));
      if (context.mounted && resultado.confirmada) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Coincidencia confirmada! Ya puedes ver el contacto.'),
        ));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Confirmado. Falta que el otro dueño también confirme.'),
        ));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _reportarUsuario(BuildContext context, WidgetRef ref) async {
    final motivoController = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar a este usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuéntanos qué pasó. Un administrador revisará el reporte.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(motivoController.text.trim()),
            child: const Text('Enviar reporte'),
          ),
        ],
      ),
    );
    if (motivo == null || motivo.isEmpty) return;

    try {
      await ref.read(profileRepositoryProvider).reportarUsuario(
            uid: coincidencia.contacto!.uid,
            motivo: motivo,
            coincidenciaId: coincidencia.id,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte enviado. Gracias por avisarnos.')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _copiar(BuildContext context, String etiqueta, String valor) {
    Clipboard.setData(ClipboardData(text: valor));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$etiqueta copiado')));
  }

  Widget _fotoConEtiqueta(String url, String etiqueta) {
    return Column(
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reporte = coincidencia.reporte;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onTapReporte,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _fotoConEtiqueta(miFotoUrl, 'Tú'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward, size: 18, color: Colors.grey),
                  ),
                  _fotoConEtiqueta(reporte.fotoUrl, 'Coincidencia'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reporte.mascota.nombre,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        coincidencia.confirmada
                            ? const AppBadge(texto: 'Confirmada', color: AppColors.green)
                            : AppBadge(
                                texto: coincidencia.etiqueta,
                                color: coincidencia.esAlta
                                    ? AppColors.green
                                    : Colors.grey,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (coincidencia.confirmada && coincidencia.contacto != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contacto de ${coincidencia.contacto!.nombre}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if (coincidencia.contacto!.telefono != null)
                      Row(
                        children: [
                          Expanded(child: Text('Tel: ${coincidencia.contacto!.telefono}')),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () => _copiar(
                              context,
                              'Teléfono',
                              coincidencia.contacto!.telefono!,
                            ),
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        Expanded(child: Text('Correo: ${coincidencia.contacto!.email}')),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () =>
                              _copiar(context, 'Correo', coincidencia.contacto!.email),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _reportarUsuario(context, ref),
                        icon: const Icon(Icons.flag_outlined, size: 16),
                        label: const Text('Reportar a este usuario'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            if (coincidencia.yoConfirme)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Text(
                  'Ya confirmaste — esperando que el otro dueño también confirme.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              )
            else if (!_esPropioPerdida && !coincidencia.duenoYaConfirmo)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Text(
                  'Aún no revisado por el dueño — cuando confirme que es su '
                  'mascota, aquí podrás aceptar que te contacte.',
                  style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                ),
              ),
            if (_puedeConfirmar || _puedeDescartar)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    if (_puedeConfirmar) ...[
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _confirmarMatch(context, ref),
                          child: Text(_esPropioPerdida ? 'Sí, es mi mascota' : 'Sí, que me contacte'),
                        ),
                      ),
                      if (_puedeDescartar) const SizedBox(width: 8),
                    ],
                    if (_puedeDescartar)
                      Expanded(
                        child: TextButton(
                          onPressed: () => _confirmarDescarte(context, ref),
                          child: const Text('Esta no es mi mascota'),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
