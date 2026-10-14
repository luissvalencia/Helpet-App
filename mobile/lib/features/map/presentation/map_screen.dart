import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/config/app_theme.dart';
import '../../../core/location/location_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../reports/domain/mascota.dart';
import '../../reports/domain/reporte.dart';
import '../../reports/presentation/report_detail_screen.dart';
import '../../reports/presentation/reportes_providers.dart';
import 'map_providers.dart';

const _umbralRecargaMetros = 2000;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _ultimoCentroConsultado;
  LatLng? _centroCamaraActual;
  Reporte? _reporteSeleccionado;
  Offset? _posicionTarjeta;
  bool _filtrosVisibles = false;
  bool _cargandoUbicacion = true;
  String? _errorUbicacion;

  final _colorController = TextEditingController();
  final _razaController = TextEditingController();

  static const _bogota = LatLng(4.7110, -74.0721);

  @override
  void initState() {
    super.initState();
    _centrarEnUbicacionActual();
  }

  @override
  void dispose() {
    _colorController.dispose();
    _razaController.dispose();
    super.dispose();
  }

  Future<void> _centrarEnUbicacionActual() async {
    setState(() {
      _cargandoUbicacion = true;
      _errorUbicacion = null;
    });
    try {
      final position = await ref.read(locationServiceProvider).obtenerUbicacionActual();
      final centro = LatLng(position.latitude, position.longitude);
      _aplicarCentro(centro);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(centro, 13));
    } on LocationException catch (e) {
      _aplicarCentro(_bogota);
      setState(() => _errorUbicacion = e.message);
    } finally {
      if (mounted) setState(() => _cargandoUbicacion = false);
    }
  }

  void _aplicarCentro(LatLng centro) {
    _ultimoCentroConsultado = centro;
    ref.read(mapaCentroProvider.notifier).state = centro;
  }

  Future<void> _actualizarPosicionTarjeta() async {
    final reporte = _reporteSeleccionado;
    final controller = _mapController;
    if (reporte == null || controller == null) return;

    final screenCoordinate = await controller.getScreenCoordinate(
      LatLng(reporte.ubicacion.lat, reporte.ubicacion.lng),
    );
    if (!mounted || _reporteSeleccionado != reporte) return;

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    setState(() {
      _posicionTarjeta = Offset(
        screenCoordinate.x / devicePixelRatio,
        screenCoordinate.y / devicePixelRatio,
      );
    });
  }

  void _onCameraIdle(LatLng nuevoCentro) {
    final anterior = _ultimoCentroConsultado;
    if (anterior == null) return;
    final distanciaMetros = Geolocator.distanceBetween(
      anterior.latitude,
      anterior.longitude,
      nuevoCentro.latitude,
      nuevoCentro.longitude,
    );
    if (distanciaMetros > _umbralRecargaMetros) {
      _aplicarCentro(nuevoCentro);
    }
  }

  BitmapDescriptor _iconoPorReporte(Reporte reporte, String? uid) {
    if (!reporte.esPerdida) {
      // Pedido del tutor: sin esto, todos los avistamientos se ven del
      // mismo verde y no hay forma de distinguir a simple vista cuál es el
      // propio en medio de los demás.
      if (reporte.creadoPor == uid) {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      }
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    if (reporte.creadoPor == uid) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  List<Widget> _posicionarTarjeta(BuildContext context) {
    const anchoTarjeta = 260.0;
    const altoAproximado = 96.0;
    const separacionDelPin = 40.0;

    final pantalla = MediaQuery.sizeOf(context);
    final posicion = _posicionTarjeta!;

    var left = posicion.dx - anchoTarjeta / 2;
    left = left.clamp(12.0, pantalla.width - anchoTarjeta - 12.0);

    // Por defecto, la tarjeta flota arriba del pin; si no cabe (el pin está
    // muy cerca del borde superior), se muestra debajo en su lugar.
    var top = posicion.dy - altoAproximado - separacionDelPin;
    if (top < 12) top = posicion.dy + separacionDelPin;

    return [
      Positioned(
        left: left,
        top: top,
        width: anchoTarjeta,
        child: _TarjetaReporte(
          reporte: _reporteSeleccionado!,
          onCerrar: () => setState(() {
            _reporteSeleccionado = null;
            _posicionTarjeta = null;
          }),
        ),
      ),
    ];
  }

  void _limpiarFiltros() {
    ref.read(mapaFiltrosProvider.notifier).state = const MapaFiltros();
    _colorController.clear();
    _razaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final reportesAsync = ref.watch(mapaReportesFiltradosProvider);
    final filtros = ref.watch(mapaFiltrosProvider);
    final centro = ref.watch(mapaCentroProvider);
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            icon: Icon(filtros.activo ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _filtrosVisibles = !_filtrosVisibles),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: centro ?? _bogota, zoom: 13),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onCameraMove: (position) => _centroCamaraActual = position.target,
            onCameraIdle: () {
              final nuevoCentro = _centroCamaraActual;
              if (nuevoCentro != null) _onCameraIdle(nuevoCentro);
              if (_reporteSeleccionado != null) _actualizarPosicionTarjeta();
            },
            markers: reportesAsync.maybeWhen(
              data: (reportes) => reportes
                  .map((r) => Marker(
                        markerId: MarkerId(r.id),
                        position: LatLng(r.ubicacion.lat, r.ubicacion.lng),
                        icon: _iconoPorReporte(r, uid),
                        // Sin esto, además de abrir nuestra _TarjetaReporte,
                        // el SDK nativo también centra la cámara y muestra
                        // su propio info window por defecto — compite con
                        // nuestro overlay y deja el mapa sin responder a
                        // gestos en este dispositivo.
                        consumeTapEvents: true,
                        onTap: () {
                          setState(() => _reporteSeleccionado = r);
                          _actualizarPosicionTarjeta();
                        },
                      ))
                  .toSet(),
              orElse: () => {},
            ),
          ),
          if (_cargandoUbicacion) const Center(child: CircularProgressIndicator()),
          if (_errorUbicacion != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_errorUbicacion!, style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: _ContadorVisibles(reportesAsync: reportesAsync),
          ),
          if (_filtrosVisibles)
            Positioned(
              top: 56,
              left: 12,
              right: 12,
              child: _PanelFiltros(
                colorController: _colorController,
                razaController: _razaController,
                onLimpiar: _limpiarFiltros,
              ),
            ),
          if (_reporteSeleccionado == null)
            const Positioned(
              bottom: 16,
              right: 12,
              child: _LeyendaColores(),
            ),
          if (_reporteSeleccionado != null && _posicionTarjeta != null)
            ..._posicionarTarjeta(context),
        ],
      ),
    );
  }
}

