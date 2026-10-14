import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../reports/domain/reporte.dart';
import '../../reports/presentation/reportes_providers.dart';

final mapaCentroProvider = StateProvider<LatLng?>((ref) => null);
final mapaRadioKmProvider = StateProvider<double>((ref) => 10);

final mapaReportesProvider = FutureProvider.autoDispose<List<Reporte>>((ref) async {
  final centro = ref.watch(mapaCentroProvider);
  final radioKm = ref.watch(mapaRadioKmProvider);
  if (centro == null) return [];
  final reportes = await ref.watch(reportesRepositoryProvider).listarCercanos(
        lat: centro.latitude,
        lng: centro.longitude,
        radioKm: radioKm,
      );
  return reportes.where((r) => r.activo).toList();
});

class MapaFiltros {
  const MapaFiltros({this.especie = 'Todos', this.color = '', this.raza = ''});

  final String especie;
  final String color;
  final String raza;

  bool get activo => especie != 'Todos' || color.isNotEmpty || raza.isNotEmpty;

  MapaFiltros copyWith({String? especie, String? color, String? raza}) {
    return MapaFiltros(
      especie: especie ?? this.especie,
      color: color ?? this.color,
      raza: raza ?? this.raza,
    );
  }
}

final mapaFiltrosProvider = StateProvider<MapaFiltros>((ref) => const MapaFiltros());

final mapaReportesFiltradosProvider =
    Provider.autoDispose<AsyncValue<List<Reporte>>>((ref) {
  final asyncReportes = ref.watch(mapaReportesProvider);
  final filtros = ref.watch(mapaFiltrosProvider);
  return asyncReportes.whenData((reportes) {
    return reportes.where((r) {
      if (filtros.especie != 'Todos' && r.mascota.especie != filtros.especie) {
        return false;
      }
      if (filtros.color.isNotEmpty &&
          !r.mascota.color.toLowerCase().contains(filtros.color.toLowerCase())) {
        return false;
      }
      if (filtros.raza.isNotEmpty &&
          !r.mascota.raza.toLowerCase().contains(filtros.raza.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  });
});
