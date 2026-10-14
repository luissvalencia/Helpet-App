import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../features/reports/presentation/report_detail_screen.dart';
import '../network/api_client.dart';

class NotificationsService {
  NotificationsService(
    this._apiClient,
    this._messaging,
    this._navigatorKey, {
    VoidCallback? onNuevaNotificacion,
  }) : _onNuevaNotificacion = onNuevaNotificacion;

  final ApiClient _apiClient;
  final FirebaseMessaging _messaging;
  final GlobalKey<NavigatorState> _navigatorKey;
  final VoidCallback? _onNuevaNotificacion;

  bool _listenersRegistrados = false;

  Future<void> initForUser(String uid) async {
    await _messaging.requestPermission();
    await _guardarToken();
    _messaging.onTokenRefresh.listen((_) => _guardarToken());
    _registrarListeners();
  }

  Future<void> _guardarToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    try {
      await _apiClient.patch('/users/me', body: {'fcmToken': token});
    } catch (_) {
      // Best-effort: si falla, se reintenta en el próximo login/apertura de la app.
    }
  }

  void _registrarListeners() {
    if (_listenersRegistrados) return;
    _listenersRegistrados = true;

    FirebaseMessaging.onMessage.listen((message) {
      _onNuevaNotificacion?.call();

      final texto = [message.notification?.title, message.notification?.body]
          .whereType<String>()
          .join(': ');
      final context = _navigatorKey.currentContext;
      if (context == null || !context.mounted || texto.isEmpty) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(texto),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () => _navegarDesdeData(message.data),
          ),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _onNuevaNotificacion?.call();
      _navegarDesdeData(message.data);
    });

    _messaging.getInitialMessage().then((message) {
      if (message == null) return;
      _onNuevaNotificacion?.call();
      _navegarDesdeData(message.data);
    });
  }

  void _navegarDesdeData(Map<String, dynamic> data) {
    final reporteId = data['reporteId'] as String?;
    if (reporteId == null) return;
    final coincidenciaId = data['coincidenciaId'] as String?;

    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(
          reporteId: reporteId,
          coincidenciaIdDestacada: coincidenciaId,
        ),
      ),
    );
  }
}
