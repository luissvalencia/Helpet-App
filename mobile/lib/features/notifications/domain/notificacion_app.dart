/// Notificación in-app persistida por el backend (no depende de que la
/// notificación push/snackbar del momento haya sido vista) — ver
/// `notificacionesUsuario` en Firestore.
class NotificacionApp {
  NotificacionApp({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.tipo,
    required this.data,
    required this.leida,
    required this.creadoEn,
  });

  factory NotificacionApp.fromJson(Map<String, dynamic> json) {
    return NotificacionApp(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      cuerpo: json['cuerpo'] as String,
      tipo: json['tipo'] as String?,
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
      leida: json['leida'] as bool? ?? false,
      creadoEn: json['creadoEn'] != null ? DateTime.tryParse(json['creadoEn'] as String) : null,
    );
  }

  final String id;
  final String titulo;
  final String cuerpo;
  final String? tipo;
  final Map<String, dynamic> data;
  final bool leida;
  final DateTime? creadoEn;

  String? get reporteId => data['reporteId'] as String?;
  String? get coincidenciaId => data['coincidenciaId'] as String?;

  NotificacionApp copyWith({bool? leida}) {
    return NotificacionApp(
      id: id,
      titulo: titulo,
      cuerpo: cuerpo,
      tipo: tipo,
      data: data,
      leida: leida ?? this.leida,
      creadoEn: creadoEn,
    );
  }
}
