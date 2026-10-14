import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/app_navigator.dart';
import '../notifications/notifications_service.dart';
import 'firebase_providers.dart';

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

/// Se incrementa cada vez que llega/se abre un push — lo observa
/// `notificacionesProvider` (centro de notificaciones) para refrescar la
/// lista sin depender de que el usuario haga pull-to-refresh a mano.
final notificacionesTickProvider = StateProvider<int>((ref) => 0);

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService(
    ref.watch(apiClientProvider),
    ref.watch(firebaseMessagingProvider),
    rootNavigatorKey,
    onNuevaNotificacion: () => ref.read(notificacionesTickProvider.notifier).state++,
  );
});
