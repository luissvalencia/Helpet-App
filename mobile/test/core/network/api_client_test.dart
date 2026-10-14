import 'dart:convert';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpet_app/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    late MockFirebaseAuth auth;

    setUp(() {
      auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'usuario-1'));
    });

    test('agrega el header Authorization con el token del usuario y decodifica el body JSON', () async {
      http.Request? requestCapturado;
      final client = MockClient((request) async {
        requestCapturado = request;
        return http.Response(jsonEncode({'ok': true}), 200);
      });

      final apiClient = ApiClient(auth, client: client);
      final resultado = await apiClient.get('/reportes/mios');

      expect(resultado, {'ok': true});
      expect(requestCapturado!.headers['Authorization'], startsWith('Bearer '));
      expect(requestCapturado!.headers['Content-Type'], 'application/json');
    });

    test('en un 401 cierra la sesión y lanza ApiException', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'Token inválido'}), 401);
      });

      final apiClient = ApiClient(auth, client: client);

      await expectLater(
        apiClient.get('/reportes/mios'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
      expect(auth.currentUser, isNull);
    });

    test('usa el mensaje de error del body JSON cuando la respuesta no es 2xx', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'mascota.nombre es requerido'}), 400);
      });

      final apiClient = ApiClient(auth, client: client);

      await expectLater(
        apiClient.post('/reportes', body: {}),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', 'mascota.nombre es requerido'),
        ),
      );
    });

    test('cae a un mensaje genérico si el body de error no es JSON', () async {
      final client = MockClient((request) async {
        return http.Response('<html>500</html>', 500);
      });

      final apiClient = ApiClient(auth, client: client);

      await expectLater(
        apiClient.get('/reportes/mios'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Error de red')),
      );
    });

    test('delete con 204 sin cuerpo no lanza', () async {
      final client = MockClient((request) async {
        return http.Response('', 204);
      });

      final apiClient = ApiClient(auth, client: client);
      await apiClient.delete('/reportes/abc');
    });
  });
}
