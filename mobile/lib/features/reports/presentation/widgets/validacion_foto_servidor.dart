import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';

/// El backend revisa con IA que la foto muestre un perro o un gato antes de
/// guardar un reporte o una mascota. Estos códigos significan que hay que
/// elegir otra foto.
bool esFotoRechazada(ApiException e) =>
    e.codigo == 'foto_sin_mascota' || e.codigo == 'foto_invalida';

/// Llama a [enviar] y, si el backend responde que la foto parece de otra
/// especie que la elegida ('especie_distinta'), le pregunta al usuario. Si
/// confirma que la especie elegida es correcta, reenvía con
/// `confirmarEspecie: true`; si prefiere revisar, devuelve `null` sin guardar.
/// Cualquier otro error se relanza tal cual.
Future<T?> enviarConValidacionDeEspecie<T>(
  BuildContext context,
  Future<T> Function(bool confirmarEspecie) enviar,
) async {
  try {
    return await enviar(false);
  } on ApiException catch (e) {
    if (e.codigo != 'especie_distinta' || !context.mounted) rethrow;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.pets_outlined),
        title: const Text('¿La especie es correcta?'),
        content: Text(
          '${e.message}\n\nRevisa la especie seleccionada. Si estás seguro de '
          'que es correcta, puedes guardar de todas formas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Revisar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar así'),
          ),
        ],
      ),
    );
    if (confirmar != true) return null;
    return enviar(true);
  }
}
