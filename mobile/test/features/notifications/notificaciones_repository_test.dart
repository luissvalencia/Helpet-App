import 'dart:convert';

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpet_app/core/network/api_client.dart';
import 'package:helpet_app/features/notifications/data/notificaciones_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('NotificacionesRepository', () {
    late MockFirebaseAuth auth;

    setUp(() {
      auth = MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'usuario-1'));
    });

    test('listar() parsea la lista y respeta leida/tipo/data', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/notificaciones');
        return http.Response(
          jsonEncode([
            {
              'id': 'n1',
              'titulo': '¡Posible coincidencia encontrada!',
              'cuerpo': 'Encontramos un avistamiento parecido.',
              'tipo': 'coincidencia',
              'data': {'reporteId': 'r1', 'coincidenciaId': 'c1'},
              'leida': false,
              'creadoEn': '2026-09-01T10:00:00.000Z',
            },
          ]),
          200,
        );
      });

      final repo = NotificacionesRepository(ApiClient(auth, client: client));
      final lista = await repo.listar();

      expect(lista, hasLength(1));
      expect(lista.first.id, 'n1');
      expect(lista.first.leida, isFalse);
      expect(lista.first.reporteId, 'r1');
      expect(lista.first.tipo, 'coincidencia');
    });

    test('marcarLeida() hace POST al endpoint correcto', () async {
      String? pathLlamado;
      final client = MockClient((request) async {
        pathLlamado = request.url.path;
        return http.Response('', 200);
      });

      final repo = NotificacionesRepository(ApiClient(auth, client: client));
      await repo.marcarLeida('n1');

      expect(pathLlamado, '/notificaciones/n1/marcar-leida');
    });

    test('marcarTodasLeidas() hace POST al endpoint correcto', () async {
      String? pathLlamado;
      final client = MockClient((request) async {
        pathLlamado = request.url.path;
        return http.Response(jsonEncode({'ok': true, 'actualizadas': 3}), 200);
      });

      final repo = NotificacionesRepository(ApiClient(auth, client: client));
      await repo.marcarTodasLeidas();

      expect(pathLlamado, '/notificaciones/marcar-todas-leidas');
    });

    test('eliminar() hace DELETE al endpoint correcto', () async {
      String? pathLlamado;
      String? metodoLlamado;
      final client = MockClient((request) async {
        pathLlamado = request.url.path;
        metodoLlamado = request.method;
        return http.Response('', 200);
      });

      final repo = NotificacionesRepository(ApiClient(auth, client: client));
      await repo.eliminar('n1');

      expect(metodoLlamado, 'DELETE');
      expect(pathLlamado, '/notificaciones/n1');
    });
  });
}
