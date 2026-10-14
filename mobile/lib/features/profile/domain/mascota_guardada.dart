// Alcance del anteproyecto: solo perros y gatos (sección 1.6).
const especieMascotaOptions = ['Perro', 'Gato'];

/// Mascota guardada en el perfil del usuario, reutilizable al reportar una
/// pérdida (evita retipear nombre/especie/raza/color cada vez).
class MascotaGuardada {
  MascotaGuardada({
    required this.id,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.color,
    required this.descripcion,
    this.fotoUrl,
  });

  factory MascotaGuardada.fromJson(Map<String, dynamic> json) {
    return MascotaGuardada(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      especie: json['especie'] as String,
      raza: json['raza'] as String? ?? '',
      color: json['color'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      fotoUrl: json['fotoUrl'] as String?,
    );
  }

  final String id;
  final String nombre;
  final String especie;
  final String raza;
  final String color;
  final String descripcion;
  final String? fotoUrl;
}
