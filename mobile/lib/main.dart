import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_theme.dart';
import 'core/navigation/app_navigator.dart';
import 'core/providers/theme_providers.dart';
import 'core/widgets/auth_gate.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Se ejecuta en un isolate separado: hay que inicializar Firebase de nuevo.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      // No llenar el dashboard de Crashlytics con crashes de desarrollo local.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Errores de widgets (build/layout/paint) capturados por Flutter — antes
      // no se reportaban a ningún lado, solo quedaban en la consola de debug.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      // Errores async fuera del árbol de widgets (fuera de try/catch, fuera
      // de un FutureBuilder/AsyncValue) que de otra forma solo aparecen como
      // "Unhandled exception" en el log del dispositivo.
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      runApp(const ProviderScope(child: HelpetApp()));
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class HelpetApp extends ConsumerWidget {
  const HelpetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Helpet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}
