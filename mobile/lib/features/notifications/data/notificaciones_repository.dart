import '../../../core/network/api_client.dart';
import '../domain/notificacion_app.dart';

class NotificacionesRepository {
  NotificacionesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<NotificacionApp>> listar() async {
    final json = await _apiClient.get('/notificaciones') as List<dynamic>;
    return json
        .map((item) => NotificacionApp.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> marcarLeida(String id) async {
    await _apiClient.post('/notificaciones/$id/marcar-leida');
  }

  Future<void> marcarTodasLeidas() async {
    await _apiClient.post('/notificaciones/marcar-todas-leidas');
  }

  Future<void> eliminar(String id) async {
    await _apiClient.delete('/notificaciones/$id');
  }
}
