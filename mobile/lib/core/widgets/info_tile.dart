import 'package:flutter/material.dart';

/// Fila ícono + etiqueta + valor, para mostrar datos dentro de un
/// [SectionCard] en vez de líneas de texto plano ("Especie: Perro").
class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.icono, required this.label, required this.valor});

  final IconData icono;
  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const Spacer(),
        Text(
          valor.isEmpty ? '—' : valor,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
