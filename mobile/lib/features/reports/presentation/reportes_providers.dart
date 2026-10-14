import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/providers/firebase_providers.dart';
import '../data/reportes_repository.dart';
import '../data/storage_repository.dart';
import '../domain/coincidencia.dart';
import '../domain/mi_coincidencia.dart';
import '../domain/reporte.dart';

final reportesRepositoryProvider = Provider<ReportesRepository>((ref) {
  return ReportesRepository(ref.watch(apiClientProvider));
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(ref.watch(firebaseStorageProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class BusquedaCercania {
  const BusquedaCercania({required this.lat, required this.lng, this.radioKm = 10});

  final double lat;
  final double lng;
  final double radioKm;
}

final busquedaCercaniaProvider = StateProvider<BusquedaCercania?>((ref) => null);

final reportesCercanosProvider =
    FutureProvider.autoDispose<List<Reporte>>((ref) async {
  final busqueda = ref.watch(busquedaCercaniaProvider);
  if (busqueda == null) return [];
  return ref.watch(reportesRepositoryProvider).listarCercanos(
        lat: busqueda.lat,
        lng: busqueda.lng,
        radioKm: busqueda.radioKm,
      );
});

final misReportesPerdidosProvider =
    FutureProvider.autoDispose<List<Reporte>>((ref) async {
  return ref.watch(reportesRepositoryProvider).listarPropios(tipo: 'perdida');
});

final reporteDetalleProvider =
    FutureProvider.autoDispose.family<Reporte, String>((ref, id) {
  return ref.watch(reportesRepositoryProvider).obtenerDetalle(id);
});

final coincidenciasProvider =
    FutureProvider.autoDispose.family<List<Coincidencia>, String>((ref, id) {
  return ref.watch(reportesRepositoryProvider).obtenerCoincidencias(id);
});

final misCoincidenciasProvider =
    FutureProvider.autoDispose<List<MiCoincidencia>>((ref) {
  return ref.watch(reportesRepositoryProvider).listarMisCoincidencias();
});
