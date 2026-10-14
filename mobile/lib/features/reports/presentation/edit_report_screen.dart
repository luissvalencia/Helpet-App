import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' show ClientException;
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/foto_validator.dart';
import '../domain/mascota.dart';
import '../domain/reporte.dart';
import '../domain/ubicacion.dart';
import 'reportes_providers.dart';
import 'widgets/location_picker_field.dart';

class EditReportScreen extends ConsumerStatefulWidget {
  const EditReportScreen({super.key, required this.reporte});

  final Reporte reporte;

  @override
  ConsumerState<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends ConsumerState<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController =
      TextEditingController(text: widget.reporte.mascota.nombre);
  late String _especie = especieOptions.contains(widget.reporte.mascota.especie)
      ? widget.reporte.mascota.especie
      : especieOptions.last;
  late final _razaController = TextEditingController(text: widget.reporte.mascota.raza);
  late final _colorController = TextEditingController(text: widget.reporte.mascota.color);
  late final _descripcionController =
      TextEditingController(text: widget.reporte.mascota.descripcion);
  late final _direccionController =
      TextEditingController(text: widget.reporte.ubicacion.direccionTexto ?? '');

  late LatLng _ubicacion =
      LatLng(widget.reporte.ubicacion.lat, widget.reporte.ubicacion.lng);
  File? _nuevaFoto;
  bool _saving = false;

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

    setState(() => _nuevaFoto = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      String? fotoUrl;
      if (_nuevaFoto != null) {
        final uid = ref.read(authRepositoryProvider).currentUser!.uid;
        fotoUrl = await ref
            .read(storageRepositoryProvider)
            .uploadFotoReporte(file: _nuevaFoto!, uid: uid);
      }

      await ref.read(reportesRepositoryProvider).actualizarReporte(
            id: widget.reporte.id,
            mascota: Mascota(
              nombre: widget.reporte.esPerdida
                  ? _nombreController.text.trim()
                  : 'Mascota encontrada',
              especie: _especie,
              raza: _razaController.text.trim(),
              color: _colorController.text.trim(),
              descripcion: _descripcionController.text.trim(),
            ),
            fotoUrl: fotoUrl,
            ubicacion: Ubicacion(
              lat: _ubicacion.latitude,
              lng: _ubicacion.longitude,
              direccionTexto: _direccionController.text.trim().isEmpty
                  ? null
                  : _direccionController.text.trim(),
            ),
          );

      ref.invalidate(reporteDetalleProvider(widget.reporte.id));
      ref.invalidate(reportesCercanosProvider);
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
      appBar: AppBar(title: const Text('Editar reporte')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                  child: _nuevaFoto != null
                      ? Image.file(_nuevaFoto!, fit: BoxFit.cover, width: double.infinity)
                      : Image.network(
                          widget.reporte.fotoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              titulo: 'Datos de la mascota',
              icono: Icons.pets_outlined,
              child: Column(
                children: [
                  if (widget.reporte.esPerdida) ...[
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
                initialLat: _ubicacion.latitude,
                initialLng: _ubicacion.longitude,
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
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
