import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers/theme_providers.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/info_tile.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../legal/presentation/politica_privacidad_screen.dart';
import '../../legal/presentation/terminos_uso_screen.dart';
import '../../reports/domain/foto_validator.dart';
import '../../reports/presentation/reportes_providers.dart';
import 'editar_perfil_screen.dart';
import 'metricas_screen.dart';
import 'mis_mascotas_screen.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _savingPrefs = false;
  bool _savingFoto = false;
  bool _verificandoEmail = false;
  bool _cerrandoSesion = false;
  late bool _emailVerified =
      ref.read(authRepositoryProvider).currentUser?.emailVerified ?? true;

  Future<void> _cerrarSesion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    setState(() => _cerrandoSesion = true);
    await ref.read(authRepositoryProvider).logout();
  }

  Future<void> _reenviarVerificacion() async {
    setState(() => _verificandoEmail = true);
    try {
      await ref.read(authRepositoryProvider).resendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Correo de verificación reenviado'),
        ));
      }
    } finally {
      if (mounted) setState(() => _verificandoEmail = false);
    }
  }

  Future<void> _yaVerifique() async {
    setState(() => _verificandoEmail = true);
    final verificado =
        await ref.read(authRepositoryProvider).reloadAndCheckEmailVerified();
    if (mounted) {
      setState(() {
        _emailVerified = verificado;
        _verificandoEmail = false;
      });
      if (!verificado) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Todavía no vemos tu correo verificado'),
        ));
      }
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
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

    setState(() => _savingFoto = true);
    try {
      final uid = ref.read(authRepositoryProvider).currentUser!.uid;
      final fotoUrl = await ref
          .read(storageRepositoryProvider)
          .uploadFotoPerfil(file: file, uid: uid);
      await ref.read(profileRepositoryProvider).updateFotoPerfil(fotoUrl);
      ref.invalidate(meProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _savingFoto = false);
    }
  }

  Future<void> _eliminarCuenta() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mi cuenta'),
        content: const Text(
          'Se borrará tu cuenta y tu perfil de Helpet de forma permanente. '
          'Tus reportes y coincidencias ya existentes se conservan como '
          'historial, pero no podrás volver a entrar con este correo. '
          '¿Confirmas que quieres continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      await ref.read(profileRepositoryProvider).eliminarCuenta();
      await ref.read(authRepositoryProvider).logout();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _updatePreferencias({
    required bool notifCoincidencias,
    required bool notifReportesCercanos,
  }) async {
    setState(() => _savingPrefs = true);
    try {
      await ref.read(profileRepositoryProvider).updatePreferencias(
            notifCoincidencias: notifCoincidencias,
            notifReportesCercanos: notifReportesCercanos,
          );
      ref.invalidate(meProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _savingPrefs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meAsync = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: _cerrandoSesion
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            onPressed: _cerrandoSesion ? null : _cerrarSesion,
          ),
        ],
      ),
      body: meAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(onRetry: () => ref.invalidate(meProvider)),
        data: (user) {
          final themeMode = ref.watch(themeModeProvider);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!_emailVerified) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Todavía no has verificado tu correo electrónico.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _verificandoEmail
                                ? null
                                : _reenviarVerificacion,
                            child: const Text('Reenviar correo'),
                          ),
                          TextButton(
                            onPressed: _verificandoEmail ? null : _yaVerifique,
                            child: const Text('Ya verifiqué'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SectionCard(
                titulo: 'Cuenta',
                icono: Icons.person_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _savingFoto ? null : _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundImage: user.fotoUrl != null
                                  ? NetworkImage(user.fotoUrl!)
                                  : null,
                              child: _savingFoto
                                  ? const CircularProgressIndicator()
                                  : user.fotoUrl == null
                                      ? const Icon(Icons.person, size: 40)
                                      : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InfoTile(
                      icono: Icons.email_outlined,
                      label: 'Correo',
                      valor: user.email,
                    ),
                    const SizedBox(height: 8),
                    InfoTile(
                      icono: Icons.phone_outlined,
                      label: 'Teléfono',
                      valor: user.telefono ?? '',
                    ),
                    const SizedBox(height: 8),
                    InfoTile(
                      icono: Icons.location_city_outlined,
                      label: 'Ciudad',
                      valor: user.ciudad ?? '',
                    ),
                    const SizedBox(height: 8),
                    InfoTile(
                      icono: Icons.place_outlined,
                      label: 'Dirección de referencia',
                      valor: user.direccionReferencia ?? '',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditarPerfilScreen(user: user),
                          ),
                        ),
                        child: const Text('Editar perfil'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                titulo: 'Mis mascotas',
                icono: Icons.pets_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Guarda el perfil de tus mascotas para elegirlas rápido '
                      'si algún día se pierden.',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MisMascotasScreen()),
                        ),
                        icon: const Icon(Icons.pets_outlined),
                        label: const Text('Administrar mis mascotas'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                titulo: 'Apariencia',
                icono: Icons.palette_outlined,
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.light, label: Text('Claro')),
                      ButtonSegment(
                          value: ThemeMode.dark, label: Text('Oscuro')),
                      ButtonSegment(
                          value: ThemeMode.system, label: Text('Sistema')),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (seleccion) => ref
                        .read(themeModeProvider.notifier)
                        .elegir(seleccion.first),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                titulo: 'Notificaciones',
                icono: Icons.notifications_outlined,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Alertas de coincidencias'),
                      value: user.notifCoincidencias,
                      onChanged: _savingPrefs
                          ? null
                          : (value) => _updatePreferencias(
                                notifCoincidencias: value,
                                notifReportesCercanos:
                                    user.notifReportesCercanos,
                              ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Alertas de reportes cercanos'),
                      value: user.notifReportesCercanos,
                      onChanged: _savingPrefs
                          ? null
                          : (value) => _updatePreferencias(
                                notifCoincidencias: user.notifCoincidencias,
                                notifReportesCercanos: value,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                titulo: 'Legal',
                icono: Icons.gavel_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Política de privacidad'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PoliticaPrivacidadScreen(),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Términos de uso'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const TerminosUsoScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                titulo: 'Zona de riesgo',
                icono: Icons.warning_amber_outlined,
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.error),
                    ),
                    onPressed: _eliminarCuenta,
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Eliminar mi cuenta'),
                  ),
                ),
              ),
              if (user.rol == 'admin') ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MetricasScreen()),
                    ),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Métricas del modelo IA'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
