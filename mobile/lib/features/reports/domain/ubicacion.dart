class Ubicacion {
  Ubicacion({required this.lat, required this.lng, this.direccionTexto});

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      direccionTexto: json['direccionTexto'] as String?,
    );
  }

  final double lat;
  final double lng;
  final String? direccionTexto;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'direccionTexto': direccionTexto,
      };
}
