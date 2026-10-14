import 'package:flutter/material.dart';

/// Encabezado + línea divisoria, usado para agrupar campos/datos
/// relacionados en vez de listarlos como texto plano suelto. Mismo
/// lenguaje visual en toda la app (detalle de reporte, crear/editar
/// reporte, login, registro, perfil). Deliberadamente plano (sin caja ni
/// relleno) — auditoría de diseño post-lanzamiento: el estilo de tarjeta
/// gris rellena se sentía pesado/"encerrado" en formularios simples como
/// login y registro.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.titulo, required this.icono, required this.child});

  final String titulo;
  final IconData icono;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: colorScheme.outlineVariant),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
