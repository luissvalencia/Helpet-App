import '../../../core/network/api_client.dart';
import '../domain/coincidencia.dart';
import '../domain/mascota.dart';
import '../domain/mi_coincidencia.dart';
import '../domain/reporte.dart';
import '../domain/ubicacion.dart';

class ReportesRepository {
  ReportesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Reporte> crearReporte({
    required String tipo,
    required Mascota mascota,
    required String fotoUrl,
    required Ubicacion ubicacion,
    String? mascotaId,
  }) async {
    final json = await _apiClient.post('/reportes', body: {
      'tipo': tipo,
      'mascota': mascota.toJson(),
      'fotoUrl': fotoUrl,
      'ubicacion': ubicacion.toJson(),
      if (mascotaId != null) 'mascotaId': mascotaId,
    }) as Map<String, dynamic>;
    return Reporte.fromJson(json);
  }

  Future<List<Reporte>> listarCercanos({
    required double lat,
    required double lng,
    double radioKm = 10,
  }) async {
    final json = await _apiClient.get('/reportes', query: {
      'lat': lat,
      'lng': lng,
      'radioKm': radioKm,
    }) as List<dynamic>;
    return json
        .map((item) => Reporte.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Reporte>> listarPropios({String? tipo}) async {
    final json = await _apiClient.get('/reportes/mios', query: {
      if (tipo != null) 'tipo': tipo,
    }) as List<dynamic>;
    return json
        .map((item) => Reporte.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Reporte> obtenerDetalle(String id) async {
    final json = await _apiClient.get('/reportes/$id') as Map<String, dynamic>;
    return Reporte.fromJson(json);
  }

  Future<List<Coincidencia>> obtenerCoincidencias(String id) async {
    final json = await _apiClient.get('/reportes/$id/coincidencias') as List<dynamic>;
    return json
        .map((item) => Coincidencia.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Reporte> actualizarReporte({
    required String id,
    Mascota? mascota,
    String? fotoUrl,
    Ubicacion? ubicacion,
  }) async {
    final json = await _apiClient.patch('/reportes/$id', body: {
      if (mascota != null) 'mascota': mascota.toJson(),
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
      if (ubicacion != null) 'ubicacion': ubicacion.toJson(),
    }) as Map<String, dynamic>;
    return Reporte.fromJson(json);
  }

  Future<Reporte> cerrarReporte(String id) async {
    final json = await _apiClient.post('/reportes/$id/cerrar') as Map<String, dynamic>;
    return Reporte.fromJson(json);
  }

  Future<void> eliminarReporte(String id) async {
    await _apiClient.delete('/reportes/$id');
  }

  Future<List<MiCoincidencia>> listarMisCoincidencias() async {
    final json = await _apiClient.get('/coincidencias/mias') as List<dynamic>;
    return json
        .map((item) => MiCoincidencia.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> descartarCoincidencia(String id) async {
    await _apiClient.post('/coincidencias/$id/descartar');
  }

  Future<ConfirmacionResultado> confirmarCoincidencia(String id) async {
    final json = await _apiClient.post('/coincidencias/$id/confirmar') as Map<String, dynamic>;
    return ConfirmacionResultado.fromJson(json);
  }
}
