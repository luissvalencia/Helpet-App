import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/notifications_providers.dart';
import '../data/notificaciones_repository.dart';
import '../domain/notificacion_app.dart';

final notificacionesRepositoryProvider = Provider<NotificacionesRepository>((ref) {
  return NotificacionesRepository(ref.watch(apiClientProvider));
});

final notificacionesProvider = FutureProvider.autoDispose<List<NotificacionApp>>((ref) {
  ref.watch(notificacionesTickProvider);
  return ref.watch(notificacionesRepositoryProvider).listar();
});

final notificacionesNoLeidasProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificacionesProvider).maybeWhen(
        data: (lista) => lista.where((n) => !n.leida).length,
        orElse: () => 0,
      );
});
