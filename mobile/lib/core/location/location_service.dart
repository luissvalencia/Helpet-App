import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocationService {
  Future<Position> obtenerUbicacionActual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException('Activa el GPS para usar tu ubicación actual');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Permiso de ubicación denegado');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Permiso de ubicación denegado permanentemente. Actívalo en la configuración de la app',
      );
    }

    return Geolocator.getCurrentPosition();
  }
}
