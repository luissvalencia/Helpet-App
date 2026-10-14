class AppConfig {
  /// URL base del backend. Para emulador Android usa el valor por defecto
  /// (10.0.2.2 apunta al localhost de la máquina anfitriona). Para probar en
  /// un dispositivo físico (Android 14 / API 34), pasa la IP de tu máquina
  /// en la misma red:
  ///
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.X:3000
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