class _LeyendaColores extends StatelessWidget {
  const _LeyendaColores();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeyendaItem(color: Colors.amber, texto: 'Mi avistamiento'),
            _LeyendaItem(color: Colors.green, texto: 'Avistamiento de otro'),
            _LeyendaItem(color: Colors.blue, texto: 'Mi mascota perdida'),
            _LeyendaItem(color: Colors.red, texto: 'Otra mascota perdida'),
          ],
        ),
      ),
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  const _LeyendaItem({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(texto, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ContadorVisibles extends StatelessWidget {
  const _ContadorVisibles({required this.reportesAsync});

  final AsyncValue<List<Reporte>> reportesAsync;

  @override
  Widget build(BuildContext context) {
    final texto = reportesAsync.maybeWhen(
      data: (reportes) => '${reportes.length} reportes visibles',
      orElse: () => '...',
    );
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _PanelFiltros extends ConsumerWidget {
  const _PanelFiltros({
    required this.colorController,
    required this.razaController,
    required this.onLimpiar,
  });

  final TextEditingController colorController;
  final TextEditingController razaController;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtros = ref.watch(mapaFiltrosProvider);
    final especies = ['Todos', ...especieOptions];

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: especies.map((especie) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(especie),
                      selected: filtros.especie == especie,
                      selectedColor: AppColors.green.withValues(alpha: 0.2),
                      onSelected: (_) => ref.read(mapaFiltrosProvider.notifier).state =
                          filtros.copyWith(especie: especie),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: colorController,
                    decoration: const InputDecoration(labelText: 'Color', isDense: true),
                    onChanged: (value) => ref.read(mapaFiltrosProvider.notifier).state =
                        filtros.copyWith(color: value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: razaController,
                    decoration: const InputDecoration(labelText: 'Raza', isDense: true),
                    onChanged: (value) => ref.read(mapaFiltrosProvider.notifier).state =
                        filtros.copyWith(raza: value),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onLimpiar, child: const Text('Limpiar filtros')),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaReporte extends StatelessWidget {
  const _TarjetaReporte({required this.reporte, required this.onCerrar});

  final Reporte reporte;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    reporte.fotoUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    // Sin esto, Flutter decodifica la foto a su resolución
                    // original (varios MB si viene de la cámara) antes de
                    // reducirla — costoso en CPU/memoria en gama baja.
                    cacheWidth: 96,
                    cacheHeight: 96,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reporte.mascota.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        reporte.esPerdida ? 'Perdida' : 'Avistamiento',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Flexible evita un bug conocido de Flutter: un hijo no-flex
                // de un Row recibe ancho infinito en la primera pasada de
                // medición de RenderFlex, y un botón Material lanza
                // "BoxConstraints forces an infinite width" con eso — deja
                // el árbol de render roto y el mapa sin responder a gestos.
                Flexible(
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: onCerrar,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(reporteId: reporte.id),
                  ),
                ),
                child: const Text('Ver detalle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
