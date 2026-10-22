import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocationService {
  // El mapa y la lista de reportes quedan montados a la vez (IndexedStack) y
  // piden la ubicación al mismo tiempo al abrir la app por primera vez;
  // geolocator rechaza una segunda solicitud de permiso mientras la primera
  // sigue abierta, así que todas comparten la misma.
  Future<LocationPermission>? _solicitudPermiso;

  /// Con [pedirPermiso] en `false` no se muestra el diálogo del sistema: si el
  /// permiso no está concedido, se lanza [LocationException] directamente.
  Future<Position> obtenerUbicacionActual({bool pedirPermiso = true}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException('Activa el GPS para usar tu ubicación actual');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!pedirPermiso) {
        throw LocationException('Permiso de ubicación denegado');
      }
      permission = await (_solicitudPermiso ??= Geolocator.requestPermission()
          .whenComplete(() => _solicitudPermiso = null));
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
