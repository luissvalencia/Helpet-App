import 'package:flutter/material.dart';

/// Estado de error reutilizable para reemplazar el patrón
/// `Center(child: Text('Error: $err'))` que muestra la excepción cruda de
/// Dart directo en pantalla.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(
              message ?? 'No se pudo cargar la información. Verifica tu conexión.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
