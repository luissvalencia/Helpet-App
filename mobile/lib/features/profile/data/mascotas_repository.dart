import '../../../core/network/api_client.dart';
import '../domain/mascota_guardada.dart';

class MascotasRepository {
  MascotasRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<MascotaGuardada> crear({
    required String nombre,
    required String especie,
    String raza = '',
    String color = '',
    String descripcion = '',
    String? fotoUrl,
  }) async {
    final json = await _apiClient.post('/mascotas', body: {
      'nombre': nombre,
      'especie': especie,
      'raza': raza,
      'color': color,
      'descripcion': descripcion,
      'fotoUrl': fotoUrl,
    }) as Map<String, dynamic>;
    return MascotaGuardada.fromJson(json);
  }

  Future<List<MascotaGuardada>> listarPropias() async {
    final json = await _apiClient.get('/mascotas/mias') as List<dynamic>;
    return json
        .map((item) => MascotaGuardada.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<MascotaGuardada> actualizar({
    required String id,
    String? nombre,
    String? especie,
    String? raza,
    String? color,
    String? descripcion,
    String? fotoUrl,
  }) async {
    final json = await _apiClient.patch('/mascotas/$id', body: {
      if (nombre != null) 'nombre': nombre,
      if (especie != null) 'especie': especie,
      if (raza != null) 'raza': raza,
      if (color != null) 'color': color,
      if (descripcion != null) 'descripcion': descripcion,
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
    }) as Map<String, dynamic>;
    return MascotaGuardada.fromJson(json);
  }

  Future<void> eliminar(String id) async {
    await _apiClient.delete('/mascotas/$id');
  }
}
