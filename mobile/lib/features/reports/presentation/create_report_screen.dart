import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' show ClientException;
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../map/presentation/map_providers.dart';
import '../../profile/domain/mascota_guardada.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/foto_validator.dart';
import '../domain/mascota.dart';
import '../domain/ubicacion.dart';
import 'reportes_providers.dart';
import 'widgets/location_picker_field.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();

  String _tipo = 'perdida';
  final _nombreController = TextEditingController();
  String _especie = especieOptions.first;
  final _razaController = TextEditingController();
  final _colorController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _direccionController = TextEditingController();

  LatLng? _ubicacion;
  File? _foto;
  bool _saving = false;

  // Si se elige una mascota guardada del perfil, se precargan sus datos y
  // (si tiene) su foto ya subida — no hace falta volver a tipear/subir nada.
  String? _mascotaSeleccionadaId;
  String? _fotoUrlDeMascota;

  void _elegirMascotaGuardada(MascotaGuardada? mascota) {
    setState(() {
      _mascotaSeleccionadaId = mascota?.id;
      _fotoUrlDeMascota = mascota?.fotoUrl;
      _foto = null;
      _nombreController.text = mascota?.nombre ?? '';
      _especie = mascota != null && especieOptions.contains(mascota.especie)
          ? mascota.especie
          : especieOptions.first;
      _razaController.text = mascota?.raza ?? '';
      _colorController.text = mascota?.color ?? '';
      _descripcionController.text = mascota?.descripcion ?? '';
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _colorController.dispose();
    _descripcionController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    try {
      await validarFoto(file);
    } on FotoValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    setState(() {
      _foto = file;
      _fotoUrlDeMascota = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_foto == null && _fotoUrlDeMascota == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona una foto')));
      return;
    }
    if (_ubicacion == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona una ubicación en el mapa')));
      return;
    }

    setState(() => _saving = true);
    try {
      String fotoUrl;
      if (_foto != null) {
        final uid = ref.read(authRepositoryProvider).currentUser!.uid;
        fotoUrl = await ref
            .read(storageRepositoryProvider)
            .uploadFotoReporte(file: _foto!, uid: uid);
      } else {
        fotoUrl = _fotoUrlDeMascota!;
      }

      await ref.read(reportesRepositoryProvider).crearReporte(
            tipo: _tipo,
            mascota: Mascota(
              nombre: _tipo == 'perdida'
                  ? _nombreController.text.trim()
                  : 'Mascota encontrada',
              especie: _especie,
              raza: _razaController.text.trim(),
              color: _colorController.text.trim(),
              descripcion: _descripcionController.text.trim(),
            ),
            fotoUrl: fotoUrl,
            ubicacion: Ubicacion(
              lat: _ubicacion!.latitude,
              lng: _ubicacion!.longitude,
              direccionTexto: _direccionController.text.trim().isEmpty
                  ? null
                  : _direccionController.text.trim(),
            ),
            mascotaId: _tipo == 'perdida' ? _mascotaSeleccionadaId : null,
          );

      // El mapa y los listados quedan montados permanentemente (IndexedStack
      // en HomeShell), así que no se refrescan solos al volver de crear un
      // reporte — hay que invalidar sus providers a mano.
      ref.invalidate(mapaReportesProvider);
      ref.invalidate(reportesCercanosProvider);
      ref.invalidate(misReportesPerdidosProvider);

      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on ClientException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo conectar al servidor. Verifica tu conexión.'),
        ));
      }
    } on SocketException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo conectar al servidor. Verifica tu conexión.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar mascota')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'perdida', label: Text('Perdí a mi mascota')),
                ButtonSegment(value: 'encontrada', label: Text('Vi un animal')),
              ],
              selected: {_tipo},
              onSelectionChanged: (selection) =>
                  setState(() => _tipo = selection.first),
            ),
            const SizedBox(height: 16),
            SectionCard(
              titulo: 'Foto',
              icono: Icons.photo_camera_outlined,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _foto != null
                      ? Image.file(_foto!, fit: BoxFit.cover, width: double.infinity)
                      : _fotoUrlDeMascota != null
                          ? Image.network(_fotoUrlDeMascota!, fit: BoxFit.cover, width: double.infinity)
                          : const Center(child: Text('Toca para elegir una foto')),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              titulo: 'Datos de la mascota',
              icono: Icons.pets_outlined,
              child: Column(
                children: [
                  if (_tipo == 'perdida') ...[
                    _SelectorMascotaGuardada(
                      mascotaSeleccionadaId: _mascotaSeleccionadaId,
                      onSeleccionar: _elegirMascotaGuardada,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre de la mascota'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: _especie,
                    decoration: const InputDecoration(labelText: 'Especie'),
                    items: especieOptions
                        .map((especie) => DropdownMenuItem(value: especie, child: Text(especie)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _especie = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _razaController,
                    decoration: const InputDecoration(labelText: 'Raza'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(labelText: 'Color'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              titulo: 'Ubicación',
              icono: Icons.place_outlined,
              child: LocationPickerField(
                direccionController: _direccionController,
                onLocationChanged: (pos) => setState(() => _ubicacion = pos),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publicar reporte'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorMascotaGuardada extends ConsumerWidget {
  const _SelectorMascotaGuardada({
    required this.mascotaSeleccionadaId,
    required this.onSeleccionar,
  });

  final String? mascotaSeleccionadaId;
  final void Function(MascotaGuardada?) onSeleccionar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mascotasAsync = ref.watch(misMascotasProvider);

    return mascotasAsync.maybeWhen(
      data: (mascotas) {
        if (mascotas.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: DropdownButtonFormField<String?>(
            initialValue: mascotaSeleccionadaId,
            decoration: const InputDecoration(labelText: '¿Cuál de tus mascotas?'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Otra mascota (nueva)')),
              ...mascotas.map(
                (mascota) => DropdownMenuItem(value: mascota.id, child: Text(mascota.nombre)),
              ),
            ],
            onChanged: (id) {
              final mascota = id == null ? null : mascotas.firstWhere((m) => m.id == id);
              onSeleccionar(mascota);
            },
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
