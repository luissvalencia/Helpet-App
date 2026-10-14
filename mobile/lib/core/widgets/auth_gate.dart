import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/profile/presentation/editar_perfil_screen.dart';
import '../../features/profile/presentation/profile_providers.dart';
import '../providers/firebase_providers.dart';
import '../providers/notifications_providers.dart';
import 'error_view.dart';
import 'home_shell.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    // US-19/US-20: al iniciar sesión (o al abrir la app si ya hay sesión),
    // registrar el FCM token y los listeners de notificaciones.
    ref.listen(authStateChangesProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user != null) {
        ref.read(notificationsServiceProvider).initForUser(user.uid);
      }
    });

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: ErrorView(onRetry: () => ref.invalidate(authStateChangesProvider)),
      ),
      data: (user) {
        if (user == null) return const LoginScreen();

        // Quienes entran con Google por primera vez no traen teléfono
        // (Google no lo entrega) — se pide antes de dejar pasar al resto de
        // la app porque es el dato principal que se revela al confirmar
        // una coincidencia (sistema de contacto).
        final meAsync = ref.watch(meProvider);
        return meAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Scaffold(
            body: ErrorView(onRetry: () => ref.invalidate(meProvider)),
          ),
          data: (me) {
            if (me.telefono == null || me.telefono!.isEmpty) {
              return EditarPerfilScreen(user: me, obligatorio: true);
            }
            return const HomeShell();
          },
        );
      },
    );
  }
}
