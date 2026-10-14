import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' show ClientException;
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../reports/domain/foto_validator.dart';
import '../../reports/presentation/reportes_providers.dart';
import '../domain/mascota_guardada.dart';
import 'profile_providers.dart';

class CrearEditarMascotaScreen extends ConsumerStatefulWidget {
  const CrearEditarMascotaScreen({super.key, this.mascota});

  /// Si es null, se está creando una mascota nueva; si no, se edita esta.
  final MascotaGuardada? mascota;

  @override
  ConsumerState<CrearEditarMascotaScreen> createState() => _CrearEditarMascotaScreenState();
}

class _CrearEditarMascotaScreenState extends ConsumerState<CrearEditarMascotaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(text: widget.mascota?.nombre ?? '');
  late String _especie = widget.mascota != null &&
          especieMascotaOptions.contains(widget.mascota!.especie)
      ? widget.mascota!.especie
      : especieMascotaOptions.first;
  late final _razaController = TextEditingController(text: widget.mascota?.raza ?? '');
  late final _colorController = TextEditingController(text: widget.mascota?.color ?? '');
  late final _descripcionController =
      TextEditingController(text: widget.mascota?.descripcion ?? '');

  File? _nuevaFoto;
  bool _saving = false;

  bool get _esNueva => widget.mascota == null;

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _colorController.dispose();
    _descripcionController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    setState(() => _nuevaFoto = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      String? fotoUrl = widget.mascota?.fotoUrl;
      if (_nuevaFoto != null) {
        final uid = ref.read(authRepositoryProvider).currentUser!.uid;
        fotoUrl = await ref
            .read(storageRepositoryProvider)
            .uploadFotoMascota(file: _nuevaFoto!, uid: uid);
      }

      final repo = ref.read(mascotasRepositoryProvider);
      if (_esNueva) {
        await repo.crear(
          nombre: _nombreController.text.trim(),
          especie: _especie,
          raza: _razaController.text.trim(),
          color: _colorController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          fotoUrl: fotoUrl,
        );
      } else {
        await repo.actualizar(
          id: widget.mascota!.id,
          nombre: _nombreController.text.trim(),
          especie: _especie,
          raza: _razaController.text.trim(),
          color: _colorController.text.trim(),
          descripcion: _descripcionController.text.trim(),
          fotoUrl: fotoUrl,
        );
      }

      ref.invalidate(misMascotasProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
      appBar: AppBar(title: Text(_esNueva ? 'Nueva mascota' : 'Editar mascota')),
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
                  child: _construirFoto(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              titulo: 'Datos de la mascota',
              icono: Icons.pets_outlined,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _especie,
                    decoration: const InputDecoration(labelText: 'Especie'),
                    items: especieMascotaOptions
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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_esNueva ? 'Guardar mascota' : 'Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirFoto() {
    if (_nuevaFoto != null) {
      return Image.file(_nuevaFoto!, fit: BoxFit.cover, width: double.infinity);
    }
    if (widget.mascota?.fotoUrl != null) {
      return Image.network(widget.mascota!.fotoUrl!, fit: BoxFit.cover, width: double.infinity);
    }
    return const Center(child: Text('Toca para elegir una foto (opcional)'));
  }
}
