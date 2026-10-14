import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_providers.dart';
import 'profile_providers.dart';

/// Pantalla dedicada para editar los datos de cuenta. En modo [obligatorio]
/// (primer login con Google sin teléfono) la renderiza `AuthGate` en vez de
/// `HomeShell` — no hay Navigator del cual hacer pop, así que al guardar
/// solo se invalida `meProvider` y `AuthGate` reacciona solo al ver que ya
/// hay teléfono.
class EditarPerfilScreen extends ConsumerStatefulWidget {
  const EditarPerfilScreen({super.key, required this.user, this.obligatorio = false});

  final AppUser user;
  final bool obligatorio;

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(text: widget.user.nombre);
  late final _telefonoController = TextEditingController(text: widget.user.telefono ?? '');
  late final _ciudadController = TextEditingController(text: widget.user.ciudad ?? '');
  late final _direccionController =
      TextEditingController(text: widget.user.direccionReferencia ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _ciudadController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateMe(
            nombre: _nombreController.text.trim(),
            telefono: _telefonoController.text.trim(),
            ciudad: _ciudadController.text.trim().isEmpty ? null : _ciudadController.text.trim(),
            direccionReferencia: _direccionController.text.trim().isEmpty
                ? null
                : _direccionController.text.trim(),
          );
      ref.invalidate(meProvider);
      if (mounted && !widget.obligatorio) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.obligatorio,
        title: Text(widget.obligatorio ? 'Completa tu perfil' : 'Editar perfil'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.obligatorio) ...[
              const Text(
                'Nos falta tu número de teléfono para poder mostrárselo al '
                'dueño de una mascota cuando confirmen una coincidencia.',
              ),
              const SizedBox(height: 16),
            ],
            SectionCard(
              titulo: 'Datos de cuenta',
              icono: Icons.person_outline,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ciudadController,
                    decoration: const InputDecoration(labelText: 'Ciudad o municipio'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de referencia',
                      helperText: 'Barrio o zona de referencia, no tu dirección exacta.',
                      helperMaxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _guardar,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
            if (widget.obligatorio) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _saving ? null : () => ref.read(authRepositoryProvider).logout(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
