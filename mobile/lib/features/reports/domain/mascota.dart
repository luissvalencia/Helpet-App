// Alcance del anteproyecto: solo perros y gatos (sección 1.6).
const especieOptions = ['Perro', 'Gato'];

class Mascota {
  Mascota({
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.color,
    required this.descripcion,
  });

  factory Mascota.fromJson(Map<String, dynamic> json) {
    return Mascota(
      nombre: json['nombre'] as String? ?? '',
      especie: json['especie'] as String,
      raza: json['raza'] as String? ?? '',
      color: json['color'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
    );
  }

  final String nombre;
  final String especie;
  final String raza;
  final String color;
  final String descripcion;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'especie': especie,
        'raza': raza,
        'color': color,
        'descripcion': descripcion,
      };
}
