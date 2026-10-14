class AppUser {
  AppUser({
    required this.uid,
    required this.email,
    required this.nombre,
    this.telefono,
    this.ciudad,
    this.direccionReferencia,
    required this.rol,
    this.fcmToken,
    this.notifCoincidencias = true,
    this.notifReportesCercanos = true,
    this.fotoUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      ciudad: json['ciudad'] as String?,
      direccionReferencia: json['direccionReferencia'] as String?,
      rol: json['rol'] as String,
      fcmToken: json['fcmToken'] as String?,
      // Usuarios creados antes de Sprint 4 no tienen estos campos: default true.
      notifCoincidencias: json['notifCoincidencias'] as bool? ?? true,
      notifReportesCercanos: json['notifReportesCercanos'] as bool? ?? true,
      fotoUrl: json['fotoUrl'] as String?,
    );
  }

  final String uid;
  final String email;
  final String nombre;
  final String? telefono;
  final String? ciudad;
  final String? direccionReferencia;
  final String rol;
  final String? fcmToken;
  final bool notifCoincidencias;
  final bool notifReportesCercanos;
  final String? fotoUrl;
}
