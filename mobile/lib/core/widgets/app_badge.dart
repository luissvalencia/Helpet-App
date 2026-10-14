import 'package:flutter/material.dart';

/// Pastilla de color para mostrar un estado corto (tipo, activo/cerrado,
/// nivel de coincidencia) sin depender del `Chip` por defecto de Material.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
