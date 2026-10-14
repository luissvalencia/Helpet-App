import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/mascota_guardada.dart';
import 'crear_editar_mascota_screen.dart';
import 'profile_providers.dart';

class MisMascotasScreen extends ConsumerWidget {
  const MisMascotasScreen({super.key});

  Future<void> _borrar(BuildContext context, WidgetRef ref, MascotaGuardada mascota) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('¿Borrar el perfil de "${mascota.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      await ref.read(mascotasRepositoryProvider).eliminar(mascota.id);
      ref.invalidate(misMascotasProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mascotasAsync = ref.watch(misMascotasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis mascotas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CrearEditarMascotaScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: mascotasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(onRetry: () => ref.invalidate(misMascotasProvider)),
        data: (mascotas) {
          if (mascotas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aún no has agregado ninguna mascota. Guarda su perfil aquí '
                  'para elegirla rápido si algún día se pierde.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mascotas.length,
            itemBuilder: (context, index) {
              final mascota = mascotas[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        mascota.fotoUrl != null ? NetworkImage(mascota.fotoUrl!) : null,
                    child: mascota.fotoUrl == null ? const Icon(Icons.pets) : null,
                  ),
                  title: Text(mascota.nombre),
                  subtitle: Text('${mascota.especie} · ${mascota.raza} · ${mascota.color}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _borrar(context, ref, mascota),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CrearEditarMascotaScreen(mascota: mascota),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
