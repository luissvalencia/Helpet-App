import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/domain/app_user.dart';
import '../data/mascotas_repository.dart';
import '../data/profile_repository.dart';
import '../domain/mascota_guardada.dart';
import '../domain/metricas.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

final mascotasRepositoryProvider = Provider<MascotasRepository>((ref) {
  return MascotasRepository(ref.watch(apiClientProvider));
});

final meProvider = FutureProvider.autoDispose<AppUser>((ref) {
  // Se re-ejecuta cada vez que cambia el usuario autenticado (login/logout),
  // porque ProfileScreen queda montada permanentemente dentro del IndexedStack
  // de HomeShell y de otro modo nunca refrescaría tras un cambio de cuenta.
  ref.watch(authStateChangesProvider);
  return ref.watch(profileRepositoryProvider).getMe();
});

final metricasProvider = FutureProvider.autoDispose<Metricas>((ref) {
  return ref.watch(profileRepositoryProvider).getMetricas();
});

final misMascotasProvider = FutureProvider.autoDispose<List<MascotaGuardada>>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(mascotasRepositoryProvider).listarPropias();
});
