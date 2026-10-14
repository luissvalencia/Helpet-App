import 'coincidencia.dart';

/// Referencia mínima al reporte PROPIO al que pertenece una coincidencia,
/// usada en GET /coincidencias/mias (que agrega coincidencias de todos los
/// reportes del usuario, no solo uno).
class MiReporteRef {
  MiReporteRef({
    required this.id,
    required this.tipo,
    required this.nombreMascota,
    required this.fotoUrl,
  });

  factory MiReporteRef.fromJson(Map<String, dynamic> json) {
    return MiReporteRef(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      nombreMascota: (json['mascota'] as Map<String, dynamic>)['nombre'] as String,
      fotoUrl: json['fotoUrl'] as String,
    );
  }

  final String id;
  final String tipo;
  final String nombreMascota;
  final String fotoUrl;

  bool get esPerdida => tipo == 'perdida';
}

class MiCoincidencia {
  MiCoincidencia({required this.coincidencia, required this.miReporte});

  factory MiCoincidencia.fromJson(Map<String, dynamic> json) {
    return MiCoincidencia(
      coincidencia: Coincidencia.fromJson(json),
      miReporte: MiReporteRef.fromJson(json['miReporte'] as Map<String, dynamic>),
    );
  }

  final Coincidencia coincidencia;
  final MiReporteRef miReporte;
}
