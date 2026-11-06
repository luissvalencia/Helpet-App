import 'package:flutter/services.dart';

/// Largos máximos de los textos libres. Deben coincidir con los del backend
/// (backend/src/schemas/common.schema.js y users.schema.js), que es quien
/// realmente los hace cumplir; aquí solo se evita que el usuario escriba de
/// más y reciba un error del servidor.
const int maxNombreMascota = 50;
const int maxRazaColor = 60;
const int maxDescripcion = 500;
const int maxDireccionReporte = 200;
const int maxNombrePersona = 80;
const int maxCiudad = 80;
const int maxDireccionReferencia = 150;
const int maxMotivoReporte = 500;

List<TextInputFormatter> limitarA(int max) =>
    [LengthLimitingTextInputFormatter(max)];

/// Mismo criterio que el backend: sin contar espacios, guiones, puntos ni
/// paréntesis, de 7 a 15 dígitos con "+" opcional al inicio.
String? validarTelefono(String? value) {
  final texto = value?.trim() ?? '';
  if (texto.isEmpty) return 'Requerido';
  final limpio = texto.replaceAll(RegExp(r'[\s\-().]'), '');
  if (!RegExp(r'^\+?\d{7,15}$').hasMatch(limpio)) {
    return 'Escribe un número de teléfono válido';
  }
  return null;
}

/// Validación básica de formato de correo (Firebase Auth hace la definitiva).
String? validarCorreo(String? value) {
  final texto = value?.trim() ?? '';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto)) {
    return 'Correo inválido';
  }
  return null;
}
