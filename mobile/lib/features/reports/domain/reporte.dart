import 'mascota.dart';
import 'ubicacion.dart';

class Reporte {
  Reporte({
    required this.id,
    required this.tipo,
    required this.creadoPor,
    required this.mascota,
    required this.fotoUrl,
    required this.ubicacion,
    required this.estado,
    this.distanciaKm,
    this.coincidenciasCount,
    this.nombreCreador,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      creadoPor: json['creadoPor'] as String,
      mascota: Mascota.fromJson(json['mascota'] as Map<String, dynamic>),
      fotoUrl: json['fotoUrl'] as String,
      ubicacion: Ubicacion.fromJson(json['ubicacion'] as Map<String, dynamic>),
      estado: json['estado'] as String,
      distanciaKm: json['distanciaKm'] != null
          ? (json['distanciaKm'] as num).toDouble()
          : null,
      coincidenciasCount: json['coincidenciasCount'] != null
          ? (json['coincidenciasCount'] as num).toInt()
          : null,
      nombreCreador: json['nombreCreador'] as String?,
    );
  }

  final String id;
  final String tipo;
  final String creadoPor;
  final Mascota mascota;
  final String fotoUrl;
  final Ubicacion ubicacion;
  final String estado;
  final double? distanciaKm;
  final int? coincidenciasCount;
  final String? nombreCreador;

  bool get esPerdida => tipo == 'perdida';
  bool get activo => estado == 'activo';
}
