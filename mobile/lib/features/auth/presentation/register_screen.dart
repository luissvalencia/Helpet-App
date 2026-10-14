import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/widgets/paw_logo.dart';
import '../../../core/widgets/section_card.dart';
import '../../legal/presentation/politica_privacidad_screen.dart';
import '../../legal/presentation/terminos_uso_screen.dart';
import 'auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telefonoController = TextEditingController();
  bool _loading = false;
  bool _aceptaLegal = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceptaLegal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debes aceptar la Política de Privacidad y los Términos de Uso'),
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            nombre: _nombreController.text.trim(),
            telefono: _telefonoController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'No se pudo crear la cuenta')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'No se pudo crear la cuenta')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registrarseConGoogle() async {
    if (!_aceptaLegal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debes aceptar la Política de Privacidad y los Términos de Uso'),
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'No se pudo crear la cuenta con Google')),
        );
      }
    } catch (_) {
      // Cancelado por el usuario o sin conexión: sin snackbar de error.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Center(child: PawLogo(size: 72)),
              const SizedBox(height: 20),
              SectionCard(
                titulo: 'Tus datos',
                icono: Icons.person_add_alt_outlined,
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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      validator: (value) =>
                          (value == null || !value.contains('@')) ? 'Correo inválido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Contraseña'),
                      validator: (value) =>
                          (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        helperText: 'Es el medio de contacto si alguien confirma '
                            'una coincidencia con tu mascota.',
                        helperMaxLines: 2,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _aceptaLegal,
                onChanged: (value) => setState(() => _aceptaLegal = value ?? false),
                title: Wrap(
                  children: [
                    const Text('He leído y acepto la '),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PoliticaPrivacidadScreen()),
                      ),
                      child: Text(
                        'Política de Privacidad',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(' y los '),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TerminosUsoScreen()),
                      ),
                      child: Text(
                        'Términos de Uso',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrarme'),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('o'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _loading ? null : _registrarseConGoogle,
                icon: SvgPicture.asset('assets/icons/google_logo.svg', width: 18, height: 18),
                label: const Text('Registrarme con Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
