import '../../../core/network/api_client.dart';
import '../../auth/domain/app_user.dart';
import '../domain/metricas.dart';

class ProfileRepository {
  ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Metricas> getMetricas() async {
    final json = await _apiClient.get('/admin/metricas') as Map<String, dynamic>;
    return Metricas.fromJson(json);
  }

  Future<AppUser> getMe() async {
    // Justo tras el primer login con Google hay una ventana breve donde
    // Firebase ya emitió el cambio de sesión pero el doc `users/{uid}`
    // (creado por el propio cliente en `signInWithGoogle`) todavía no
    // terminó de escribirse — el backend responde 404 en ese instante.
    // Se reintenta un par de veces antes de darlo por un error real.
    for (var intento = 0; ; intento++) {
      try {
        final json = await _apiClient.get('/users/me') as Map<String, dynamic>;
        return AppUser.fromJson(json);
      } on ApiException catch (e) {
        if (e.statusCode != 404 || intento >= 2) rethrow;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<AppUser> updateMe({
    required String nombre,
    String? telefono,
    String? ciudad,
    String? direccionReferencia,
  }) async {
    final json = await _apiClient.patch('/users/me', body: {
      'nombre': nombre,
      'telefono': telefono,
      'ciudad': ciudad,
      'direccionReferencia': direccionReferencia,
    }) as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }

  Future<AppUser> updatePreferencias({
    required bool notifCoincidencias,
    required bool notifReportesCercanos,
  }) async {
    final json = await _apiClient.patch('/users/me', body: {
      'notifCoincidencias': notifCoincidencias,
      'notifReportesCercanos': notifReportesCercanos,
    }) as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }

  Future<AppUser> updateFotoPerfil(String fotoUrl) async {
    final json = await _apiClient.patch('/users/me', body: {
      'fotoUrl': fotoUrl,
    }) as Map<String, dynamic>;
    return AppUser.fromJson(json);
  }

  Future<void> eliminarCuenta() async {
    await _apiClient.delete('/users/me');
  }

  Future<void> reportarUsuario({
    required String uid,
    required String motivo,
    String? coincidenciaId,
  }) async {
    await _apiClient.post('/users/$uid/reportar', body: {
      'motivo': motivo,
      if (coincidenciaId != null) 'coincidenciaId': coincidenciaId,
    });
  }
}
