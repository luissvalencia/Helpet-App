import 'package:flutter_test/flutter_test.dart';
import 'package:helpet_app/core/utils/validadores.dart';

void main() {
  group('validarTelefono', () {
    for (final valido in ['3001234567', '300 123 4567', '+57 300-123-4567', '(602) 8201234']) {
      test('acepta "$valido"', () => expect(validarTelefono(valido), isNull));
    }
    for (final invalido in ['', '   ', 'hola', '123', '300abc4567']) {
      test('rechaza "$invalido"', () => expect(validarTelefono(invalido), isNotNull));
    }
  });

  group('validarCorreo', () {
    test('acepta un correo normal', () => expect(validarCorreo('ana@correo.com'), isNull));
    test('rechaza texto sin dominio', () => expect(validarCorreo('ana@'), isNotNull));
    test('rechaza texto sin arroba', () => expect(validarCorreo('ana.correo.com'), isNotNull));
  });
}
