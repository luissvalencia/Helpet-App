import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/location/location_service.dart';
import '../reportes_providers.dart';

class LocationPickerField extends ConsumerStatefulWidget {
  const LocationPickerField({
    super.key,
    this.initialLat,
    this.initialLng,
    required this.direccionController,
    required this.onLocationChanged,
  });

  final double? initialLat;
  final double? initialLng;
  final TextEditingController direccionController;
  final ValueChanged<LatLng> onLocationChanged;

  @override
  ConsumerState<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends ConsumerState<LocationPickerField> {
  static const _bogota = LatLng(4.7110, -74.0721);

  GoogleMapController? _mapController;
  LatLng? _posicion;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _posicion = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      _solicitarUbicacionInicial();
    }
  }

  Future<void> _solicitarUbicacionInicial() async {
    setState(() => _locating = true);
    try {
      final position = await ref.read(locationServiceProvider).obtenerUbicacionActual();
      final pos = LatLng(position.latitude, position.longitude);
      setState(() => _posicion = pos);
      widget.onLocationChanged(pos);
      _moverCamaraA(pos);
      await _reverseGeocode(pos);
    } on LocationException catch (e) {
      setState(() {
        _posicion = _bogota;
        _error = e.message;
      });
      widget.onLocationChanged(_bogota);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _onMarkerDragEnd(LatLng pos) async {
    setState(() => _posicion = pos);
    widget.onLocationChanged(pos);
    await _reverseGeocode(pos);
  }

  void _moverCamaraA(LatLng pos) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isEmpty) return;
      final p = placemarks.first;
      final partes = [p.thoroughfare, p.subLocality, p.locality]
          .where((s) => s != null && s.trim().isNotEmpty)
          .join(', ');
      if (partes.isNotEmpty && mounted) {
        widget.direccionController.text = partes;
      }
    } catch (_) {
      // Sin conexión o servicio de geocoding no disponible: el campo de
      // dirección queda como estaba, editable a mano.
    }
  }

  @override
  Widget build(BuildContext context) {
    final posicion = _posicion ?? _bogota;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ubicación', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: posicion, zoom: 15),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_posicion != null) _moverCamaraA(_posicion!);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer()),
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('ubicacion-seleccionada'),
                      position: posicion,
                      draggable: true,
                      onDragEnd: _onMarkerDragEnd,
                    ),
                  },
                ),
                if (_locating) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 4),
        const Text(
          'Arrastra el marcador para ajustar la ubicación exacta',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: widget.direccionController,
          decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
        ),
      ],
    );
  }
}
