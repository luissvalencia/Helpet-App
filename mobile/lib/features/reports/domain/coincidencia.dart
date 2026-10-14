import 'mascota.dart';
import 'ubicacion.dart';

class ReporteCoincidente {
  ReporteCoincidente({
    required this.id,
    required this.tipo,
    required this.mascota,
    required this.fotoUrl,
    required this.ubicacion,
    this.propietarioNombre,
  });

  factory ReporteCoincidente.fromJson(Map<String, dynamic> json) {
    return ReporteCoincidente(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      mascota: Mascota.fromJson(json['mascota'] as Map<String, dynamic>),
      fotoUrl: json['fotoUrl'] as String,
      ubicacion: Ubicacion.fromJson(json['ubicacion'] as Map<String, dynamic>),
      propietarioNombre: json['propietarioNombre'] as String?,
    );
  }

  final String id;
  final String tipo;
  final Mascota mascota;
  final String fotoUrl;
  final Ubicacion ubicacion;
  final String? propietarioNombre;

  bool get esPerdida => tipo == 'perdida';
}

/// Datos de contacto del otro dueño, solo se reciben cuando ambas partes
/// confirmaron la coincidencia (sistema de contacto post-Sprint-5).
class Contacto {
  Contacto({required this.uid, required this.nombre, this.telefono, required this.email});

  factory Contacto.fromJson(Map<String, dynamic> json) {
    return Contacto(
      uid: json['uid'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      email: json['email'] as String,
    );
  }

  final String uid;
  final String nombre;
  final String? telefono;
  final String email;
}

class Coincidencia {
  Coincidencia({
    required this.id,
    required this.similitud,
    required this.estado,
    required this.reporte,
    this.yoConfirme = false,
    this.duenoYaConfirmo = false,
    this.contacto,
  });

  factory Coincidencia.fromJson(Map<String, dynamic> json) {
    return Coincidencia(
      id: json['id'] as String,
      similitud: (json['similitud'] as num).toDouble(),
      estado: json['estado'] as String,
      reporte: ReporteCoincidente.fromJson(json['reporte'] as Map<String, dynamic>),
      yoConfirme: json['yoConfirme'] as bool? ?? false,
      duenoYaConfirmo: json['duenoYaConfirmo'] as bool? ?? false,
      contacto: json['contacto'] != null
          ? Contacto.fromJson(json['contacto'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final double similitud;
  final String estado;
  final ReporteCoincidente reporte;
  final bool yoConfirme;
  // El dueño (lado "perdida") ya confirmó de su lado. Determina si a quien
  // reportó el avistamiento se le debe mostrar la acción de contacto — no
  // tiene sentido ofrecérsela antes de que el dueño inicie el contacto.
  final bool duenoYaConfirmo;
  final Contacto? contacto;

  bool get confirmada => estado == 'confirmada';

  Coincidencia copyWith({String? estado, bool? yoConfirme, bool? duenoYaConfirmo, Contacto? contacto}) {
    return Coincidencia(
      id: id,
      similitud: similitud,
      estado: estado ?? this.estado,
      reporte: reporte,
      yoConfirme: yoConfirme ?? this.yoConfirme,
      duenoYaConfirmo: duenoYaConfirmo ?? this.duenoYaConfirmo,
      contacto: contacto ?? this.contacto,
    );
  }

  /// US-14: porcentaje redondeado a entero para mostrar en la UI.
  int get porcentaje => (similitud * 100).round();

  /// Auditoría post-Sprint-5: el usuario final no necesita ver el número
  /// crudo de similitud de un modelo de IA para entender si vale la pena
  /// revisar la coincidencia — una etiqueta categórica es más clara.
  String get etiqueta => esAlta ? 'Alta coincidencia' : 'Posible coincidencia';

  /// Corte de "Alta coincidencia" en la escala del modelo de ai-service
  /// (umbral de coincidencia 0.145): ~la mitad de las coincidencias reales lo
  /// superan y solo ~1 % de los animales parecidos pero distintos.
  static const umbralAlta = 0.35;

  bool get esAlta => similitud >= umbralAlta;
}

/// Respuesta de POST /coincidencias/:id/confirmar.
class ConfirmacionResultado {
  ConfirmacionResultado({required this.estado, required this.confirmada, this.contacto});

  factory ConfirmacionResultado.fromJson(Map<String, dynamic> json) {
    return ConfirmacionResultado(
      estado: json['estado'] as String,
      confirmada: json['confirmada'] as bool,
      contacto: json['contacto'] != null
          ? Contacto.fromJson(json['contacto'] as Map<String, dynamic>)
          : null,
    );
  }

  final String estado;
  final bool confirmada;
  final Contacto? contacto;
}
